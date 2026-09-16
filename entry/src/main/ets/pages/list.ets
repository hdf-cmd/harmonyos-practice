// 练习页：垂直列表 + 水平列表
@Entry
@ComponentV2
struct ListPage {
  // 列表数据源：真实项目里来自接口/Mock，这里先用字符串数组
  @Local verticalItems: string[] = ['列表项 1', '列表项 2', '列表项 3', '列表项 4', '列表项 5', '列表项 6', '列表项 7']
  @Local horizontalItems: string[] = ['卡片 A', '卡片 B', '卡片 C', '卡片 D', '卡片 E', '卡片 F']

  build() {
    Column({ space: 16 }) {
      // ===== 垂直列表 =====
      Text('垂直列表（往下滚）')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      List({ space: 10 }) {
        ForEach(this.verticalItems, (item: string) => {
          ListItem() {
            Text(item)
              .width('100%')
              .height(60)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .backgroundColor(Color.White)
              .borderRadius(12)
          }
        }, (item: string) => item)
      }
      .width('100%')
      .layoutWeight(1)          // 占满剩余高度，内容超出自动竖向滚动
      // 默认就是 Axis.Vertical，可以不写
      .listDirection(Axis.Vertical)

      // ===== 水平列表 =====
      Text('水平列表（往右滑）')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      List({ space: 10 }) {
        ForEach(this.horizontalItems, (item: string) => {
          ListItem() {
            Text(item)
              .width(100)
              .height(80)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .backgroundColor('#E3F2FD')
              .borderRadius(12)
          }
        }, (item: string) => item)
      }
      .width('100%')
      .height(80)
      .listDirection(Axis.Horizontal)   // 关键：改成水平方向，子项横着排、横向滚
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F5F6FA')
  }
}