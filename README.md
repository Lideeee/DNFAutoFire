# DAF AutoFire

## 自动识别说明
- 自动识别现在只保留一条固定流程：流程按“血条 -> 城镇 -> 技能”执行；
- 血条未命中时会按重试间隔持续重试；城镇未命中时会直接停止本次自动识别；未识别到技能时会自动切换到首个配置。


## 改动功能说明
- 托盘退出、手动切换配置、自动识别切换配置现在共用同一套子进程清理流程
- 次级窗口统一改为通过 `gui/GuiRegistry.ahk` 按需创建，首次打开才建窗，减少主程序首开卡顿。
- 重复启动接管旧实例时，优先等待旧进程真实退出，拿不到进程句柄时再退回短轮询，减少开关软件时的停顿感。
- 主连发和大部分 EX 已改为“按键钩子 + one-shot 定时器”驱动，空闲时不再 `Sleep(1)` 轮询。
- 连发发送层拆成持续脉冲与一次点击两套接口；停止、切配置、失焦和退出时会统一补发释放，降低卡键概率。


## 项目结构
注：.ahk脚本为utf-8，.ini配置文件为utf-16LE


### 根目录

- [DNFAutoFire.ahk](D:/06Code/DNFAutoFire/DNFAutoFire.ahk)：主入口脚本，负责按顺序装配核心模块、GUI 模块和 EX 功能模块。
- [Version.ahk](D:/06Code/DNFAutoFire/Version.ahk)：版本号定义。
- [CHANGELOG.md](D:/06Code/DNFAutoFire/CHANGELOG.md)：历史说明与版本更新记录。
- [README.md](D:/06Code/DNFAutoFire/README.md)：项目说明文档。
- [config.ini](D:/06Code/DNFAutoFire/config.ini)：运行时配置文件。
- [DNFAutoFire.exe](D:/06Code/DNFAutoFire/DNFAutoFire.exe)：打包后的可执行文件。

### `core/` 核心逻辑

- [core/AppBootstrap.ahk](D:/06Code/DNFAutoFire/core/AppBootstrap.ahk)：应用启动收口，负责初始化、托盘、主窗口启动等流程。
- [core/AutoFireController.ahk](D:/06Code/DNFAutoFire/core/AutoFireController.ahk)：连发主控制器，管理按键启停、热键绑定、运行态切换。
- [core/AutoFire.ahk](D:/06Code/DNFAutoFire/core/AutoFire.ahk)：主连发子进程运行时，负责按下/抬起热键、节奏定时和失焦释放。
- [core/Config.ahk](D:/06Code/DNFAutoFire/core/Config.ahk)：通用配置读写。
- [core/FeatureModuleRegistry.ahk](D:/06Code/DNFAutoFire/core/FeatureModuleRegistry.ahk)：扩展功能模块注册表，统一描述 EX 功能与实现入口。
- [core/GameContext.ahk](D:/06Code/DNFAutoFire/core/GameContext.ahk)：游戏窗口上下文判断。
- [core/GetKeycode.ahk](D:/06Code/DNFAutoFire/core/GetKeycode.ahk)：按键采集、规范化、转换。
- [core/PresetExFeatures.ahk](D:/06Code/DNFAutoFire/core/PresetExFeatures.ahk)：预设与 EX 功能开关/配置关联。
- [core/PresetManager.ahk](D:/06Code/DNFAutoFire/core/PresetManager.ahk)：预设管理核心，负责创建、重命名、克隆、删除、排序和保存加载。
- [core/PresetRecognition.ahk](D:/06Code/DNFAutoFire/core/PresetRecognition.ahk)：自动识别与自动切换预设逻辑。
- [core/SendIP.ahk](D:/06Code/DNFAutoFire/core/SendIP.ahk)：输入发送与释放辅助，统一管理持续脉冲、点击和补 `Up` 回收。
- [core/SessionState.ahk](D:/06Code/DNFAutoFire/core/SessionState.ahk)：运行期状态缓存。
- [core/SingleInstance.ahk](D:/06Code/DNFAutoFire/core/SingleInstance.ahk)：单实例接管。

### `gui/` 通用 GUI 文案

- [gui/GuiText.ahk](D:/06Code/DNFAutoFire/gui/GuiText.ahk)：通用窗口、通用短标签、系统级文本。
- [gui/GuiRegistry.ahk](D:/06Code/DNFAutoFire/gui/GuiRegistry.ahk)：次级窗口注册与懒加载收口。
- [gui/MainWindowText.ahk](D:/06Code/DNFAutoFire/gui/MainWindowText.ahk)：主窗口独有文案。
- [gui/ExText.ahk](D:/06Code/DNFAutoFire/gui/ExText.ahk)：EX 功能配置窗口文案。

### `gui/main/` 主窗口

- [gui/main/Main.ahk](D:/06Code/DNFAutoFire/gui/main/Main.ahk)：主窗口入口，事件转发、菜单、全局控件表、主窗口内部模块装配。
- [gui/main/MainWindow.ahk](D:/06Code/DNFAutoFire/gui/main/MainWindow.ahk)：创建主窗口，组装布局和 builder。
- [gui/main/MainController.ahk](D:/06Code/DNFAutoFire/gui/main/MainController.ahk)：主窗口行为控制，如显示隐藏、启动连发、保存界面状态。
- [gui/main/MainKeyGrid.ahk](D:/06Code/DNFAutoFire/gui/main/MainKeyGrid.ahk)：按键区交互和按键高亮状态刷新。
- [gui/main/MainPresetPanel.ahk](D:/06Code/DNFAutoFire/gui/main/MainPresetPanel.ahk)：预设区交互，负责预设列表、右键菜单、拖拽排序、独立间隔设置。
- [gui/main/MainFeaturePanel.ahk](D:/06Code/DNFAutoFire/gui/main/MainFeaturePanel.ahk)：扩展开关区交互，负责开关绘制和 EX 入口点击。

### `gui/main/builders/` 主窗口搭建件

- [gui/main/builders/MainKeyPanelBuilder.ahk](D:/06Code/DNFAutoFire/gui/main/builders/MainKeyPanelBuilder.ahk)：搭建按键面板。
- [gui/main/builders/MainConfigPanelBuilder.ahk](D:/06Code/DNFAutoFire/gui/main/builders/MainConfigPanelBuilder.ahk)：搭建预设和配置面板。
- [gui/main/builders/MainActionButtonBuilder.ahk](D:/06Code/DNFAutoFire/gui/main/builders/MainActionButtonBuilder.ahk)：搭建主窗口操作按钮。
- [gui/main/builders/MainExFeatureBuilder.ahk](D:/06Code/DNFAutoFire/gui/main/builders/MainExFeatureBuilder.ahk)：搭建扩展功能区。

### `gui/main/layout/` 主窗口布局数据

- [gui/main/layout/MainLayout.ahk](D:/06Code/DNFAutoFire/gui/main/layout/MainLayout.ahk)：主窗口整体尺寸和坐标规则。
- [gui/main/layout/MainKeyLayoutData.ahk](D:/06Code/DNFAutoFire/gui/main/layout/MainKeyLayoutData.ahk)：按键区布局数据。
- [gui/main/layout/MainExFeatureLayoutData.ahk](D:/06Code/DNFAutoFire/gui/main/layout/MainExFeatureLayoutData.ahk)：扩展功能区布局数据。

### `gui/dialogs/` 独立弹窗

- [gui/dialogs/Setting.ahk](D:/06Code/DNFAutoFire/gui/dialogs/Setting.ahk)：设置弹窗视图。
- [gui/dialogs/SettingController.ahk](D:/06Code/DNFAutoFire/gui/dialogs/SettingController.ahk)：设置弹窗行为与保存逻辑。
- [gui/dialogs/QuickSwitch.ahk](D:/06Code/DNFAutoFire/gui/dialogs/QuickSwitch.ahk)：快速切换预设弹窗视图。
- [gui/dialogs/QuickSwitchController.ahk](D:/06Code/DNFAutoFire/gui/dialogs/QuickSwitchController.ahk)：快速切换弹窗行为。

### `gui/ex/` 扩展功能配置窗口

- [gui/ex/ExWindowHost.ahk](D:/06Code/DNFAutoFire/gui/ex/ExWindowHost.ahk)：EX 弹窗公共宿主，负责 owned window 显示隐藏。
- [gui/ex/LvRen.ahk](D:/06Code/DNFAutoFire/gui/ex/LvRen.ahk)：旅人配置窗口。
- [gui/ex/GuanYu.ahk](D:/06Code/DNFAutoFire/gui/ex/GuanYu.ahk)：关羽配置窗口。
- [gui/ex/PetSkill.ahk](D:/06Code/DNFAutoFire/gui/ex/PetSkill.ahk)：宠物技能配置窗口。
- [gui/ex/ZhanFa.ahk](D:/06Code/DNFAutoFire/gui/ex/ZhanFa.ahk)：战法配置窗口。
- [gui/ex/JianZong.ahk](D:/06Code/DNFAutoFire/gui/ex/JianZong.ahk)：剑宗配置窗口。
- [gui/ex/AutoRun.ahk](D:/06Code/DNFAutoFire/gui/ex/AutoRun.ahk)：自动跑图配置窗口。
- [gui/ex/Combo.ahk](D:/06Code/DNFAutoFire/gui/ex/Combo.ahk)：一键连招配置窗口。
- [gui/ex/autoPreset/AutoPresetSettings.ahk](D:/06Code/DNFAutoFire/gui/ex/autoPreset/AutoPresetSettings.ahk)：自动识别设置窗口，统一展示开关、帮助、当前预设识别图与识别区域设置入口。
- [gui/ex/autoPreset/AutoPresetSettingsCtrl.ahk](D:/06Code/DNFAutoFire/gui/ex/autoPreset/AutoPresetSettingsCtrl.ahk)：自动识别设置窗口行为、开关绘制和识别图预览刷新。
- [gui/ex/autoPreset/PresetAutoSwitch.ahk](D:/06Code/DNFAutoFire/gui/ex/autoPreset/PresetAutoSwitch.ahk)：识别区域设置窗口，展示技能区、血条和城镇识别区域预览与操作。
- [gui/ex/autoPreset/PresetAutoCtrl.ahk](D:/06Code/DNFAutoFire/gui/ex/autoPreset/PresetAutoCtrl.ahk)：识别区域设置窗口行为与识别区域预览刷新。
- [gui/ex/autoPreset/PresetRegionPicker.ahk](D:/06Code/DNFAutoFire/gui/ex/autoPreset/PresetRegionPicker.ahk)：截图框选与识别区域拾取。

### `ex/` 扩展功能实现

- [ex/ExLvRen.ahk](D:/06Code/DNFAutoFire/ex/ExLvRen.ahk)：旅人 EX 逻辑实现，多个触发键汇聚为一个持续输出节奏。
- [ex/ExGuanYu.ahk](D:/06Code/DNFAutoFire/ex/ExGuanYu.ahk)：关羽 EX 逻辑实现，按下边沿后挂一次性延时触发。
- [ex/ExPetSkill.ahk](D:/06Code/DNFAutoFire/ex/ExPetSkill.ahk)：宠物技能 EX 逻辑实现，纯按下边沿触发一次。
- [ex/ExZhanFa.ahk](D:/06Code/DNFAutoFire/ex/ExZhanFa.ahk)：战法 EX 逻辑实现，多个触发键汇聚为一个持续输出节奏。
- [ex/ExJianZong.ahk](D:/06Code/DNFAutoFire/ex/ExJianZong.ahk)：剑宗 EX 逻辑实现，先延时再进入持续输出。
- [ex/ExAutoRun.ahk](D:/06Code/DNFAutoFire/ex/ExAutoRun.ahk)：自动跑图逻辑实现，保留方向键特例并接入统一释放清理。
- [ex/ExCombo.ahk](D:/06Code/DNFAutoFire/ex/ExCombo.ahk)：一键连招逻辑实现，热键触发序列并支持按住循环重启。

### `lib/` 公共库与 UI 主题

- [lib/GuiTheme.ahk](D:/06Code/DNFAutoFire/lib/GuiTheme.ahk)：GUI 主题、按钮样式、开关样式、列表样式。
- [lib/UiTheme.ahk](D:/06Code/DNFAutoFire/lib/UiTheme.ahk)：底层主题参数。
- [lib/FlatButtonGdip.ahk](D:/06Code/DNFAutoFire/lib/FlatButtonGdip.ahk)：GDI+ 按钮绘制。
- [lib/ToggleGdip.ahk](D:/06Code/DNFAutoFire/lib/ToggleGdip.ahk)：GDI+ 开关绘制。
- [lib/GdipUiHelpers.ahk](D:/06Code/DNFAutoFire/lib/GdipUiHelpers.ahk)：GDI+ UI 辅助函数。
- [lib/GdiPlusSession.ahk](D:/06Code/DNFAutoFire/lib/GdiPlusSession.ahk)：GDI+ 生命周期封装。
- [lib/GetPressKey.ahk](D:/06Code/DNFAutoFire/lib/GetPressKey.ahk)：按键捕获辅助。
- [lib/Keys.ahk](D:/06Code/DNFAutoFire/lib/Keys.ahk)：按键数据与键盘布局相关工具。
- [lib/JSON.ahk](D:/06Code/DNFAutoFire/lib/JSON.ahk)：JSON 读写库。
- [lib/MultipleThread.ahk](D:/06Code/DNFAutoFire/lib/MultipleThread.ahk)：子进程启动、跟踪和清理辅助。
- [lib/Time.ahk](D:/06Code/DNFAutoFire/lib/Time.ahk)：时间辅助。
- [lib/RunWithAdministrator.ahk](D:/06Code/DNFAutoFire/lib/RunWithAdministrator.ahk)：管理员权限启动辅助。
- [lib/Log.ahk](D:/06Code/DNFAutoFire/lib/Log.ahk)：调试日志辅助。

### `assets/` 资源文件

- `assets/icons/`：程序图标与托盘状态图标。
