@Entry
@Component
struct Index {
  @State title: string = '智题通'

  build() {
    Column() {
      Text(this.title)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
