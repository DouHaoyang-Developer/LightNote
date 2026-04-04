import { BrowserTabManager } from '../view/BrowserTabManager';

@Component
export struct HomePage {
  build() {
    Column() {
      BrowserTabManager()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }
}