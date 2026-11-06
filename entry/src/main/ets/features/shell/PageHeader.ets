// 顶栏页面标题：三个 Tab 页共用的页头（首页 / 刷题 / 我的）。
//
// 【为什么放 features/shell 而不是 common HAR】
//   @zhititong/common 的对外口径写死在它的 Index.ets 与 oh-package.json5 描述里——
//   "base / constants / model / mock / utils / log"，是一个**零 UI** 的逻辑公共层，
//   今天没有一个 ArkUI 组件从那里导出。跨 feature 的 UI 组件本仓已有先例是
//   features/assistant/AssistantEntry.ets：组件放在自己的目录里，使用方按相对路径 import。
//   本文件照这条先例走，不去破 HAR 的零 UI 边界。
//
// 【为什么是独立组件而不是三个 View 各写一遍】
//   三屏的顶栏规格完全一样（只有标题文字不同），这正是 §6.6 那条"配方分散会漂"的同一个洞：
//   首页/刷题/我的各写一份，改一处漏两处。收敛成一个组件，规格只有一处真相。
import { CommonConstants } from '@zhititong/common'

// 顶栏高度：设计稿 header 内层是 `h-14` = 56px，直读为 56vp。
const HEADER_HEIGHT: number = 56

@ComponentV2
export struct PageHeader {
  // @Param @Require：标题由使用方给，不给就是编译错误——顶栏没有"空标题"这种合法状态
  @Param @Require title: string

  build() {
    Row() {
      Text(this.title)
        // 16/600：设计稿 `text-headline-sm font-headline-sm`（16px / line-height 24 / weight 600）。
        //   不给 lineHeight——顶栏标题是单行、不参与换行，§3.3 那条"行高只给可换行文字"在这儿成立。
        .fontSize(CommonConstants.FONT_HEADLINE_SM)
        .fontWeight(CommonConstants.WEIGHT_SEMI)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        // 标题过长时截断而不是折行：折行会把 56 的固定高度撑破
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(HEADER_HEIGHT)
    // 左右 16 = 设计稿 `px-gutter`，与页面横向 gutter 同轨；不额外给顶栏内缩
    .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
    .alignItems(VerticalAlign.Center)
    // 底色取页面大底，不铺白、不加描边或阴影：
    //   设计稿 header 是 `bg-surface/85 backdrop-blur-xl`，而导出屏 token 表里 surface 与 background
    //   同为 #f8f9fb——即稿子这条顶栏本来就和页面同色、只靠毛玻璃区分。毛玻璃按 §6.4
    //   "两份设计源矛盾取更克制的那一读"已裁决不做，剩下的就是一个同色页头，
    //   所以这里连阴影也不补，免得把"没有毛玻璃"换成"多一条分割线"。
    .backgroundColor(CommonConstants.COLOR_BG_PAGE)
  }
}
