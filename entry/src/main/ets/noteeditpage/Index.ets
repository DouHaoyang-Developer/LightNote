import { PageMap } from './detail/SecondPageBuilder'
import { NoteEditPage } from './pages/NoteEditPage';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

// 避让区域配置接口
interface AvoidAreaConfig {
  top: number;    // 顶部避让区域大小
  bottom: number; // 底部避让区域大小
}

// 获取统一的避让区域配置
function getAvoidAreaConfig(): AvoidAreaConfig {
  return {
    top: 35,    // 顶部避让区域大小
    bottom: 60  // 底部避让区域大小
  };
}

@Entry
@Component
struct Index {
  private scroller: Scroller = new Scroller();
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @State title: string = 'page_title';
  @State avoidAreaTop: number = 0;
  @State avoidAreaBottom: number = 0;

  aboutToAppear(): void {
    // 页面显示时确保沉浸式效果
    this.setImmersiveMode();
    // 设置统一的避让区域
    this.setAvoidArea();
  }

  onPageShow(): void {
    // 页面显示时设置沉浸式效果
    this.setImmersiveMode();
    // 重新设置避让区域
    this.setAvoidArea();
  }

  onPageHide(): void {
    // 页面隐藏时恢复默认状态（可选）
    // this.resetImmersiveMode();
  }

  // 设置沉浸式模式
  private setImmersiveMode(): void {
    let windowClass: window.Window | undefined = undefined;
    window.getLastWindow(this.getUIContext().getHostContext(), (err: BusinessError, data: window.Window) => {
      if (err.code) {
        console.error('Failed to get window. Cause: ' + JSON.stringify(err));
        return;
      }
      windowClass = data;

      // 设置全屏布局
      windowClass.setWindowLayoutFullScreen(true).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error('Failed to setting the window layout. Cause: ' + JSON.stringify(err));
      });

      // 设置状态栏和导航栏样式
      let sysBarProps: window.SystemBarProperties = {
        statusBarColor: '#F5F7F9', // 与界面背景色一致
        navigationBarColor: '#F5F7F9', // 与界面背景色一致
        statusBarContentColor: '#000000', // 黑色文字
        navigationBarContentColor: '#000000' // 黑色文字
      };

      windowClass.setWindowSystemBarProperties(sysBarProps).then(() => {
        console.info('Succeeded in setting the system bar properties.');
      }).catch((err: BusinessError) => {
        console.error('Failed to setting the system bar properties. Cause: ' + JSON.stringify(err));
      });
    });
  }

  // 设置统一的避让区域
  private setAvoidArea(): void {
    const config: AvoidAreaConfig = getAvoidAreaConfig();
    this.avoidAreaTop = config.top;
    this.avoidAreaBottom = config.bottom;
    console.info(`NoteEditPage Avoid area - Top: ${this.avoidAreaTop}, Bottom: ${this.avoidAreaBottom}`);
  }

  build() {
    Navigation(this.appPathStack) {
      Column() {
        Scroll(this.scroller) {
          Column() {
            NoteEditPage()
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .backgroundColor('#F5F7F9') // 修改为浅灰色背景，与NoteEditPage保持一致
      .height('100%')
      .padding({ top: this.avoidAreaTop, bottom: this.avoidAreaBottom })
    }
    .navDestination(PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}