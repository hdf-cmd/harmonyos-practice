import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { AppStorageV2, PersistenceV2, window } from '@kit.ArkUI';
import { BackgroundMonitor, FontSetting, Logger, StateKeys } from '@zhititong/common';

export default class EntryAbility extends UIAbility {
  // 全应用日志统一走 Logger：模板自带的 hilog + 'testTag' 会把每条生命周期日志
  // 都打进同一个测试标签下，真机捞日志时分不清是谁打的。Logger 内部仍是 hilog，
  // 换的只是 tag 收口（domain 沿用 0x0000，日志等级与格式不变）。
  private logger: Logger = new Logger('[EntryAbility]')

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.logger.info('Ability onCreate');
  }

  onDestroy(): void {
    this.logger.info('Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    this.logger.info('Ability onWindowStageCreate');

    // 全应用唯一入口：AppNavigation（内部是根栈 Navigation，首屏放登录页）
    windowStage.loadContent('pages/AppNavigation', (err) => {
      if (err.code) {
        this.logger.error(`Failed to load the content. Cause: ${JSON.stringify(err)}`);
        return;
      }
      this.logger.info('Succeeded in loading the content.');
      // V2 应用级状态：建立全局字号"内存单例 + 自动持久化"
      PersistenceV2.connect(FontSetting, StateKeys.FONT_SETTING, () => new FontSetting());
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      this.logger.error(`Failed to set colorMode. Cause: ${JSON.stringify(err)}`);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    this.logger.info('Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // 预留：回到前台暂无逻辑，保留回调以完整呈现生命周期对
    this.logger.info('Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    this.logger.info('Ability onBackground');
    // 应用切到后台：考试进行中则记一次（防作弊计数）。
    // 同 key 再 connect 取回的是同一个实例，不会重建、也不会把已累计的 count 冲掉；
    // 要不要计数由 BackgroundMonitor.increase() 自己判，这里不读 monitoring。
    AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
      () => new BackgroundMonitor())!.increase();
  }
}