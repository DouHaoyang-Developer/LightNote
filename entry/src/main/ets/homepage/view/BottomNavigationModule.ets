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
import {
  Data, DataSource
} from '../viewmodel/BottomNavigationModuleData';
import { LoadingStatus } from '../common/CommonEnums';
import { LoadingFailedView } from '../view/LoadingFailedView';
import { BreakpointConstants } from '../common/BreakpointConstants';
import { BreakpointType } from '../util/BreakpointType';
import LazyDataSource from '../util/LazyDataSource';
import { CommonConstants } from '../common/CommonConstants';

@Component
export struct BottomNavigationModule {
  @State itemModel: Data =
    Data.getInstance();
  @State lazyDataSource: LazyDataSource<DataSource> =
    this.itemModel.lazyDataSource;
  @State moduleTitle: string = "模块名";
  @State moduleRedirectContent: string = "跳转";
  @State rowHeight: number = 50;
  @State rowGap: number = 6;
  private columnGapArray: number[] = [0, 10, 12];
  private columnNumberArray: number[] = [3, 6, 6];
  private rowNumberArray: number[] = [2, 1, 1];
  @State loadingStatus: LoadingStatus = LoadingStatus.OFF;
  @Consume('appPathStack') appPathStack: NavPathStack;
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;

  jump(pageName: string = 'EmptyPagePathStack'): void {
    this.appPathStack.pushPathByName(pageName, undefined);
  }

  aboutToAppear() {
    this.loadResources();
  }

  loadResources(): void {
    this.loadingStatus = LoadingStatus.LOADING;
    this.itemModel.getResources().then(() => {
      this.loadingStatus = LoadingStatus.SUCCESS;
    }).catch(() => {
      this.loadingStatus = LoadingStatus.FAILED;
    });
  }

  build() {
    Column() {
      Column() {
        if (this.loadingStatus === LoadingStatus.FAILED) {
          LoadingFailedView(() => this.loadResources())
        }
        if (this.loadingStatus === LoadingStatus.SUCCESS) {
          Grid() {
            LazyForEach(this.lazyDataSource,
              (item: DataSource, index: number) => {
                GridItem() {
                  Row() {
                    if (index > 0) {
                      Divider()
                        .vertical(true)
                        .strokeWidth(1)
                        .color($r('sys.color.ohos_id_divider_color'))
                        .height('80%')
                        .align(Alignment.Start)
                    }
                    HorizontalGraphicTextEntranceItem({
                      icon: item.getIcon(),
                      title: item.getTitle()
                    })
                      .align(Alignment.Center)
                      .width('100%')
                  }
                  .width('100%')
                }
                .onClick(() => {
                  this.jump("BottomNavigationModuleDetail" + index.toString())
                })
                .backgroundColor($r('app.color.comp_background_primary_trans'))
              }, (item: DataSource, index: number) => index + JSON.stringify(item))
          }
          .columnsTemplate(("1fr ").repeat(new BreakpointType(this.columnNumberArray[0], this.columnNumberArray[1],
            this.columnNumberArray[2]).getValue(this.currentWidthBreakpoint)).trim())
          .rowsTemplate(("1fr ").repeat(new BreakpointType(this.rowNumberArray[0], this.rowNumberArray[1],
            this.rowNumberArray[2]).getValue(this.currentWidthBreakpoint)).trim())
          .height((this.rowGap + this.rowHeight) * new BreakpointType(this.rowNumberArray[0], this.rowNumberArray[1],
            this.rowNumberArray[2]).getValue(this.currentWidthBreakpoint))
          .columnsGap(new BreakpointType(this.columnGapArray[0], this.columnGapArray[1],
            this.columnGapArray[2]).getValue(this.currentWidthBreakpoint))
          .rowsGap(this.rowGap)
          .borderRadius($r('sys.float.corner_radius_level8'))
        }
      }
      .width('92%')
      .margin({ bottom: "10vp" })
    }.width('100%')
  }
}

@Component
export struct HorizontalGraphicTextEntranceItem {
  @State title: string = '模块名';
  @State icon: Resource = $r("app.media.ic_failure");

  build() {
    Row() {
      /**
       * TODO:
       * please modify it according to the actual situation.
       * directly modify {@link Data#ICONS}
       * or refactor method {@code getResources()} to implement your custom code logic.
       * @see Data#getResources()
       */
      Image(this.icon)
        .height('40%')
        .margin({ right: 2 })
        .borderRadius($r('sys.float.corner_radius_level8'))
        .fillColor($r('app.color.comp_emphasize_secondary'))
      Column() {
        /**
         * TODO:
         * please modify it according to the actual situation.
         * directly modify {@link Data#TITLES}
         * or refactor method {@code getResources()} to implement your custom code logic.
         * @see Data#getResources()
         */
        Text(this.title)
          .margin({ bottom: '3vp' })
          .fontColor($r('sys.color.font_primary'))
          .maxFontSize($r('app.integer.subtitle_text_S'))
          .minFontSize($r('app.integer.caption_text_L'))
          .fontWeight('Medium')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 6, right: 2 })
    }
    .height(CommonConstants.FULL_PERCENT)
  }
}

@Component
export struct BottomNavigationModuleTitleInfo {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;
  public title: string = '';
  public moduleRedirectContent: string = '';
  @Consume('appPathStack') appPathStack: NavPathStack;
  public onJump?: () => void;

  jump(): void {
    this.appPathStack.pushPathByName('EmptyPagePathStack', undefined);
  }

  build() {
    if (this.title.length) {
      Row() {
        Text(this.title)
          .fontSize($r('app.integer.subtitle_text_L'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
        Text(this.moduleRedirectContent)
          .fontColor($r('app.color.font_secondary'))
          .fontSize($r('app.integer.body_text_S'))
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.onJump) {
              this.onJump()
            } else {
              this.jump()
            }
          })
      }
      .width(CommonConstants.FULL_PERCENT)
      .height("44vp")
      .justifyContent(FlexAlign.SpaceBetween)
      .borderRadius($r('sys.float.corner_radius_level8'))
    }
  }
}