/**
 * 应用级状态 key 集中管理。
 *
 * 【为什么必须有这个类】AppStorageV2 / PersistenceV2 都靠字符串 key 寻址，
 *   而 key 写错或"同 key 不同类型"（一处当 number 用、一处当 class 用）编译期完全不报错，
 *   只在运行时表现为取不到值或类型错乱，是应用级状态的头号事故源。
 *   key 收敛成常量后：拼错即编译错误；想知道"谁在用这个 key"，IDE 查一次引用就有全部使用者，
 *   类型漂移当场暴露。新增应用级状态一律先来这里登记，不要在业务代码里写字面量 key。
 */
export class StateKeys {
  // 字号设置的落盘 key（PersistenceV2）；带应用前缀，避免与其他库的 key 撞名
  static readonly FONT_SETTING: string = 'zhititong.fontSetting'
}
