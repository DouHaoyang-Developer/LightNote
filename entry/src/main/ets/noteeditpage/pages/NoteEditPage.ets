// LightNote笔记编辑页面 - Obsidian式三模式架构
// 源码模式(SOURCE) | 实时阅览(LIVE) | 阅读模式(READING)
// SOURCE和LIVE共用RichEditor，光标位置天然一致
import { FileService } from '../../utils/FileService';
import { TabManager } from '../../tabmanagement/model/TabManager';
import { RichTextComponent, RichTextRepresentation } from 'rich_text_vista';
import { router } from '@kit.ArkUI';
import { getCompletions, shouldShowCompletion, CompletionItem } from '../util/MarkdownCompleter';
import { parseMarkdownSegments } from '../util/MarkdownSegmenter';
import { markdownToHtml } from '../util/MarkdownToHtml';

enum EditorView {
  SOURCE = 0,
  LIVE = 1,
  READING = 2
}

interface SpanLike {
  value: string;
}

@Component
export struct NoteEditPage {
  @State fileName: string = '未命名';
  @State fileContent: string = '';
  @State filePath: string = '';
  @State isEditing: boolean = false;
  @State editorView: EditorView = EditorView.LIVE;
  @State isEditingTitle: boolean = false;
  @State titleEverEdited: boolean = false;
  @State titleInputValue: string = '';
  @State currentTabId: string = '';
  @State completions: CompletionItem[] = [];
  @State showCompletions: boolean = false;

  private fileService: FileService = FileService.getInstance();
  private autoSaveTimer: number = -1;
  private richEditorController = new RichEditorController();
  private isRebuilding: boolean = false;

  aboutToAppear(): void {
    this.loadPageParams();
    this.startAutoSave();
  }

  aboutToDisappear(): void {
    this.stopAutoSave();
  }

  onPageShow(): void {
    this.loadPageParams();
  }

  onPageHide(): void {
    if (this.isEditing && this.filePath) {
      this.saveFileContent();
    }
  }

  // ─── RTV 辅助 ─────────────────────────────────

  private getRichTextRep(): RichTextRepresentation {
    const rep = new RichTextRepresentation();
    rep.htmlString = markdownToHtml(this.fileContent);
    return rep;
  }

  // ─── 三模式切换 ────────────────────────────────

  private cycleEditorView(): void {
    if (this.editorView === EditorView.SOURCE) {
      this.editorView = EditorView.LIVE;
    } else if (this.editorView === EditorView.LIVE) {
      this.editorView = EditorView.READING;
    } else {
      this.editorView = EditorView.SOURCE;
    }
    // 切回编辑模式时刷新 RichEditor 内容样式
    if (this.editorView === EditorView.SOURCE || this.editorView === EditorView.LIVE) {
      this.rebuildEditorFromFileContent();
    }
  }

  // ─── 文件读写 ──────────────────────────────────

  private async loadPageParams(): Promise<void> {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params.filePath && params.fileName) {
        const newFilePath = params.filePath as string;
        const newFileName = params.fileName as string;
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
      } else {
        this.fileContent = '';
      }
    } catch (err) {
      this.fileContent = '';
    }
  }

  private async saveFileContent(): Promise<void> {
    try {
      await this.fileService.writeFile(this.filePath, this.fileContent);
      this.isEditing = false;
    } catch (err) {
      console.error(`Failed to save file: ${JSON.stringify(err)}`);
    }
  }

  // ─── 标题编辑 ──────────────────────────────────

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

  // ─── 自动补全 ──────────────────────────────────

  private checkCompletion(): void {
    if (this.editorView === EditorView.READING) {
      this.showCompletions = false;
      return;
    }
    if (!this.fileContent) {
      this.showCompletions = false;
      return;
    }
    const lines = this.fileContent.split('\n');
    const lastLine = lines[lines.length - 1];
    if (shouldShowCompletion(lastLine)) {
      this.completions = getCompletions(lastLine, lastLine);
      this.showCompletions = this.completions.length > 0;
    } else {
      this.showCompletions = false;
    }
  }

  private applyCompletion(item: CompletionItem): void {
    const lines = this.fileContent.split('\n');
    const lastLine = lines[lines.length - 1];
    const trimmed = lastLine.trimStart();
    const indent = lastLine.slice(0, lastLine.length - trimmed.length);
    const beforeReplace = lines.slice(0, -1).join('\n');
    const newLastLine = indent + item.insertText;
    this.fileContent = lines.length > 1
      ? beforeReplace + '\n' + newLastLine
      : newLastLine;
    this.isEditing = true;
    this.showCompletions = false;
    this.completions = [];
    this.rebuildEditorFromFileContent();
  }

  private dismissCompletion(): void {
    this.showCompletions = false;
    this.completions = [];
  }

  // ─── RichEditor：SOURCE/LIVE 共用编辑核心 ────────

  private handleEditorChange(rangeBefore: Object, rangeAfter: Object): void {
    if (this.isRebuilding) {
      return;
    }
    this.rebuildEditorSpans();
  }

  private initEditorContent(): void {
    if (!this.fileContent) {
      return;
    }
    this.rebuildEditorFromFileContent();
  }

  private rebuildEditorFromFileContent(): void {
    if (this.editorView === EditorView.READING) {
      return;
    }
    this.buildSpansFromText(this.fileContent, -1);
  }

  private rebuildEditorSpans(): void {
    try {
      const caret = this.richEditorController.getCaretOffset();
      const spans = this.richEditorController.getSpans();
      let text = '';
      for (let i = 0; i < spans.length; i++) {
        const item = spans[i];
        if (item !== null && item !== undefined && typeof (item as SpanLike).value === 'string') {
          text += (item as SpanLike).value;
        }
      }

      if (text !== this.fileContent) {
        this.fileContent = text;
        this.isEditing = true;
        this.checkCompletion();
      }

      this.buildSpansFromText(text, caret);

      const clampedCaret = Math.min(caret, text.length);
      this.richEditorController.setCaretOffset(clampedCaret);
    } catch (err) {
      console.error('rebuildEditorSpans error: ' + JSON.stringify(err));
    }
  }

  private buildSpansFromText(text: string, caretOffset: number): void {
    this.isRebuilding = true;
    try {
      this.richEditorController.deleteSpans();

      if (this.editorView === EditorView.LIVE) {
        const segments = parseMarkdownSegments(text);
        let segOffset = 0;
        for (const seg of segments) {
          if (!seg.text) {
            continue;
          }
          const segStart = segOffset;
          const segEnd = segOffset + seg.text.length;
          segOffset = segEnd;

          if (seg.type === 'syntax') {
            const cursorInside = caretOffset < 0 || (caretOffset >= segStart && caretOffset < segEnd);
            this.richEditorController.addTextSpan(seg.text, cursorInside
              ? { style: { fontColor: '#C7C7CC', fontSize: 14, fontFamily: 'monospace' } }
              : { style: { fontColor: Color.Transparent, fontSize: 1 } });
          } else {
            this.richEditorController.addTextSpan(seg.text,
              { style: { fontColor: '#1A1A1A', fontSize: 16, fontFamily: 'monospace' } });
          }
        }
      } else {
        if (text) {
          this.richEditorController.addTextSpan(text,
            { style: { fontColor: '#1A1A1A', fontSize: 16, fontFamily: 'monospace' } });
        }
      }
    } catch (err) {
      console.error('buildSpansFromText error: ' + JSON.stringify(err));
    } finally {
      this.isRebuilding = false;
    }
  }

  // ─── 自动保存 ──────────────────────────────────

  private startAutoSave(): void {
    if (this.autoSaveTimer !== -1) {
      return;
    }
    this.autoSaveTimer = setInterval(() => {
      if (this.isEditing && this.filePath) {
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

  // ─── UI 构建 ────────────────────────────────────

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.arrow_left')).width(24).height(24)
        }
        .borderRadius(20).backgroundColor(Color.White)
        .shadow({ radius: 12, color: '#d7d7d7', offsetX: 0, offsetY: 3 })
        .onClick(() => {
          if (this.isEditing) { this.saveFileContent(); }
          if (this.currentTabId) { TabManager.getInstance().clearTabFile(this.currentTabId); }
          router.back();
        })

        Blank().layoutWeight(1)

        Row() {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text(this.viewModeLabel())
              .fontSize(13).fontColor('#8B5CF6').fontWeight(FontWeight.Medium)
          }
          .backgroundColor(Color.Transparent).margin({ right: 12 })
          .onClick(() => { this.cycleEditorView(); })

          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Image($r('app.media.dot_grid_2x2')).width(24).height(24).fillColor(Color.Black)
          }
          .backgroundColor(Color.Transparent)
        }
        .padding({ left: 18, right: 18, top: 8, bottom: 8 })
        .shadow({ radius: 12, color: '#d7d7d7', offsetX: 0, offsetY: 3 })
        .borderRadius(18).backgroundColor(Color.White)
      }
      .width('100%').height(56)
      .padding({ left: 20, right: 20, top: 0, bottom: 12 })
      .alignItems(VerticalAlign.Center).backgroundColor('#F5F7F9')

      Column() {
        if (this.editorView !== EditorView.READING) {
          if (this.isEditingTitle) {
            TextInput({ text: this.titleInputValue })
              .onChange((value: string) => { this.titleInputValue = value; })
              .onSubmit(() => { this.confirmTitleEdit(); })
              .onBlur(() => { this.confirmTitleEdit(); })
              .fontSize(28).fontColor(Color.Black).fontWeight(FontWeight.Bold)
              .backgroundColor(Color.Transparent).padding(0)
              .margin({ left: 29, top: 15, bottom: 20 }).width('100%')
              .textAlign(TextAlign.Start).lineHeight(36).defaultFocus(true)
          } else {
            Text(this.fileName.replace('.md', ''))
              .fontSize(28)
              .fontColor(this.titleEverEdited ? Color.Black : '#999999')
              .fontWeight(FontWeight.Bold).textAlign(TextAlign.Start).lineHeight(36)
              .margin({ left: 29, top: 15, bottom: 20 }).width('100%')
              .onClick(() => { this.startTitleEdit(); })
          }
        }

        if (this.editorView !== EditorView.READING) {
          if (this.showCompletions && this.completions.length > 0) {
            Scroll() {
              Row() {
                ForEach(this.completions, (item: CompletionItem) => {
                  Button() {
                    Column() {
                      Text(item.label)
                        .fontSize(14).fontColor('#8B5CF6').fontWeight(FontWeight.Medium)
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(item.description).fontSize(11).fontColor('#999999').maxLines(1)
                    }
                    .alignItems(HorizontalAlign.Start).padding({ left: 10, right: 10 })
                  }
                  .height(44).backgroundColor('#F8F6FC').borderRadius(10)
                  .border({ width: 1, color: '#E0D5F5', style: BorderStyle.Solid })
                  .margin({ right: 8 })
                  .onClick(() => { this.applyCompletion(item); })
                }, (item: CompletionItem) => item.label)
              }
              .padding({ left: 4, right: 4 })
            }
            .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
            .width('100%').height(52)
            .margin({ left: 20, right: 20, bottom: 4 })
          }
        }

        if (this.editorView === EditorView.SOURCE || this.editorView === EditorView.LIVE) {
          // SOURCE/LIVE 共用 RichEditor
          RichEditor({ controller: this.richEditorController })
            .onReady(() => { this.initEditorContent(); })
            .onDidChange((rangeBefore, rangeAfter) => {
              this.handleEditorChange(rangeBefore, rangeAfter);
            })
            .caretColor('#8B5CF6')
            .borderRadius(12)
            .padding(16)
            .width('100%').layoutWeight(1)
            .margin({ left: 20, right: 20 })
        } else {
          Scroll() {
            Column() {
              Text(this.fileName.replace('.md', ''))
                .fontSize(28).fontColor(Color.Black).fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start).lineHeight(36)
                .margin({ left: 29, top: 15, bottom: 20 }).width('100%')

              RichTextComponent({
                richText: this.getRichTextRep(),
                fontSize: 16, fontColor: '#333333', lineHeight: 26
              }).width('100%')
            }
            .width('100%').padding(16)
          }
          .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off)
          .width('100%').layoutWeight(1)
          .margin({ left: 20, right: 20 })
          .borderRadius(12)
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#F5F7F9').layoutWeight(1)

      if (this.editorView !== EditorView.READING) {
        Row() {
          this.toolButton($r('app.media.undo'))
          this.toolButton($r('app.media.redo'))
          this.toolButton($r('app.media.xiaoyi'))
          this.toolButton($r('app.media.text_edit'))
          this.toolButton($r('app.media.plus'))
          this.toolButton($r('app.media.label'))
          this.toolButton($r('app.media.paperclip'))
          this.toolButton($r('app.media.doc'))
          this.toolButton($r('app.media.exported'))
        }
        .width('92%').height(56).padding({ left: 8, right: 8 })
        .justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Center)
        .backgroundColor(Color.White).borderRadius(28)
        .shadow({ radius: 12, color: '#d7d7d7', offsetX: 0, offsetY: 3 })
        .margin({ bottom: 24 }).alignSelf(ItemAlign.Center)
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#F5F7F9').padding({ top: 24 })
  }

  @Builder
  toolButton(icon: Resource) {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Image(icon).width(21).height(21)
    }
    .backgroundColor(Color.Transparent).borderRadius(20).flexGrow(1)
  }

  private viewModeLabel(): string {
    switch (this.editorView) {
      case EditorView.SOURCE: return '源码';
      case EditorView.LIVE: return '实时阅览';
      case EditorView.READING: return '阅读';
    }
  }
}
