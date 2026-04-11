// LightNote笔记编辑页面 - 鸿蒙NEXT系统视觉舒适度优化版
// 修复底部工具栏图标显示不全问题
@Component
export struct NoteEditPage {
  build() {
    Column() {
      // 顶部导航栏 - 背景与页面一致，无边框，优化胶囊宽度
      Row() {
        // 左上角：左侧导航栏按钮（24x24vp，圆角8vp）
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.indent_right'))
            .width(24)
            .height(24)
        }
        .borderRadius(20)
        .backgroundColor(Color.White)
        .shadow({
          radius: 12,
          color: '#d7d7d7',
          offsetX: 0,
          offsetY: 3
        })

        Blank()
          .layoutWeight(1)

        // 右上角：双图标组合圆角胶囊按钮（优化宽度，圆角20vp）
        Row() {
          // 阅读模式按钮
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image($r('app.media.book_pages_fill_1')) // 阅读模式图标
              .width(24)
              .height(24)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .margin({ right: 12 })
          
          // 四点菜单按钮
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image($r('app.media.dot_grid_2x2')) // 四点菜单图标
              .width(24)
              .height(24)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
        }
        .padding({
          left: 18,
          right: 18,
          top: 8,
          bottom: 8
        })
        .shadow({
          radius: 12,
          color: '#d7d7d7',
          offsetX: 0,
          offsetY: 3
        })
        .borderRadius(18)
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20, top: 0, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#F5F7F9')
      
      // 页面主体区域 - 优化标题位置和字号
      Column() {
        // 页面顶部居左位置：浅灰加粗标题文字「未命名」
        Text('未命名')
          .fontSize(28)
          .fontColor('#666666')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .lineHeight(36)
          .margin({ left: 33, top: 28, bottom: 24 })
          .width('100%')

        // 主体区域为大面积空白可编辑区域
        Row() {
          Blank()
        }
        .layoutWeight(1)
        .backgroundColor('#F5F7F9')
        .margin({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7F9')
      .layoutWeight(1)
      
      // 底部编辑工具栏 - 修复图标显示不全问题
      Row() {
        // 左箭头撤销图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.undo'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)
        
        // 右箭头重做图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.redo'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 小艺AI图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.xiaoyi'))
            .width(21)
            .height(21)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // ”T“文本字体编辑图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.text_edit'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 特殊字符块添加图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.plus'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 标签图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.label'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 插入附件图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.paperclip'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 插入文件图标
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.doc'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 最右侧搜索按钮
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.magnifyingglass'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)
      }
      .width('92%')
      .height(56) // 恢复合适的工具栏高度
      .padding({ left: 8, right: 8 }) // 减少左右内边距
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(28)
      .shadow({
        radius: 12,
        color: '#d7d7d7',
        offsetX: 0,
        offsetY: 3
      })
      .margin({ bottom: 24 })
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7F9')
    .padding({ top: 24 })
  }
}