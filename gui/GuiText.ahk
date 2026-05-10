#Requires AutoHotkey v2.0

class GuiText {
    static TrayMainSettings() {
        return "连发设置"
    }

    static TrayAppSettings() {
        return "软件设置"
    }

    static TrayExit() {
        return "退出程序"
    }

    static AppIconTip() {
        return "DAF连发工具"
    }

    static InvalidMainKey() {
        return "仅支持主连发键盘上的按键。"
    }

    static SettingTitle() {
        return "软件设置"
    }

    static SettingNavGeneral() {
        return "常规设置"
    }

    static SettingNavAbout() {
        return "关于"
    }

    static SettingAutoStart() {
        return "软件打开后自动启动连发"
    }

    static SettingOnSystemStart() {
        return "开机后自动启动"
    }

    static SettingBlockWin() {
        return "游戏内屏蔽Win键"
    }

    static SettingQuickSwitchLabel() {
        return "快速切换热键"
    }

    static SettingAutoPresetSwitch() {
        return "自动识别"
    }

    static SettingAutoPresetButton() {
        return "识别区域设置"
    }

    static SettingAutoPresetHelp() {
        return "1. 未识别到自动切换到首个配置`n2. 游戏窗口位置、大小、分辨率变化，都需要重新截取识别图像。（或调整回原来的窗口大小和位置）"
    }

    static AutoPresetSettingsTitle() {
        return "自动识别"
    }

    static AutoPresetPresetListLabel() {
        return "配置列表"
    }

    static AutoPresetSelectedPresetLabel() {
        return "当前识别配置："
    }

    static SaveButton() {
        return "保存"
    }

    static AboutApp() {
        return "作者：某亚瑟`n图标：Ousumu"
    }

    static AboutOriginalPost() {
        return "原帖地址："
    }

    static AboutReleasePost() {
        return "二次开发："
    }

    static QuickSwitchTitle() {
        return "快速切换预设"
    }

    static QuickSwitchHelp() {
        return "双击或按空格切换到选中的预设，按 Esc 关闭窗口。"
    }

    static QuickSwitchStart() {
        return "切换并启动"
    }

    static QuickSwitchStop() {
        return "停止连发"
    }

    static PresetAutoTitle() {
        return "识别区域设置"
    }

    static PresetAutoHotkeyLabel() {
        return "自动切换触发热键"
    }

    static PresetAutoPickSkillRegion() {
        return "选择技能识别区域"
    }

    static PresetAutoPickCalibrateRegion() {
        return "选择血条识别区域"
    }

    static PresetAutoUpdateCalibrate() {
        return "更新血条识别图像"
    }

    static PresetAutoDeleteCalibrate() {
        return "删除血条识别图像"
    }

    static PresetAutoPreviewHint() {
        return "框选后按 Enter 确认，按 Esc 取消。"
    }

    static HelpButton() {
        return "?"
    }

}
