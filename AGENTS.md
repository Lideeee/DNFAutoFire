# DAF AutoFire 0.29 架构说明

本文件给 Codex、Claude 等代码代理快速理解 `0.29` 版本结构和功能用。

进入 `0.29` 目录后，先读本文件；同时也建议回到主目录查看：

- [主目录 AGENTS.md](D:/06Code/DNFAutoFire/AGENTS.md)
- [DAF_0.27/AGENTS.md](D:/06Code/DNFAutoFire/DAF_0.27/AGENTS.md)

当前主目录正在做 `0.30` 重构，`0.29` 在这里主要扮演“完整模块化版本参考”的角色。

## 0.29 是什么

这是一个运行在 Windows 上的 AutoHotkey DNF 连发工具项目。

项目当前主要能力包括：

- 按键连发
- 预设管理与快速切换
- 自动识别并切换预设
- 若干职业/功能扩展
- 基于 GDI+ 的图形界面

## 文件与目录结构

### 根目录

- `DNFAutoFire.ahk`：主入口脚本，负责装配核心模块、GUI 模块和扩展模块
- `Version.ahk`：版本信息
- `config.ini`：运行期配置文件
- `README.md`：版本说明

### `core/`

核心运行时逻辑，主要包括：

- `AppBootstrap.ahk`：启动流程、托盘、自动启动连发、退出清理
- `AutoFireController.ahk`：主连发控制
- `Config.ahk`：配置读写
- `FeatureModuleRegistry.ahk`：扩展模块注册与启停
- `GameContext.ahk`：游戏窗口上下文判断
- `GetKeycode.ahk`：键名、路由标识、发送标识转换
- `KeyRouter.ahk`：统一热键分发
- `PresetExFeatures.ahk`：预设与扩展开关联
- `PresetManager.ahk`：预设管理
- `PresetRecognition.ahk`：自动识别与自动切换预设
- `SendIP.ahk`：按键发送辅助
- `SessionState.ahk`：运行期状态
- `SingleInstance.ahk`：单实例接管

### `gui/`

图形界面与交互控制。

公共文案：

- `GuiText.ahk`：全局文案
- `MainWindowText.ahk`：主窗口文案
- `ExText.ahk`：扩展窗口文案

主窗口：

- `gui/main/Main.ahk`：主窗口入口
- `gui/main/MainWindow.ahk`：主窗口视图
- `gui/main/MainController.ahk`：主窗口控制器
- `gui/main/MainKeyGrid.ahk`：主键区交互
- `gui/main/MainPresetPanel.ahk`：预设区交互
- `gui/main/MainFeaturePanel.ahk`：扩展区交互
- `gui/main/builders/`：主窗口构建器
- `gui/main/layout/`：主窗口布局数据

独立弹窗：

- `gui/dialogs/Setting.ahk`：设置窗口
- `gui/dialogs/SettingController.ahk`：设置控制器
- `gui/dialogs/QuickSwitch.ahk`：快速切换窗口
- `gui/dialogs/QuickSwitchController.ahk`：快速切换控制器

扩展配置窗口：

- `gui/ex/ExWindowHost.ahk`：扩展窗口宿主
- `gui/ex/autoPreset/`：自动识别相关配置窗口

### `ex/`

扩展功能实现：

- `ExLvRen.ahk`：旅人逻辑
- `ExGuanYu.ahk`：关羽逻辑
- `ExPetSkill.ahk`：宠物技能逻辑
- `ExZhanFa.ahk`：战法逻辑
- `ExJianZong.ahk`：剑宗逻辑
- `ExAutoRun.ahk`：自动跑图逻辑
- `ExCombo.ahk`：一键连招逻辑

### `lib/`

通用库、工具函数和 GDI+ UI 支撑：

- `Keys.ahk`：键位数据
- `JSON.ahk`：JSON 库
- `Time.ahk`：时间辅助
- `GetPressKey.ahk`：按键采集辅助
- `RunWithAdministrator.ahk`：提权辅助
- `Log.ahk`：调试日志
- `GuiTheme.ahk`：GUI 主题
- `UiTheme.ahk`：底层主题参数
- `FlatButtonGdip.ahk`：GDI+ 按钮绘制
- `ToggleGdip.ahk`：GDI+ 开关绘制
- `GdipUiHelpers.ahk`：GDI+ 辅助函数
- `GdiPlusSession.ahk`：GDI+ 生命周期

### `assets/`

资源文件：

- `icons/`：程序图标与托盘图标
- `preset-recognition/`：自动识别相关资源
  - `skills/`：预设技能图标样本
  - `calibrate/`：校准图
  - `backstep/`：后跳识别图

### `docs/`

其他开发说明文档。

## 功能架构

### 1. 程序入口与启动编排

- `DNFAutoFire.ahk`：装配核心模块、GUI 模块、扩展模块
- `core/AppBootstrap.ahk`：负责启动流程、托盘、自动启动连发、退出清理
- `core/SingleInstance.ahk`：负责单实例接管

### 2. 主连发

- `core/AutoFireController.ahk`：主连发开始、停止、切换预设、切换按键状态
- `core/SessionState.ahk`：保存当前预设、启用键、热键注册状态
- `core/SendIP.ahk`：执行按键发送
- `core/GetKeycode.ahk`：负责键名、路由标识、发送标识转换
- `core/GameContext.ahk`：判断 DNF 窗口上下文
- `lib/Keys.ahk`：维护主键集合和键位数据

### 3. 自动识别与自动切换预设

- `core/PresetRecognition.ahk`：管理识别区域、截图、搜图、重试、热键触发与自动切换预设
- `gui/ex/autoPreset/AutoPresetSettings.ahk`：自动识别设置窗口
- `gui/ex/autoPreset/AutoPresetSettingsCtrl.ahk`：自动识别设置控制器
- `gui/ex/autoPreset/PresetRegionPicker.ahk`：识别区域框选
- `gui/ex/autoPreset/PresetAutoSwitch.ahk`：自动切换相关窗口
- `gui/ex/autoPreset/PresetAutoCtrl.ahk`：自动切换相关交互控制
- `gui/ex/PresetSkillIcon.ahk`：预设技能图标截取与管理
- `assets/preset-recognition/`：自动识别用图标、校准图和后跳图资源

### 4. GUI

主窗口：

- `gui/main/Main.ahk`：主窗口入口与模块接线
- `gui/main/MainWindow.ahk`：主窗口视图搭建
- `gui/main/MainController.ahk`：主窗口行为控制
- `gui/main/MainKeyGrid.ahk`：主键区交互与高亮
- `gui/main/MainPresetPanel.ahk`：预设区交互
- `gui/main/MainFeaturePanel.ahk`：扩展区交互

独立弹窗：

- `gui/dialogs/Setting.ahk`：设置窗口
- `gui/dialogs/SettingController.ahk`：设置控制器
- `gui/dialogs/QuickSwitch.ahk`：快速切换窗口
- `gui/dialogs/QuickSwitchController.ahk`：快速切换控制器

扩展窗口与主题：

- `gui/ex/ExWindowHost.ahk`：扩展窗口宿主
- `gui/ex/`：各扩展功能配置窗口
- `gui/GuiText.ahk`、`gui/MainWindowText.ahk`、`gui/ExText.ahk`：界面文案
- `lib/GuiTheme.ahk`、`lib/UiTheme.ahk`、`lib/FlatButtonGdip.ahk`、`lib/ToggleGdip.ahk`、`lib/GdipUiHelpers.ahk`、`lib/GdiPlusSession.ahk`：GDI+ UI 与主题能力

### 5. 热键分发与注册

- `core/KeyRouter.ahk`：统一注册物理键并向订阅者广播按下/抬起事件
- `core/GetKeycode.ahk`：把键名转换成可路由的标识
- `core/GameContext.ahk`：处理失焦补偿，避免丢失 `KeyUp`
- `core/AutoFireController.ahk`：主连发通过 `KeyRouter` 订阅按键事件
- `core/FeatureModuleRegistry.ahk`：统一扩展模块的启用、热键注册与注销入口

### 6. 配置管理与预设管理

- `core/Config.ahk`：负责全局设置、预设字段、默认值、排序、最近预设恢复等配置读写
- `core/PresetManager.ahk`：负责预设创建、克隆、重命名、删除、选择，以及主连发参数和扩展状态的统一加载保存
- `core/PresetExFeatures.ahk`：桥接预设与扩展开关
- `config.ini`：保存全局设置、预设、识别区域、独立键间隔和扩展参数

### 7. 扩展功能模块

- `core/FeatureModuleRegistry.ahk`：按当前预设启用对应扩展模块，并统一管理注册/注销入口
- `ex/ExLvRen.ahk`：旅人逻辑
- `ex/ExGuanYu.ahk`：关羽逻辑
- `ex/ExPetSkill.ahk`：宠物技能逻辑
- `ex/ExZhanFa.ahk`：战法逻辑
- `ex/ExJianZong.ahk`：剑宗逻辑
- `ex/ExAutoRun.ahk`：自动跑图逻辑
- `ex/ExCombo.ahk`：一键连招逻辑

## 对当前 0.30 重构的参考意义

`0.29` 最适合拿来参考的是：

- 模块边界怎么切
- 主窗口与子窗口怎么拆
- 预设、自动识别、扩展模块怎样围绕主连发组织

当前主目录在重构时，不应把 `0.29` 当成“整包直接复制”的目标，而应把它当成模块仓库。

## 注意

PowerShell 5.1 默认写文件可能破坏 UTF-8 中文。

因此修改中文文档、AHK 源码或配置文件时：

- 必须保持 UTF-8 编码
- 要警惕文件被写成 UTF-16LE 或系统代码页
- 发现乱码时先检查编码问题

DNF 对模拟输入参数较敏感。普通 VK + 扫描码输入可能同时影响游戏和聊天框。

项目在游戏窗口内对非方向使用 `vk=0xFF` 的游戏模式输入，避免聊天框误识别；在记事本调试窗口内保留普通输入方便本地验证。

