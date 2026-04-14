#Requires AutoHotkey v2.0

global gQuickSwitchGui := Gui("-MinimizeBox -MaximizeBox -SysMenu +AlwaysOnTop -Theme +0x800000")
global gQuickSwitchCtrls := Map()

gQuickSwitchGui.OnEvent("Escape", QuickSwitchGuiEscape)
gQuickSwitchGui.OnEvent("Close", QuickSwitchGuiClose)
gQuickSwitchGui.SetFont("s18", "微软雅黑")
gQuickSwitchCtrls["QuickSwitchList"] := gQuickSwitchGui.Add("ListBox", "vQuickSwitchList x8 y8 w240 h292")
gQuickSwitchCtrls["QuickSwitchList"].OnEvent("DoubleClick", QuickSwitchChangeList)
gQuickSwitchGui.SetFont()
gQuickSwitchGui.Add("Button", "x8 y330 w100 h36 +Default", "切换并启动连发").OnEvent("Click", QuickSwitchStart)
gQuickSwitchGui.Add("Button", "x150 y330 w100 h36", "停止连发").OnEvent("Click", QuickSwitchStop)
gQuickSwitchGui.Add("Text", "x8 y300 w240 h30", "使用键盘上下键选择配置，按空格或回车快速切换，按ESC关闭窗口")

QuickSwitchGetCtrl(name) {
    global gQuickSwitchCtrls
    return gQuickSwitchCtrls.Has(name) ? gQuickSwitchCtrls[name] : ""
}

QuickSwitchGuiEscape(*) {
    HideGuiQuickSwitch()
}

QuickSwitchGuiClose(*) {
    HideGuiQuickSwitch()
}

QuickSwitchStart(*) {
    presetName := QuickSwitchGetCtrl("QuickSwitchList").Text
    ChangePreset(presetName)
    StartAutoFire()
    HideGuiQuickSwitch()
}

QuickSwitchStop(*) {
    StopAutoFire()
    HideGuiQuickSwitch()
}

ShowGuiQuickSwitch(*) {
    HideGuiMain()
    gQuickSwitchGui.Title := "快速切换"
    gQuickSwitchGui.Show("w256 h370")
    nowSelectPreset := GetNowSelectPreset()
    presetList := LoadAllPresetString()
    ctrl := QuickSwitchGetCtrl("QuickSwitchList")
    ctrl.Delete()
    idx := 0
    cnt := 0
    for i, item in StrSplit(presetList, "|") {
        if (item != "") {
            ctrl.Add([item])
            cnt++
            if (item = nowSelectPreset) {
                idx := cnt
            }
        }
    }
    if (idx > 0) {
        ctrl.Choose(idx)
    } else if (cnt > 0) {
        ctrl.Choose(1)
    }
    ctrl.Focus()
    OnMessage(0x0100, QuickSwitchOnSpacePress)
}

HideGuiQuickSwitch() {
    gQuickSwitchGui.Hide()
    OnMessage(0x0100, QuickSwitchOnSpacePress, 0)
}

QuickSwitchOnSpacePress(wParam, lParam, msg, hwnd) {
    global gQuickSwitchGui
    if (!IsObject(gQuickSwitchGui) || !WinExist("ahk_id " gQuickSwitchGui.Hwnd) || !WinActive("ahk_id " gQuickSwitchGui.Hwnd)) {
        return
    }
    key := GetKeyName(Format("vk{1:02X}", wParam))
    if (key = "Space" || key = "Enter") {
        QuickSwitchStart()
    }
}

QuickSwitchChangeList(*) {
    QuickSwitchStart()
}
