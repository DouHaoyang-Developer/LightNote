import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { FileService } from '../utils/FileService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 全局初始化文件服务上下文
    FileService.getInstance().setContext(this.context);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 获取主窗口并设置沉浸式效果
    windowStage.getMainWindow((err: BusinessError, windowClass) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err));
        return;
      }

      // 设置窗口为全屏布局
      windowClass.setWindowLayoutFullScreen(true).then(() => {
        hilog.info(DOMAIN, 'testTag', 'Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', 'Failed to setting the window layout. Cause: %{public}s', JSON.stringify(err));
      });

      // 设置状态栏和导航栏样式，与界面背景色匹配
      let sysBarProps: window.SystemBarProperties = {
        statusBarColor: '#F5F7F9', // 与界面背景色一致
        navigationBarColor: '#F5F7F9', // 与界面背景色一致
        statusBarContentColor: '#000000', // 黑色文字
        navigationBarContentColor: '#000000' // 黑色文字
      };

      windowClass.setWindowSystemBarProperties(sysBarProps).then(() => {
        hilog.info(DOMAIN, 'testTag', 'Succeeded in setting the system bar properties.');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', 'Failed to setting the system bar properties. Cause: %{public}s', JSON.stringify(err));
      });
    });

    windowStage.loadContent('homepage/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}