/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Button组件参数接口
interface ButtonParams {
  type: ButtonType;
  stateEffect: boolean;
}

@Component
export struct BrowserTabManager {
  @Consume('appPathStack') appPathStack: NavPathStack;
  build() {
    Column() {
      // 主内容区域 - 垂直居中偏上
      Column() {
        // 悬浮标签卡片
        Column() {
          // 卡片内容
          Row() {
            // 左侧图标和文字（添加间距）
            Row() {
              // 图标
              Image($r('app.media.doc'))
                .width(20)
                .height(20)
                
              // 新标签页文字（添加右边距）
              Text("新标签页")
                .fontSize(14)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium)
                .margin({ left: 8 })
            }
            .layoutWeight(1)
            .alignItems(VerticalAlign.Center)

            // 右侧按钮组（添加间距）
            Row() {
              // 固定按钮
              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Image($r('app.media.pin'))
                  .width(14)
                  .height(14)
              }
              .width(26)
              .height(26)
              .backgroundColor('#F0F0F0')
              .borderRadius(14)

              // 关闭按钮（添加左边距）
              Button({ type: ButtonType.Normal, stateEffect: true }) {
                Image($r('app.media.xmark'))
                  .width(14)
                  .height(14)
              }
              .width(26)
              .height(26)
              .backgroundColor('#F0F0F0')
              .borderRadius(14)
              .margin({ left: 8 })
            }
            .justifyContent(FlexAlign.End)
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: 16,
            bottom: 16
          })
        }
        .width('80%')
        .height(60)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .border({
          width: 1.5,
          color: '#9D50FF'
        })
        .shadow({
          radius: 12,
          color: '#1A000000',
          offsetX: 0,
          offsetY: 4
        })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 底部操作栏
      Row() {
        // 左侧加号按钮 - 圆形按钮
        Column() {
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.plus'))
              .width(20)
              .height(20)
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
        }
        .width('25%')
        .justifyContent(FlexAlign.Center)

        // 中间标签页数量 - 减小宽度，居中显示
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Row() {
            Text("1个标签页")
              .fontSize(15)
              .fontColor('#000000')
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.chevron_down'))
              .width(20)
              .height(20)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .backgroundColor(Color.Transparent)
        .width('50%')

        // 右侧完成按钮
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Text("完成")
            .fontSize(15)
            .fontColor('#000000')
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor(Color.Transparent)
        .width('25%')
        .onClick(() => {
          // 返回主页
          this.appPathStack.pop()
        })
      }
      .width('100%')
      .height(35)
      .backgroundColor('#F5F5F7')

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
    .padding({ top: 12, bottom: 12 }) // 使用统一的避让区域设置
  }
}