import { fileIo as fs, ReadOptions, ListFileOptions } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 文件服务工具类
 * 提供文件创建、读取、写入等功能
 */
export class FileService {
  private static instance: FileService;
  private context: common.UIAbilityContext | null = null;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): FileService {
    if (!FileService.instance) {
      FileService.instance = new FileService();
    }
    return FileService.instance;
  }

  /**
   * 设置应用上下文
   */
  public setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 获取应用文件目录路径
   */
  private getFilesDir(): string {
    if (!this.context) {
      console.error('Context is not set. Please call setContext() first.');
      return '';
    }
    return this.context.filesDir;
  }

  /**
   * 创建新文件
   * @param fileName 文件名
   * @returns 文件路径
   */
  public createFile(fileName: string): string {
    const filesDir = this.getFilesDir();
    if (!filesDir) {
      console.error('Cannot get files directory');
      return '';
    }
    
    const filePath = `${filesDir}/${fileName}`;
    
    try {
      // 创建并打开文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      
      // 写入初始内容（可以为空）
      fs.writeSync(file.fd, '');
      
      // 关闭文件
      fs.closeSync(file);
      
      console.info(`File created successfully: ${filePath}`);
      return filePath;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to create file: ${err.message}`);
      return '';
    }
  }

  /**
   * 读取文件内容
   * @param filePath 文件路径
   * @returns 文件内容字符串
   */
  public readFile(filePath: string): string {
    try {
      // 检查文件是否存在
      if (!fs.accessSync(filePath)) {
        console.warn(`File does not exist: ${filePath}`);
        return '';
      }

      // 打开文件
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      
      // 获取文件大小
      const stats = fs.statSync(filePath);
      const fileSize = stats.size;
      
      // 读取文件内容
      const arrayBuffer = new ArrayBuffer(fileSize);
      const readOptions: ReadOptions = {
        offset: 0,
        length: fileSize
      };
      
      const readLen = fs.readSync(file.fd, arrayBuffer, readOptions);
      
      // 转换为字符串
      const buf = buffer.from(arrayBuffer, 0, readLen);
      const content = buf.toString();
      
      // 关闭文件
      fs.closeSync(file);
      
      console.info(`File read successfully: ${filePath}`);
      return content;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to read file: ${err.message}`);
      return '';
    }
  }

  /**
   * 写入文件内容
   * @param filePath 文件路径
   * @param content 要写入的内容
   */
  public writeFile(filePath: string, content: string): void {
    try {
      // 打开文件（如果不存在则创建）
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      
      // 写入内容
      const writeLen = fs.writeSync(file.fd, content);
      
      // 关闭文件
      fs.closeSync(file);
      
      console.info(`File written successfully: ${filePath}, length: ${writeLen}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to write file: ${err.message}`);
    }
  }

  /**
   * 检查文件是否存在
   * @param filePath 文件路径
   * @returns 是否存在
   */
  public fileExists(filePath: string): boolean {
    try {
      return fs.accessSync(filePath);
    } catch (error) {
      return false;
    }
  }

  /**
   * 生成唯一文件名（避免重名）
   * @param baseName 基础文件名
   * @param extension 文件扩展名
   * @returns 唯一文件名
   */
  public generateUniqueFileName(baseName: string, extension: string): string {
    const filesDir = this.getFilesDir();
    if (!filesDir) {
      console.error('Cannot get files directory');
      return `${baseName}.${extension}`;
    }
    
    let fileName = `${baseName}.${extension}`;
    let counter = 1;
    
    // 检查文件是否已存在，如果存在则添加数字后缀
    while (this.fileExists(`${filesDir}/${fileName}`)) {
      fileName = `${baseName}(${counter}).${extension}`;
      counter++;
    }
    
    return fileName;
  }

  /**
   * 获取所有.md文件列表
   * @returns 文件路径数组
   */
  public getMarkdownFiles(): string[] {
    try {
      const filesDir = this.getFilesDir();
      if (!filesDir) {
        console.error('Cannot get files directory');
        return [];
      }
      
      // 创建ListFileOptions对象
      const listFileOption: ListFileOptions = {
        recursion: false,
        listNum: 0,
        filter: {
          suffix: ['.md'],
          displayName: [],
          fileSizeOver: 0,
          lastModifiedAfter: 0
        }
      };
      
      const files = fs.listFileSync(filesDir, listFileOption);
      return files.map(file => `${filesDir}/${file}`);
    } catch (error) {
      console.error('Failed to list markdown files');
      return [];
    }
  }
}