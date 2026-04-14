import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { FileService } from '../../utils/FileService';

// BottomIconNavigation组件参数接口
interface BottomIconNavigationParams {
  appPathStack: NavPathStack;
}

// CapsuleButton组件参数接口
interface CapsuleButtonParams {
  text: string;
}

@Component
export struct HomePage {
  @State avoidAreaTop: number = 0;
  @State avoidAreaBottom: number = 0;
  @Consume('appPathStack') appPathStack: NavPathStack;
  private fileService: FileService = FileService.getInstance();

  aboutToAppear(): void {
    // 获取避让区域信息，确保内容不会被状态栏和导航栏遮挡
    this.getAvoidArea();
    
    // 设置文件服务的应用上下文
    const context = getContext(this) as common.UIAbilityContext;
    this.fileService.setContext(context);
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
        
        // 简化方案：使用固定的小值作为顶部避让区域
        // 由于状态栏和导航栏已经沉浸式显示，我们只需要很小的避让区域
        this.avoidAreaTop = 25; // 固定25vp，足够避让状态栏内容
        this.avoidAreaBottom = avoidArea.bottomRect.height; // 底部保持原样
        
        console.info(`Avoid area - Top: ${this.avoidAreaTop}, Bottom: ${this.avoidAreaBottom}`);
      } catch (error) {
        console.error('Failed to get avoid area. Cause: ' + JSON.stringify(error));
        // 设置默认值
        this.avoidAreaTop = 20; // 默认顶部避让20vp
        this.avoidAreaBottom = 60; // 默认底部避让60vp
      }
    });
  }

  // 创建新文件并跳转到编辑页面
  private createNewFile(): void {
    try {
      // 强制转换为 string，排除 FileService 类型问题
      const fileName = this.fileService.generateUniqueFileName('未命名', 'md') as string;
      const filePath = this.fileService.createFile(fileName) as string;

      console.info(`New file created: ${filePath}`);

      router.pushUrl({
        url: 'pages/noteeditpage/Index',
        params: {
          filePath: filePath,
          fileName: fileName
        }
      }).catch(() => {
        // TODO: Implement error handling.
      });

    } catch (error) {
      console.error('Failed to create new file: ' + JSON.stringify(error));
    }
  }

  build() {
    Column() {
      // 顶部极简导航栏 - 使用优化后的避让区域
      TopNavigationBar()
        .padding({ top: this.avoidAreaTop })
      
      // 中间垂直居中的胶囊按钮区域
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        // 创建新文件按钮 - 使用接口类型
        CapsuleButton({ text: '创建新文件' } as CapsuleButtonParams)
          .onClick(() => {
            this.createNewFile();
          })
        // 关闭标签页按钮 - 使用接口类型
        CapsuleButton({ text: '关闭标签页' } as CapsuleButtonParams)
          .onClick(() => {
            // 关闭标签页逻辑
          })
      }
      .layoutWeight(1)

      // 底部悬浮图标导航栏 - 添加底部避让区域padding
      BottomIconNavigation({ appPathStack: this.appPathStack } as BottomIconNavigationParams)
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
      // 左侧列表图标按钮 - 使用简化语法
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

      // 右侧三点图标按钮 - 使用简化语法
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
struct CapsuleButton {
  @Prop text: string = ''

  build() {
    Button() {
      Text(this.text)
    }
    .width(160)
    .height(44)
    .fontSize(16)
    .fontColor('#8B5CF6') // 淡紫色文字
    .fontWeight(FontWeight.Medium)
    .backgroundColor('#F8FAFC') // 浅白色背景
    .borderRadius(22) // 胶囊形状
    .margin({ top: 12, bottom: 12 })
  }
}

@Component
struct BottomIconNavigation {
  @Prop appPathStack: NavPathStack;

  build() {
    // 外层：全屏居中 + 底部留白
    Row() {
      // 核心胶囊导航栏（带边框 + 阴影 + 悬浮）
      Row() {
        // 左箭头
        this.navItem($r('app.media.arrow_left'), '#C7C7CC')
        // 右箭头
        this.navItem($r('app.media.arrow_right'), '#C7C7CC')
        // 搜索
        this.navItem($r('app.media.magnifyingglass'), Color.Black)
        // 加号
        this.navItem($r('app.media.plus'), Color.Black)
        // 标签页 - 第五个按钮 - 使用简化语法
        Button() {
          Image($r('app.media.rectangle'))
            .width(24)
            .height(24)
            .fillColor(Color.Black)
        }
        .type(ButtonType.Normal)
        .stateEffect(false)
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)
        .height('100%')
        .onClick(() => {
          // 跳转到标签页管理页面
          this.appPathStack.pushPathByName('tabmanagement/Index', undefined);
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
}