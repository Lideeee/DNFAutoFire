#Requires AutoHotkey v2.0

global gQuickSwitchGui := Gui("-MinimizeBox -MaximizeBox -SysMenu +AlwaysOnTop +0x800000")
global gQuickSwitchCtrls := Map()
global gQuickSwitchLayout := QuickSwitchLayout.Window()

UiApplyWindow(gQuickSwitchGui)
gQuickSwitchGui.OnEvent("Escape", QuickSwitchGuiEscape)
gQuickSwitchGui.OnEvent("Close", QuickSwitchGuiClose)
gQuickSwitchCtrls["QuickSwitchList"] := gQuickSwitchGui.Add("ListBox", UiLayoutRect(gQuickSwitchLayout, 12, 12, 244, 132, "vQuickSwitchList"))
gQuickSwitchCtrls["QuickSwitchList"].OnEvent("DoubleClick", QuickSwitchChangeList)
gQuickSwitchGui.Add("Text", UiLayoutRect(gQuickSwitchLayout, 12, 152, 244, 44), MainText["QuickSwitchHint"])
gQuickSwitchGui.Add("Button", UiLayoutRect(gQuickSwitchLayout, 12, 204, 118, 38), MainText["QuickSwitchStart"]).OnEvent("Click", QuickSwitchStart)
gQuickSwitchGui.Add("Button", UiLayoutRect(gQuickSwitchLayout, 138, 204, 118, 38), MainText["QuickSwitchStop"]).OnEvent("Click", QuickSwitchStop)

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
    HideGuiQuickSwitch()
    StopAutoFire()
    EnterRunningMode(presetName)
}

QuickSwitchStop(*) {
    HideGuiQuickSwitch()
    SwitchToStoppedState()
    gMainGui.Show("w" MainLayout.GuiWidth() " h" MainLayout.GuiHeight())
    SetTimer(MainMutedLinkPoll, 100)
}

ShowGuiQuickSwitch(*) {
    global gQuickSwitchGui, gQuickSwitchLayout
    HideGuiMain()
    gQuickSwitchGui.Title := MainText["QuickSwitchTitle"]
    gQuickSwitchGui.Show("w" gQuickSwitchLayout.Width() " h" gQuickSwitchLayout.Height())
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
