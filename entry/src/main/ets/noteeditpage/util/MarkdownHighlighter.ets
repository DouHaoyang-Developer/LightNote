import { MutableStyledString, TextSpanStyle } from '@kit.ArkUI';

/**
 * 行级样式
 */
const DEFAULT_STYLE: TextSpanStyle = new TextSpanStyle({
  fontColor: '#333333',
  fontSize: 16,
});

const HEADING_STYLES: TextSpanStyle[] = [
  new TextSpanStyle({ fontColor: '#6C3BD4', fontSize: 28, fontWeight: FontWeight.Bold }),
  new TextSpanStyle({ fontColor: '#7B2D8B', fontSize: 24, fontWeight: FontWeight.Bold }),
  new TextSpanStyle({ fontColor: '#8B5CF6', fontSize: 20, fontWeight: FontWeight.Bold }),
  new TextSpanStyle({ fontColor: '#9D50FF', fontSize: 18, fontWeight: FontWeight.Bold }),
  new TextSpanStyle({ fontColor: '#B065FB', fontSize: 16, fontWeight: FontWeight.Bold }),
  new TextSpanStyle({ fontColor: '#C084FC', fontSize: 16, fontWeight: FontWeight.Bold }),
];

const QUOTE_STYLE: TextSpanStyle = new TextSpanStyle({
  fontColor: '#8B5CF6',
  fontSize: 16,
  fontStyle: FontStyle.Italic,
});

const HR_STYLE: TextSpanStyle = new TextSpanStyle({
  fontColor: '#C7C7CC',
  fontSize: 14,
});

/**
 * 行内样式（相对于默认样式的叠加）
 */
interface InlineRange {
  start: number;
  end: number;
  style: TextSpanStyle;
}

/**
 * 将原始 Markdown 文本转换为带语法高亮的 MutableStyledString
 */
export function highlightMarkdown(text: string): MutableStyledString {
  const result = new MutableStyledString(text);
  result.setStyle(0, text.length, DEFAULT_STYLE);

  const lines = text.split('\n');
  let offset = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineLen = line.length;

    const headingMatch = line.match(/^(#{1,6})\s+(.*)/);
    const isHr = /^(---|\*\*\*|___)\s*$/.test(line);
    const isQuote = /^>\s?/.test(line);
    const isUl = /^[\-\*\+]\s+/.test(line);
    const isOl = /^\d+\.\s+/.test(line);

    if (headingMatch) {
      const level = headingMatch[1].length;
      result.setStyle(offset, lineLen, HEADING_STYLES[level - 1]);
    } else if (isHr) {
      result.setStyle(offset, lineLen, HR_STYLE);
    } else if (isQuote) {
      result.setStyle(offset, lineLen, QUOTE_STYLE);
    } else {
      // 行内高亮
      const inlineRanges = parseInlineRanges(line, offset);
      for (const r of inlineRanges) {
        result.setStyle(r.start, r.end - r.start, r.style);
      }
    }

    offset += lineLen + 1; // +1 for the '\n' separator
  }

  return result;
}

/**
 * 解析一行文本中的行内 Markdown 语法，返回样式范围列表
 */
function parseInlineRanges(line: string, lineOffset: number): InlineRange[] {
  const ranges: InlineRange[] = [];
  let i = 0;

  while (i < line.length) {
    // 粗斜体 ***text***
    const biMatch = matchAt(line, i, /^\*\*\*(.+?)\*\*\*/);
    if (biMatch) {
      ranges.push({ start: lineOffset + i, end: lineOffset + i + biMatch[0].length, style: BI_STYLE });
      i += biMatch[0].length;
      continue;
    }

    // 粗体 **text**
    const bMatch = matchAt(line, i, /^\*\*(.+?)\*\*/);
    if (bMatch) {
      ranges.push({ start: lineOffset + i, end: lineOffset + i + bMatch[0].length, style: BOLD_STYLE });
      i += bMatch[0].length;
      continue;
    }

    // 斜体 *text*（不是 **）
    const iMatch = matchAt(line, i, /^\*(?!\*)(.+?)\*(?!\*)/);
    if (iMatch) {
      ranges.push({ start: lineOffset + i, end: lineOffset + i + iMatch[0].length, style: ITALIC_STYLE });
      i += iMatch[0].length;
      continue;
    }

    // 行内代码 `text`
    const cMatch = matchAt(line, i, /^`([^`]+)`/);
    if (cMatch) {
      ranges.push({ start: lineOffset + i, end: lineOffset + i + cMatch[0].length, style: CODE_STYLE });
      i += cMatch[0].length;
      continue;
    }

    // 链接 [text](url)
    const lMatch = matchAt(line, i, /^\[([^\]]+)\]\(([^)]+)\)/);
    if (lMatch) {
      ranges.push({ start: lineOffset + i, end: lineOffset + i + lMatch[0].length, style: LINK_STYLE });
      i += lMatch[0].length;
      continue;
    }

    i++;
  }

  return ranges;
}

/**
 * 在指定位置尝试匹配，成功则返回匹配结果（含完整匹配和捕获组）
 */
function matchAt(text: string, pos: number, regex: RegExp): RegExpMatchArray | null {
  const sub = text.slice(pos);
  const m = sub.match(regex);
  return m && m.index === 0 ? m : null;
}

// ─── 行内样式 ───────────────────────────────────────────

const BOLD_STYLE: TextSpanStyle = new TextSpanStyle({ fontWeight: FontWeight.Bold });
const ITALIC_STYLE: TextSpanStyle = new TextSpanStyle({ fontStyle: FontStyle.Italic });
const BI_STYLE: TextSpanStyle = new TextSpanStyle({ fontWeight: FontWeight.Bold, fontStyle: FontStyle.Italic });

const CODE_STYLE: TextSpanStyle = new TextSpanStyle({
  fontColor: '#C0392B',
  fontFamily: 'monospace',
  fontSize: 15,
});

const LINK_STYLE: TextSpanStyle = new TextSpanStyle({
  fontColor: '#8B5CF6',
  decoration: { type: TextDecorationType.Underline, color: '#8B5CF6' },
});
