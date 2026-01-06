# AiCodeMirror Monitor

一款 macOS 应用，用于监控 [AiCodeMirror](https://aicodemirror.com) 账户余额。

## 功能

- **菜单栏快捷访问** - 在菜单栏查看账户余额
- **仪表盘视图** - 显示详细的余额信息（订阅状态、按量付费余额）
- **桌面小组件** - 支持小、中、大三种尺寸的桌面小组件
- **自动刷新** - 定时自动更新余额数据
- **通知提醒** - 余额变动时发送通知

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 15.0 或更高版本（用于编译）

## 安装

1. 克隆仓库
   ```bash
   git clone https://github.com/yourusername/aicodemirror-monitor.git
   ```

2. 使用 Xcode 打开项目
   ```bash
   open "AiCodeMirror Monitor.xcodeproj"
   ```

3. 配置开发者团队
   - 在 Xcode 中选择项目 → Signing & Capabilities
   - 为 `AiCodeMirror Monitor` 和 `BalanceWidgetExtension` 两个 Target 选择你的开发者团队

4. 编译并运行

## 使用

1. 启动应用后，点击菜单栏图标
2. 首次使用需要登录 AiCodeMirror 账户
3. 登录后即可在菜单栏和小组件中查看余额

## 许可证

MIT License
