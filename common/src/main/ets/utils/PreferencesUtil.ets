/**
 * Preferences 统一封装：教材 6.2.2 的工程落地
 *
 * 【为什么包这一层】Preferences 是"内存 + 磁盘"两层，put 只改内存、flush 才落盘——
 *   业务侧每写一次都要记得 flush，忘一次就表现为"重启后数据没了"，且极难复现。
 *   这里把 flush 收进封装，业务侧不可能漏。
 *   同名实例缓存复用，避免重复 getPreferencesSync 的开销。
 *   init(context) 在 EntryAbility.onCreate 注入一次，业务侧从此零参数调用。
 */
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

export class PreferencesUtil {
  private static appContext?: common.UIAbilityContext
  private static cache: Map<string, preferences.Preferences> = new Map()

  /** 必须在 EntryAbility.onCreate 中调用一次 */
  static init(context: common.UIAbilityContext): void {
    PreferencesUtil.appContext = context
  }

  private static getPrefs(prefName: string): preferences.Preferences {
    let prefs: preferences.Preferences | undefined = PreferencesUtil.cache.get(prefName)
    if (prefs === undefined) {
      prefs = preferences.getPreferencesSync(PreferencesUtil.appContext!, { name: prefName })
      PreferencesUtil.cache.set(prefName, prefs)
    }
    return prefs
  }

  /** 写入字符串（自动 flush 落盘） */
  static async putString(prefName: string, key: string, value: string): Promise<void> {
    const prefs = PreferencesUtil.getPrefs(prefName)
    await prefs.put(key, value)
    await prefs.flush()
  }

  /** 同步读取字符串 */
  static getString(prefName: string, key: string, defaultValue: string = ''): string {
    return PreferencesUtil.getPrefs(prefName).getSync(key, defaultValue) as string
  }

  /** 删除指定 key */
  static async remove(prefName: string, key: string): Promise<void> {
    const prefs = PreferencesUtil.getPrefs(prefName)
    await prefs.delete(key)
    await prefs.flush()
  }

  /** 清空整个 prefName 下的全部数据 */
  static async clear(prefName: string): Promise<void> {
    const prefs = PreferencesUtil.getPrefs(prefName)
    await prefs.clear()
    await prefs.flush()
  }
}
