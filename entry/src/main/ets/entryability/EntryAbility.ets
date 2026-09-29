import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, PersistenceV2, window } from '@kit.ArkUI';
import { BackgroundMonitor, FontSetting, StateKeys } from '@zhititong/common';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 全应用唯一入口：AppNavigation（内部是根栈 Navigation，首屏放登录页）
    windowStage.loadContent('pages/AppNavigation', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      // V2 应用级状态：建立全局字号"内存单例 + 自动持久化"
      PersistenceV2.connect(FontSetting, StateKeys.FONT_SETTING, () => new FontSetting());
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // 预留：回到前台暂无逻辑，保留回调以完整呈现生命周期对
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    // 应用切到后台：考试进行中则记一次（防作弊计数）。
    // 同 key 再 connect 取回的是同一个实例，不会重建、也不会把已累计的 count 冲掉；
    // 要不要计数由 BackgroundMonitor.increase() 自己判，这里不读 monitoring。
    AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
      () => new BackgroundMonitor())!.increase();
  }
}