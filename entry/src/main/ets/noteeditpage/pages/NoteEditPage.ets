// LightNote笔记编辑页面 - 鸿蒙NEXT系统视觉舒适度优化版
// 支持 Markdown 编辑与实时预览切换、异步文件读写、20秒自动保存、后台保存
import { FileService } from '../../utils/FileService';
import { TabManager } from '../../tabmanagement/model/TabManager';
import { Markdown, MarkdownController, MdCallback } from '@luvi/lv-markdown-in';
import { router } from '@kit.ArkUI';
import { getCompletions, shouldShowCompletion, CompletionItem } from '../util/MarkdownCompleter';

/**
 * 编辑器显示模式
 */
enum EditorMode {
  EDIT = 0,
  PREVIEW = 1
}

@Component
export struct NoteEditPage {
  @State fileName: string = '未命名';
  @State fileContent: string = '';
  @State filePath: string = '';
  @State isEditing: boolean = false;
  @State editorMode: number = EditorMode.EDIT;
  @State isEditingTitle: boolean = false;
  @State titleEverEdited: boolean = false;
  @State titleInputValue: string = '';
  @State currentTabId: string = '';
  @State completions: CompletionItem[] = [];
  @State showCompletions: boolean = false;

  private fileService: FileService = FileService.getInstance();
  private mdController: MarkdownController = new MarkdownController();
  private autoSaveTimer: number = -1;
  private mdCallback: MdCallback = {
    complete: () => {
      console.info('Markdown rendering completed');
    },
    fail: (code: number, message: string) => {
      console.error(`Markdown rendering failed: code=${code}, message=${message}`);
    }
  };

  aboutToAppear(): void {
    this.loadPageParams();
    this.startAutoSave();
    this.configureMarkdownStyle();
  }

  aboutToDisappear(): void {
    this.stopAutoSave();
  }

  onPageShow(): void {
    this.loadPageParams();
  }

  onPageHide(): void {
    // 页面隐藏时保存（切后台 / 导航离开）
    if (this.isEditing && this.filePath) {
      this.saveFileContent();
    }
  }

  // ─── Markdown 样式配置 ──────────────────────────

  private configureMarkdownStyle(): void {
    this.mdController
      // 正文文本
      .setTextSize(16)
      .setTextColor('#333333')
      .setTextLineHeight(26)
      // 标题 h1-h6
      .setTitleSize([28, 24, 20, 18, 16, 14])
      .setTitleColor(['#1A1A1A', '#1A1A1A', '#1A1A1A', '#1A1A1A', '#1A1A1A', '#1A1A1A'])
      .setTitleFontWeight([FontWeight.Bold, FontWeight.Bold, FontWeight.Bold, FontWeight.Bold, FontWeight.Bold, FontWeight.Bold])
      .setTitleLineHeight([36, 32, 28, 26, 24, 22])
      // 行内代码
      .setInlineCodeColor('#C0392B')
      .setInlineCodeBackgroundColor('#F5F0F0')
      .setInlineCodeBackgroundRadius(4)
      // 引用块
      .setQuoteBorderColor('#8B5CF6')
      .setQuoteBackgroundColor('#F8F6FC')
      .setQuoteBorderRadius(8)
      .setQuoteBorderWidth(3)
      // 代码块
      .setCodeBlockTheme('light')
      .setCodeBlockBorderRadius(8)
      // 超链接
      .setHyperlinkTextColor('#8B5CF6')
      .setHyperlinkUnderlineState(true)
      // 表格
      .setTableBorderRadius(8)
      .setTableOuterBorderColor('#E8E8E8')
      .setTableInnerBorderColor('#F0F0F0')
      .setTableTitleBackgroundColor('#F8F6FC')
      // 图片
      .setImageBorderRadius(8)
      // 分割线
      .setLineColor('#E8E8E8')
      // 列表
      .setUlPointColor('#8B5CF6')
      // 块间距（返回 void，必须放在最后）
      .setBlockSpacing(12);
  }

  // ─── 模式切换 ─────────────────────────────────

  private async toggleEditorMode(): Promise<void> {
    if (this.editorMode === EditorMode.EDIT) {
      // 切换到预览模式前，先保存正在编辑的内容
      if (this.isEditing) {
        await this.saveFileContent();
      }
      this.editorMode = EditorMode.PREVIEW;
    } else {
      this.editorMode = EditorMode.EDIT;
    }
  }

  // ─── 文件读写 ─────────────────────────────────

  private async loadPageParams(): Promise<void> {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params.filePath && params.fileName) {
        const newFilePath = params.filePath as string;
        const newFileName = params.fileName as string;

        // 相同的文件路径，跳过重复加载
        if (this.filePath === newFilePath) {
          return;
        }

        this.filePath = newFilePath;
        this.fileName = newFileName;
        this.currentTabId = (params.tabId as string) || '';

        if (this.currentTabId) {
          await TabManager.getInstance().setActiveTabById(this.currentTabId);
        } else {
          await TabManager.getInstance().addTab(this.fileName, this.filePath);
        }

        await this.loadFileContent();
      }
    } catch (err) {
      console.error('Failed to get page parameters');
    }
  }

  private async loadFileContent(): Promise<void> {
    try {
      if (await this.fileService.fileExists(this.filePath)) {
        this.fileContent = await this.fileService.readFile(this.filePath);
        console.info(`File content loaded: ${this.filePath}`);
      } else {
        console.warn(`File does not exist: ${this.filePath}`);
        this.fileContent = '';
      }
    } catch (err) {
      console.error(`Failed to load file content: ${JSON.stringify(err)}`);
      this.fileContent = '';
    }
  }

  private async saveFileContent(): Promise<void> {
    try {
      await this.fileService.writeFile(this.filePath, this.fileContent);
      console.info(`File saved: ${this.filePath}`);
      this.isEditing = false;
    } catch (err) {
      console.error(`Failed to save file: ${JSON.stringify(err)}`);
    }
  }

  private onContentChange(value: string): void {
    this.fileContent = value;
    this.isEditing = true;
  }

  // ─── 标题编辑 ─────────────────────────────────

  private startTitleEdit(): void {
    this.titleInputValue = this.fileName.replace('.md', '');
    this.isEditingTitle = true;
  }

  private async confirmTitleEdit(): Promise<void> {
    const newDisplayName = this.titleInputValue.trim();
    if (!newDisplayName || newDisplayName === this.fileName.replace('.md', '')) {
      this.isEditingTitle = false;
      return;
    }

    const newFileName = `${newDisplayName}.md`;
    const filesDir = this.fileService.getBaseDirectory();
    const newFilePath = `${filesDir}/${newFileName}`;

    const success = await this.fileService.renameFile(this.filePath, newFilePath);
    if (success) {
      await TabManager.getInstance().updateTabInfo(this.filePath, newFileName, newFilePath);
      this.fileName = newFileName;
      this.filePath = newFilePath;
      this.titleEverEdited = true;
    }
    this.isEditingTitle = false;
  }

  // ─── 自动补全 ─────────────────────────────────

  private checkCompletion(): void {
    if (this.editorMode !== EditorMode.EDIT) {
      this.showCompletions = false;
      return;
    }

    // 获取光标前的文本用于判断触发
    const text = this.fileContent;
    if (!text) {
      this.showCompletions = false;
      return;
    }

    // 检测最后一行的内容作为补全触发依据
    const lines = text.split('\n');
    const lastLine = lines[lines.length - 1];

    if (shouldShowCompletion(lastLine)) {
      this.completions = getCompletions(lastLine, lastLine);
      this.showCompletions = this.completions.length > 0;
    } else {
      this.showCompletions = false;
    }
  }

  private applyCompletion(item: CompletionItem): void {
    // 移除触发字符，插入补全文本
    const lines = this.fileContent.split('\n');
    const lastLine = lines[lines.length - 1];
    const trimmed = lastLine.trimStart();
    const indent = lastLine.slice(0, lastLine.length - trimmed.length);

    // 计算需要替换的文本（从触发字符开始的当前行尾部）
    const beforeReplace = lines.slice(0, -1).join('\n');
    const newLastLine = indent + item.insertText;
    this.fileContent = lines.length > 1
      ? beforeReplace + '\n' + newLastLine
      : newLastLine;
    this.isEditing = true;
    this.showCompletions = false;
    this.completions = [];
  }

  private dismissCompletion(): void {
    this.showCompletions = false;
    this.completions = [];
  }

  // ─── 自动保存 ─────────────────────────────────

  private startAutoSave(): void {
    if (this.autoSaveTimer !== -1) {
      return;
    }
    this.autoSaveTimer = setInterval(() => {
      if (this.isEditing && this.filePath) {
        console.info('Auto-saving triggered (20s interval)');
        this.saveFileContent();
      }
    }, 20000);
  }

  private stopAutoSave(): void {
    if (this.autoSaveTimer !== -1) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = -1;
    }
  }

  // ─── UI 构建 ──────────────────────────────────

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 左侧返回按钮
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
          if (this.isEditing) {
            this.saveFileContent();
          }
          if (this.currentTabId) {
            TabManager.getInstance().clearTabFile(this.currentTabId);
          }
          router.back();
        })

        Blank()
          .layoutWeight(1)

        // 右侧：模式切换 + 菜单胶囊
        Row() {
          // 编辑/预览切换按钮
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            if (this.editorMode === EditorMode.EDIT) {
              // 编辑模式 → 显示阅读图标
              Image($r('app.media.book_pages_fill_1'))
                .width(24)
                .height(24)
                .fillColor(Color.Black)
            } else {
              // 预览模式 → 显示编辑图标
              Image($r('app.media.text_edit'))
                .width(24)
                .height(24)
                .fillColor(Color.Black)
            }
          }
          .backgroundColor(Color.Transparent)
          .margin({ right: 12 })
          .onClick(() => {
            this.toggleEditorMode();
          })

          // 菜单按钮
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image($r('app.media.dot_grid_2x2'))
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

      // 页面主体区域
      Column() {
        // 文件名标题（编辑模式下显示）
        if (this.editorMode === EditorMode.EDIT) {
          if (this.isEditingTitle) {
            TextInput({ text: this.titleInputValue })
              .onChange((value: string) => {
                this.titleInputValue = value;
              })
              .onSubmit(() => {
                this.confirmTitleEdit();
              })
              .onBlur(() => {
                this.confirmTitleEdit();
              })
              .fontSize(28)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(Color.Transparent)
              .padding(0)
              .margin({ left: 29, top: 15, bottom: 20 })
              .width('100%')
              .textAlign(TextAlign.Start)
              .lineHeight(36)
              .defaultFocus(true)
          } else {
            Text(this.fileName.replace('.md', ''))
              .fontSize(28)
              .fontColor(this.titleEverEdited ? Color.Black : '#999999')
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Start)
              .lineHeight(36)
              .margin({ left: 29, top: 15, bottom: 20 })
              .width('100%')
              .onClick(() => {
                this.startTitleEdit();
              })
          }
        }

        if (this.editorMode === EditorMode.EDIT) {
          // 语法补全面板
          if (this.showCompletions && this.completions.length > 0) {
            Scroll() {
              Row() {
                ForEach(this.completions, (item: CompletionItem) => {
                  Button() {
                    Column() {
                      Text(item.label)
                        .fontSize(14)
                        .fontColor('#8B5CF6')
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(item.description)
                        .fontSize(11)
                        .fontColor('#999999')
                        .maxLines(1)
                    }
                    .alignItems(HorizontalAlign.Start)
                    .padding({ left: 10, right: 10 })
                  }
                  .height(44)
                  .backgroundColor('#F8F6FC')
                  .borderRadius(10)
                  .border({ width: 1, color: '#E0D5F5', style: BorderStyle.Solid })
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.applyCompletion(item);
                  })
                }, (item: CompletionItem) => item.label)
              }
              .padding({ left: 4, right: 4 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
            .height(52)
            .margin({ left: 20, right: 20, bottom: 4 })
          }

          // ── 编辑模式：TextArea + 语法标注 ──
          TextArea({
            placeholder: '开始编写你的笔记...',
            text: this.fileContent
          })
          .onChange((value: string) => {
            this.onContentChange(value);
            this.checkCompletion();
          })
          .fontSize(16)
          .fontColor(Color.Black)
          .backgroundColor("#F5F7F9")
          .borderRadius(12)
          .padding(16)
          .width('100%')
          .layoutWeight(1)
          .margin({ left: 20, right: 20 })
        } else {
          // ── 预览模式：Markdown 渲染 ──
          Scroll() {
            Column() {
              Markdown({
                controller: this.mdController,
                text: this.fileContent,
                mode: "text",
                callback: this.mdCallback
              })
              .width('100%')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 24 })
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7F9')
      .layoutWeight(1)

      // 底部编辑工具栏（仅编辑模式显示）
      if (this.editorMode === EditorMode.EDIT) {
        Row() {
          // 撤销
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.undo'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 重做
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.redo'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 小艺AI
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.xiaoyi'))
              .width(21)
              .height(21)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 粗体/文本格式
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.text_edit'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 插入
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.plus'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 标签
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.label'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 附件
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.paperclip'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 文件
          Button({ type: ButtonType.Normal, stateEffect: false }) {
            Image($r('app.media.doc'))
              .width(21)
              .height(21)
              .fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
          .borderRadius(20)
          .flexGrow(1)

          // 更多
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
        .height(56)
        .padding({ left: 8, right: 8 })
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7F9')
    .padding({ top: 24 })
  }
}
