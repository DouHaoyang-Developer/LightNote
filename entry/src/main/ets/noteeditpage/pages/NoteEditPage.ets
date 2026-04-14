// LightNote笔记编辑页面 - 鸿蒙NEXT系统视觉舒适度优化版
// 修复底部工具栏图标显示不全问题，添加文件编辑功能
import { FileService } from '../../utils/FileService';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';

@Component
export struct NoteEditPage {
  @State fileName: string = '未命名';
  @State fileContent: string = '';
  @State filePath: string = '';
  @State isEditing: boolean = false;
  
  private fileService: FileService = FileService.getInstance();

  aboutToAppear(): void {
    // 设置文件服务的应用上下文
    const context = getContext(this) as common.UIAbilityContext;
    this.fileService.setContext(context);
    
    // 获取页面参数
    this.loadPageParams();
  }

  onPageShow(): void {
    // 重新获取页面参数（确保在页面显示时也能获取到）
    this.loadPageParams();
  }

  // 加载页面参数
  private loadPageParams(): void {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params.filePath && params.fileName) {
        this.filePath = params.filePath as string;
        this.fileName = params.fileName as string;
        this.loadFileContent();
      }
    } catch (error) {
      console.error('Failed to get page parameters');
    }
  }

  // 加载文件内容
  private loadFileContent(): void {
    try {
      if (this.fileService.fileExists(this.filePath)) {
        this.fileContent = this.fileService.readFile(this.filePath);
        console.info(`File content loaded: ${this.filePath}`);
      } else {
        console.warn(`File does not exist: ${this.filePath}`);
        this.fileContent = '';
      }
    } catch (error) {
      console.error(`Failed to load file content: ${JSON.stringify(error)}`);
      this.fileContent = '';
    }
  }

  // 保存文件内容
  private saveFileContent(): void {
    try {
      this.fileService.writeFile(this.filePath, this.fileContent);
      console.info(`File content saved: ${this.filePath}`);
      this.isEditing = false;
    } catch (error) {
      console.error(`Failed to save file content: ${JSON.stringify(error)}`);
    }
  }

  // 处理内容变化
  private onContentChange(newContent: string): void {
    this.fileContent = newContent;
    this.isEditing = true;
    
    // 可以在这里添加自动保存逻辑（可选）
    // this.autoSave();
  }

  // 自动保存（可选功能）
  private autoSave(): void {
    // 可以在这里实现自动保存逻辑
    // 例如：使用防抖函数延迟保存
  }

  build() {
    Column() {
      // 顶部导航栏 - 背景与页面一致，无边框，优化胶囊宽度
      Row() {
        // 左上角：返回按钮
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.arrow_left'))
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
        .onClick(() => {
          // 返回前检查是否需要保存
          if (this.isEditing) {
            this.saveFileContent();
          }
          // 执行返回操作
          router.back();
        })

        Blank()
          .layoutWeight(1)

        // 右上角：保存按钮（仅在编辑状态显示）
        if (this.isEditing) {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('保存')
              .fontSize(14)
              .fontColor('#8B5CF6')
              .fontWeight(FontWeight.Medium)
          }
          .borderRadius(16)
          .backgroundColor(Color.White)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .shadow({
            radius: 8,
            color: '#d7d7d7',
            offsetX: 0,
            offsetY: 2
          })
          .onClick(() => {
            this.saveFileContent();
          })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20, top: 0, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#F5F7F9')
      
      // 页面主体区域 - 优化标题位置和字号
      Column() {
        // 页面顶部居左位置：显示文件名
        Text(this.fileName.replace('.md', ''))
          .fontSize(28)
          .fontColor('#666666')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .lineHeight(36)
          .margin({ left: 33, top: 28, bottom: 24 })
          .width('100%')

        // 主体区域为文本编辑区域
        TextArea({
          placeholder: '开始编写您的笔记...',
          text: this.fileContent
        })
        .onChange((value: string) => {
          this.onContentChange(value);
        })
        .fontSize(16)
        .fontColor(Color.Black)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .padding(16)
        .width('100%')
        .layoutWeight(1)
        .margin({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7F9')
      .layoutWeight(1)
      
      // 底部编辑工具栏 - 修复图标显示不全问题
      Row() {
        // 左箭头撤销图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.undo'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)
        
        // 右箭头重做图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.redo'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 小艺AI图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.xiaoyi'))
            .width(21)
            .height(21)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // "T"文本字体编辑图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.text_edit'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 特殊字符块添加图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.plus'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 标签图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.label'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 插入附件图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.paperclip'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 插入文件图标
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.doc'))
            .width(21)
            .height(21)
            .fillColor(Color.Black)
        }
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .flexGrow(1)

        // 最右侧更多功能按钮
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Image($r('app.media.exported'))
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