import { TabManager, TabItem } from '../model/TabManager';
import router from '@ohos.router';

@Component
export struct BrowserTabManager {
  @Consume('appPathStack') appPathStack: NavPathStack;
  @State tabList: TabItem[] = [];
  @State tabCountText: string = '0个标签页';

  private tabManager: TabManager = TabManager.getInstance();

  aboutToAppear(): void {
    this.refreshTabs();
  }

  onPageShow(): void {
    this.refreshTabs();
  }

  private async refreshTabs(): Promise<void> {
    await this.tabManager.init();
    this.tabList = this.tabManager.getTabs();
    this.tabCountText = `${this.tabList.length}个标签页`;
  }

  /**
   * 点击标签卡片 → 导航到首页或编辑器
   */
  private async openTab(tab: TabItem): Promise<void> {
    await this.tabManager.setActiveTabById(tab.id);
    if (tab.isEmpty) {
      router.pushUrl({
        url: 'homepage/Index',
        params: { tabId: tab.id }
      }).catch((err: Error) => {
        console.error('Failed to navigate to homepage: ' + err.message);
      });
    } else {
      router.pushUrl({
        url: 'homepage/Index',
        params: {
          tabId: tab.id,
          autoOpenEditor: true,
          filePath: tab.filePath,
          fileName: tab.fileName
        }
      }).catch((err: Error) => {
        console.error('Failed to navigate to homepage: ' + err.message);
      });
    }
  }

  /**
   * 关闭标签
   */
  private async closeTab(tabId: string): Promise<void> {
    await this.tabManager.removeTab(tabId);
    await this.refreshTabs();
  }

  /**
   * 切换置顶
   */
  private async togglePinTab(tabId: string): Promise<void> {
    await this.tabManager.togglePin(tabId);
    await this.refreshTabs();
  }

  /**
   * 新建标签
   */
  private async createNewTab(): Promise<void> {
    const tabId = await this.tabManager.addEmptyTab();
    router.pushUrl({
      url: 'homepage/Index',
      params: {
        tabId: tabId
      }
    }).catch((err: Error) => {
      console.error('Failed to navigate to homepage: ' + err.message);
    });
  }

  build() {
    Column() {
      // 主内容区域 —— 标签卡片列表
      Column() {
        if (this.tabList.length === 0) {
          // 空状态
          Column() {
            Text('暂无打开的标签页')
              .fontSize(16)
              .fontColor('#999999')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })

            Text('点击下方 + 创建新标签')
              .fontSize(13)
              .fontColor('#BBBBBB')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 标签列表
          Scroll() {
            Column() {
              ForEach(this.tabList, (tab: TabItem) => {
                this.tabCard(tab)
              }, (tab: TabItem) => tab.id)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .width('100%')
        }
      }
      .layoutWeight(1)
      .width('100%')

      // 底部操作栏
      Row() {
        // 左侧加号按钮
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.plus'))
            .width(20)
            .height(20)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .width('25%')
        .onClick(() => {
          this.createNewTab();
        })

        // 中间标签页数量
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Row() {
            Text(this.tabCountText)
              .fontSize(15)
              .fontColor('#000000')
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.chevron_down'))
              .width(20)
              .height(20)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .backgroundColor(Color.Transparent)
        .width('50%')

        // 右侧完成按钮
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Text("完成")
            .fontSize(15)
            .fontColor('#000000')
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor(Color.Transparent)
        .width('25%')
        .onClick(() => {
          router.back();
        })
      }
      .width('100%')
      .height(52)
      .backgroundColor('#F5F5F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }

  /**
   * 标签卡片
   */
  @Builder
  tabCard(tab: TabItem) {
    Column() {
      Row() {
        // 左侧：置顶标记 + 图标 + 文字
        Row() {
          if (tab.isPinned) {
            Image($r('app.media.pin_fill_1'))
              .width(14)
              .height(14)
              .fillColor('#9D50FF')
              .margin({ right: 6 })
          }

          Image($r('app.media.doc'))
            .width(20)
            .height(20)

          Text(tab.isEmpty ? '新标签页' : tab.fileName)
            .fontSize(14)
            .fontColor(tab.isEmpty ? '#999999' : (tab.isActive ? '#9D50FF' : '#000000'))
            .fontWeight(tab.isActive ? FontWeight.Medium : FontWeight.Normal)
            .margin({ left: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: '60%' })
        }
        .alignItems(VerticalAlign.Center)
        .layoutWeight(1)

        // 右侧按钮组
        Row() {
          // 置顶按钮
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.pin'))
              .width(14)
              .height(14)
              .fillColor(tab.isPinned ? '#9D50FF' : '#999999')
          }
          .width(26)
          .height(26)
          .backgroundColor(tab.isPinned ? '#EDE9FE' : '#F0F0F0')
          .borderRadius(14)
          .onClick(() => {
            this.togglePinTab(tab.id);
          })

          // 关闭按钮
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.xmark'))
              .width(14)
              .height(14)
              .fillColor('#999999')
          }
          .width(26)
          .height(26)
          .backgroundColor('#F0F0F0')
          .borderRadius(14)
          .margin({ left: 8 })
          .onClick(() => {
            this.closeTab(tab.id);
          })
        }
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 14,
        bottom: 14
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({
      width: tab.isActive ? 1.5 : 1,
      color: tab.isActive ? '#9D50FF' : '#E8E8E8'
    })
    .shadow({
      radius: tab.isActive ? 8 : 4,
      color: tab.isActive ? '#1A9D50FF' : '#1A000000',
      offsetX: 0,
      offsetY: tab.isActive ? 3 : 1
    })
    .margin({ bottom: 10 })
    .onClick(() => {
      this.openTab(tab);
    })
  }
}
