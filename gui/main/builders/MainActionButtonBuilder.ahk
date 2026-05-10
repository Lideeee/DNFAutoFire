#Requires AutoHotkey v2.0

class MainActionButtonBuilder {
    static Build() {
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        x := MainLayout.ButtonColumnX()
        w := MainLayout.ActionButtonWidth()
        h := MainLayout.ActionButtonHeight()
        gMainCtrls["MainSetting"] := GuiTheme_FlatTextBtn(gMainGui, "vMainSetting x" . x . " y" . MainLayout.ActionButtonYTop() . " w" . w . " h" . h, MainWindowText.SettingButton(), MainSetting)
        gMainCtrls["MainCheckUpdate"] := GuiTheme_FlatTextBtn(gMainGui, "vMainCheckUpdate x" . x . " y" . MainLayout.ActionButtonYMiddle() . " w" . w . " h" . h, MainWindowText.CheckUpdateButton(), MainCheckUpdate)
        gMainCtrls["MainStart"] := GuiTheme_FlatTextBtn(gMainGui, "vMainStart x" . x . " y" . MainLayout.ActionButtonYBottom() . " w" . w . " h" . h, MainWindowText.StartButton(), MainStart, true)
    }
}
