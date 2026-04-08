import { router } from '@kit.ArkUI';

@Entry({ routeName: 'EmptyPage' })
@Component
struct EmptyPage {
  @State content: string = (router.getParams() as Record<string, string>)['text'];
  @Consume('appPathStack') appPathStack: NavPathStack;

  build() {
    Column() {
      Row() {
        Text('empty page for ')
          .fontSize('25vp')
          .fontColor(Color.Gray)
        Text(this.content)
          .fontSize('25vp')
          .fontColor(Color.Blue)
      }
      .onClick(() => {
        this.appPathStack.pop();
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }
}