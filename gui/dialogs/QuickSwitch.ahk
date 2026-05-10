#Requires AutoHotkey v2.0

#Include ./QuickSwitchController.ahk

global gQuickSwitchGui := Gui("-MinimizeBox -MaximizeBox -SysMenu +AlwaysOnTop -Theme +0x800000")
global gQuickSwitchCtrls := Map()

GuiTheme_Apply(gQuickSwitchGui)

gQuickSwitchGui.OnEvent("Escape", QuickSwitchGuiEscape)
gQuickSwitchGui.OnEvent("Close", QuickSwitchGuiClose)
gQuickSwitchGui.SetFont("s12 norm", GuiTheme_Face)
gQuickSwitchCtrls["QuickSwitchList"] := GuiTheme_AddListBox(gQuickSwitchGui, "QuickSwitchList", 12, 12, 244, 132)
gQuickSwitchCtrls["QuickSwitchList"].OnEvent("DoubleClick", QuickSwitchChangeList)
gQuickSwitchGui.SetFont("s10 norm c334155", GuiTheme_Face)
gQuickSwitchGui.Add("Text", "x12 y152 w244 h44", GuiText.QuickSwitchHelp())
GuiTheme_FlatBtn(gQuickSwitchGui, "x12 y204 w118 h38", GuiText.QuickSwitchStart(), QuickSwitchStart, true)
GuiTheme_FlatBtn(gQuickSwitchGui, "x138 y204 w118 h38", GuiText.QuickSwitchStop(), QuickSwitchStop, false)

QuickSwitchGetCtrl(name) {
    global gQuickSwitchCtrls
    return gQuickSwitchCtrls.Has(name) ? gQuickSwitchCtrls[name] : ""
}

QuickSwitchGuiEscape(*) => QuickSwitchController.Hide()
QuickSwitchGuiClose(*) => QuickSwitchController.Hide()
QuickSwitchStart(*) => QuickSwitchController.Start()
QuickSwitchStop(*) => QuickSwitchController.Stop()
ShowGuiQuickSwitch(*) => QuickSwitchController.Show()
HideGuiQuickSwitch() => QuickSwitchController.Hide()
QuickSwitchOnSpacePress(wParam, lParam, msg, hwnd) => QuickSwitchController.OnSpacePress(wParam, lParam, msg, hwnd)
QuickSwitchChangeList(*) => QuickSwitchController.ChangeList()
