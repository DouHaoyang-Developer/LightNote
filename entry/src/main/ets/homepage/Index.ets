import { PageMap } from './detail/SecondPageBuilder'
import { HomePage } from './pages/HomePage';
import { window, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry({ routeName: 'homepage/Index' })
@Component
struct Index {
  private scroller: Scroller = new Scroller();
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @State title: string = 'page_title';
  private lastBackPressTime: number = 0;
  private readonly EXIT_INTERVAL: number = 2000;

  onBackPress(): boolean | void {
    const now = Date.now();
    if (now - this.lastBackPressTime < this.EXIT_INTERVAL) {
      // 2秒内第二次按返回，退出应用
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.terminateSelf();
      return true;
    }

    // 第一次按返回，提示再按一次
    this.lastBackPressTime = now;
    promptAction.showToast({
      message: '再按一次返回退出应用',
      duration: 2000
    });
    return true;
  }

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

  build() {
    Navigation(this.appPathStack) {
      Column() {
        Scroll(this.scroller) {
          Column() {
            HomePage()
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .backgroundColor('#F5F7F9')
      .height('100%')
    }
    .navDestination(PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}