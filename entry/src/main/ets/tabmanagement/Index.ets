import { PageMap } from './detail/SecondPageBuilder'
import { BrowserTabManager } from './view/BrowserTabManager';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry({ routeName: 'tabmanagement/Index' })
@Component
struct Index {
  private scroller: Scroller = new Scroller();
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @State title: string = '标签页管理';

  aboutToAppear(): void {
    // 页面显示时确保沉浸式效果
    this.setImmersiveMode();
  }

  onPageShow(): void {
    // 页面显示时设置沉浸式效果
    this.setImmersiveMode();
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
        statusBarColor: '#F5F5F7', // 与标签页管理界面背景色一致
        navigationBarColor: '#F5F5F7', // 与标签页管理界面背景色一致
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

  build() {
    Navigation(this.appPathStack) {
      Column() {
        Scroll(this.scroller) {
          Column() {
            BrowserTabManager()
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .backgroundColor('#F5F5F7')
      .height('100%')
    }
    .navDestination(PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}