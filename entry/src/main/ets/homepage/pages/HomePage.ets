import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';
import { FileService } from '../../utils/FileService';
import { TabManager } from '../../tabmanagement/model/TabManager';

// 避让区域配置接口
interface AvoidAreaConfig {
  top: number;    // 顶部避让区域大小
  bottom: number; // 底部避让区域大小
}

// 获取统一的避让区域配置
function getAvoidAreaConfig(): AvoidAreaConfig {
  return {
    top: 30,    // 顶部避让区域大小
    bottom: 20  // 底部避让区域大小
  };
}

@Component
export struct HomePage {
  @State avoidAreaTop: number = 0;
  @State avoidAreaBottom: number = 0;
  @State isCloseTabDisabled: boolean = true;
  @State currentTabId: string = '';
  @State tabCount: number = 0;
  private fileService: FileService = FileService.getInstance();
  private tabManager: TabManager = TabManager.getInstance();

  aboutToAppear(): void {
    this.getAvoidArea();
    this.readPageParams();
    this.ensureDefaultTab();
    this.refreshTabState();
    this.autoOpenEditorIfNeeded();
  }

  onPageShow(): void {
    this.readPageParams();
    this.ensureDefaultTab();
    this.refreshTabState();
  }

  private readPageParams(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params && params.tabId) {
      this.currentTabId = params.tabId as string;
    }
  }

  /**
   * 确保当前页面有关联的标签（首次启动或恢复时自动创建）
   */
  private async ensureDefaultTab(): Promise<void> {
    if (this.currentTabId) {
      return;
    }
    await this.tabManager.init();
    if (this.tabManager.getTabCount() === 0) {
      this.currentTabId = await this.tabManager.addEmptyTab();
    } else {
      const activeTab = this.tabManager.getActiveTab();
      this.currentTabId = activeTab ? activeTab.id : await this.tabManager.addEmptyTab();
    }
  }

  private autoOpenEditorIfNeeded(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params && params.autoOpenEditor && params.filePath && params.fileName) {
      router.pushUrl({
        url: 'noteeditpage/Index',
        params: {
          tabId: this.currentTabId,
          filePath: params.filePath as string,
          fileName: params.fileName as string
        }
      }).catch((err: Error) => {
        console.error('Failed to navigate to editor: ' + err.message);
      });
    }
  }

  /**
   * 刷新标签状态，控制"关闭标签页"按钮的可用性
   */
  private async refreshTabState(): Promise<void> {
    await this.tabManager.init();
    this.tabCount = this.tabManager.getTabCount();
    this.isCloseTabDisabled = this.tabCount <= 1;
  }

  /**
   * 关闭当前标签页并自动跳转到上一个标签页
   */
  private async closeCurrentTab(): Promise<void> {
    if (this.isCloseTabDisabled) {
      return;
    }

    const tabId = this.currentTabId || this.tabManager.getActiveTab()?.id;
    if (!tabId) {
      return;
    }

    await this.tabManager.removeTab(tabId);

    // 获取删除后的新活跃标签，原地更新状态
    const newActiveTab = this.tabManager.getActiveTab();
    if (!newActiveTab) {
      return;
    }

    this.currentTabId = newActiveTab.id;
    this.tabCount = this.tabManager.getTabCount();
    this.isCloseTabDisabled = this.tabCount <= 1;

    if (!newActiveTab.isEmpty) {
      router.pushUrl({
        url: 'noteeditpage/Index',
        params: {
          tabId: newActiveTab.id,
          filePath: newActiveTab.filePath,
          fileName: newActiveTab.fileName
        }
      }).catch((err: Error) => {
        console.error('Failed to navigate to editor: ' + err.message);
      });
    }
  }

  // 获取避让区域信息
  private getAvoidArea(): void {
    let windowClass: window.Window | undefined = undefined;
    window.getLastWindow(this.getUIContext().getHostContext(), (err: BusinessError, data: window.Window) => {
      if (err.code) {
        console.error('Failed to get window. Cause: ' + JSON.stringify(err));
        return;
      }
      windowClass = data;

      try {
        // 获取避让区域
        let avoidArea: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        
        // 使用统一的避让区域配置
        const config: AvoidAreaConfig = getAvoidAreaConfig();
        this.avoidAreaTop = config.top;
        this.avoidAreaBottom = avoidArea.bottomRect.height; // 底部使用系统实际值
        
        console.info(`HomePage Avoid area - Top: ${this.avoidAreaTop}, Bottom: ${this.avoidAreaBottom}`);
      } catch (error) {
        console.error('Failed to get avoid area. Cause: ' + JSON.stringify(error));
        // 设置默认值
        const config: AvoidAreaConfig = getAvoidAreaConfig();
        this.avoidAreaTop = config.top;
        this.avoidAreaBottom = config.bottom;
      }
    });
  }

  // 创建新文件并跳转到编辑页面
  private async createNewFile(): Promise<void> {
    try {
      const fileName = await this.fileService.generateUniqueFileName('未命名', 'md');
      const filePath = await this.fileService.createFile(fileName);

      if (!filePath) {
        console.error('Failed to create new file');
        return;
      }

      const tabManager = TabManager.getInstance();

      if (this.currentTabId) {
        // Tab 管理模式下：更新当前标签的文件信息
        await tabManager.setTabFile(this.currentTabId, fileName, filePath);
      } else {
        // 独立模式下：作为新标签创建
        await tabManager.addTab(fileName, filePath);
      }

      console.info(`New file created: ${filePath}`);

      router.pushUrl({
        url: 'noteeditpage/Index',
        params: {
          tabId: this.currentTabId,
          filePath: filePath,
          fileName: fileName
        }
      }).catch(() => {
        console.error('Failed to navigate to note edit page');
      });
    } catch (err) {
      console.error('Failed to create new file: ' + JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 顶部极简导航栏 - 使用优化后的避让区域
      TopNavigationBar()
        .padding({ top: this.avoidAreaTop })
      
      // 中间垂直居中的胶囊按钮区域
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        // 创建新文件按钮
        Button() {
          Text('创建新文件')
        }
        .width(160)
        .height(44)
        .fontSize(16)
        .fontColor('#8B5CF6')
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#F8FAFC')
        .borderRadius(22)
        .margin({ top: 12, bottom: 12 })
        .onClick(() => {
          this.createNewFile();
        })
        
        // 关闭标签页按钮（仅标签数 > 1 时可用）
        Button() {
          Text('关闭标签页')
        }
        .width(160)
        .height(44)
        .fontSize(16)
        .fontColor(this.isCloseTabDisabled ? '#B89EEE' : '#8B5CF6')
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.isCloseTabDisabled ? '#F0EEF5' : '#F8FAFC')
        .borderRadius(22)
        .margin({ top: 12, bottom: 12 })
        .enabled(!this.isCloseTabDisabled)
        .onClick(() => {
          this.closeCurrentTab();
        })
      }
      .layoutWeight(1)

      // 底部悬浮图标导航栏 - 添加底部避让区域padding
      BottomIconNavigation({ tabCount: this.tabCount, currentTabId: this.currentTabId })
        .padding({ bottom: this.avoidAreaBottom })
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#F5F7F9")
  }
}

@Component
struct TopNavigationBar {
  build() {
    Row() {
      // 左侧列表图标按钮
      Button() {
        Image($r('app.media.indent_right'))
          .width(24)
          .height(24)
      }
      .type(ButtonType.Circle)
      .stateEffect(true)
      .borderRadius(20)
      .backgroundColor(Color.White)
      .shadow({
        radius: 12,
        color: '#d7d7d7',
        offsetX: 0,
        offsetY: 3
      })

      // 中间标题
      Text('新标签页')
        .fontSize(18)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧三点图标按钮
      Button() {
        Image($r('app.media.exported'))
          .width(24)
          .height(24)
      }
      .type(ButtonType.Circle)
      .stateEffect(true)
      .borderRadius(20)
      .backgroundColor(Color.White)
      .shadow({
        radius: 12,
        color: '#d7d7d7',
        offsetX: 0,
        offsetY: 3
      })
     }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 16,
      right: 16
    })
    .backgroundColor("#F5F7F9")
  }
}

@Component
struct BottomIconNavigation {
  @Prop tabCount: number = 0;
  @Prop currentTabId: string = '';
  private tabManager: TabManager = TabManager.getInstance();

  private navigateToTab(tabId: string, hasFile: boolean, filePath: string, fileName: string): void {
    router.pushUrl({
      url: 'homepage/Index',
      params: {
        tabId: tabId,
        autoOpenEditor: hasFile ? 'true' : '',
        filePath: filePath,
        fileName: fileName
      }
    }).catch((err: Error) => {
      console.error('Failed to navigate tab: ' + err.message);
    });
  }

  private async handlePrevTab(): Promise<void> {
    const tabs = this.tabManager.getTabs();
    const idx = tabs.findIndex(t => t.id === this.currentTabId);
    if (idx > 0) {
      const tab = tabs[idx - 1];
      await this.tabManager.setActiveTabById(tab.id);
      this.navigateToTab(tab.id, !tab.isEmpty, tab.filePath, tab.fileName);
    }
  }

  private async handleNextTab(): Promise<void> {
    const tabs = this.tabManager.getTabs();
    const idx = tabs.findIndex(t => t.id === this.currentTabId);
    if (idx >= 0 && idx < tabs.length - 1) {
      const tab = tabs[idx + 1];
      await this.tabManager.setActiveTabById(tab.id);
      this.navigateToTab(tab.id, !tab.isEmpty, tab.filePath, tab.fileName);
    }
  }

  private hasPrevTab(): boolean {
    const tabs = this.tabManager.getTabs();
    const idx = tabs.findIndex(t => t.id === this.currentTabId);
    return idx > 0;
  }

  private hasNextTab(): boolean {
    const tabs = this.tabManager.getTabs();
    const idx = tabs.findIndex(t => t.id === this.currentTabId);
    return idx >= 0 && idx < tabs.length - 1;
  }

  build() {
    // 外层：全屏居中 + 底部留白
    Row() {
      // 核心胶囊导航栏（带边框 + 阴影 + 悬浮）
      Row() {
        // 左箭头 - 上一个标签页
        this.arrowPrevButton()
        // 右箭头 - 下一个标签页
        this.arrowNextButton()
        // 搜索
        this.navItem($r('app.media.magnifyingglass'), Color.Black)
        // 加号 - 创建新标签页
        Button() {
          Image($r('app.media.plus'))
            .width(24)
            .height(24)
            .fillColor(Color.Black)
        }
        .type(ButtonType.Circle)
        .stateEffect(false)
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)
        .height('100%')
        .onClick(async () => {
          const tabId = await TabManager.getInstance().addEmptyTab();
          router.pushUrl({
            url: 'homepage/Index',
            params: { tabId: tabId }
          });
        })
        // 标签页 - 第五个按钮（居中显示数量）
        Button() {
          Text(`${this.tabCount}`)
            .fontSize(15)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Medium)
        }
        .type(ButtonType.Normal)
        .stateEffect(false)
        .backgroundColor(Color.Transparent)
        .border({
          width: 1.5,
          color: Color.Black,
          style: BorderStyle.Solid,
          radius: 8
        })
        .borderRadius(8)
        .height(24)
        .flexGrow(1)
        .onClick(() => {
          router.pushUrl({
            url: 'tabmanagement/Index'
          }).catch(() => {
            // TODO: Implement error handling.
          });
        })
        // 菜单
        this.navItem($r('app.media.more'), Color.Black)
      }
      .width('90%')
      .height(64)
      .backgroundColor(Color.White)        // 纯白背景
      .borderRadius(32)                   // 胶囊大圆角
      .shadow({                            // 柔和悬浮阴影
        radius: 12,
        color: '#d7d7d7',
        offsetX: 0,
        offsetY: 3
      })
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)    // 垂直居中
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ bottom: 24 }) // 距离底部
  }

  // 封装按钮：自动均分 + 居中
  @Builder
  navItem(icon: ResourceStr, color: string | Color) {
    Button() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(color)
    }
    .type(ButtonType.Circle)
    .stateEffect(false)
    .backgroundColor(Color.Transparent)
    .borderRadius(20)
    .flexGrow(1)           // 6个按钮自动等分宽度
    .height('100%')
  }

  // 左箭头 - 上一个标签页
  @Builder
  arrowPrevButton() {
    Button() {
      Image($r('app.media.arrow_left'))
        .width(24)
        .height(24)
        .fillColor(this.hasPrevTab() ? Color.Black : '#C7C7CC')
    }
    .type(ButtonType.Circle)
    .stateEffect(false)
    .backgroundColor(Color.Transparent)
    .borderRadius(20)
    .flexGrow(1)
    .height('100%')
    .enabled(this.hasPrevTab())
    .onClick(() => {
      if (this.hasPrevTab()) {
        this.handlePrevTab();
      }
    })
  }

  // 右箭头 - 下一个标签页
  @Builder
  arrowNextButton() {
    Button() {
      Image($r('app.media.arrow_right'))
        .width(24)
        .height(24)
        .fillColor(this.hasNextTab() ? Color.Black : '#C7C7CC')
    }
    .type(ButtonType.Circle)
    .stateEffect(false)
    .backgroundColor(Color.Transparent)
    .borderRadius(20)
    .flexGrow(1)
    .height('100%')
    .enabled(this.hasNextTab())
    .onClick(() => {
      if (this.hasNextTab()) {
        this.handleNextTab();
      }
    })
  }
}