#Requires AutoHotkey v2.0

class MainKeyPanelBuilder {
    static Build() {
        gMainGui.SetFont("s10 c" GuiTheme_Hint, GuiTheme_Face)
        gMainGui.Add("Text", "x16 y16 w" MainKeyLayoutData.KeyboardWidth() " h14 +0x200", MainWindowText.KeyHelp())

        for item in MainKeyLayoutData.GetRows() {
            name := item[1], pos := item[2], label := item.Length >= 3 ? item[3] : name
            fontSize := GuiTheme_MainKeyLabelFontSize(name)
            if MainKeyUiGrayOnly(name) {
                gMainGui.SetFont(fontSize, GuiTheme_Face)
                ctrl := MainAdd("Text", "v" name " " pos . GuiTheme_MainKeyCellSuffix(true), label)
            } else {
                gMainGui.SetFont(fontSize " c" GuiTheme_KeyOff, GuiTheme_Face)
                ctrl := MainAdd("Text", "v" name " " pos . GuiTheme_MainKeyCellSuffix(false), label)
                ctrl.OnEvent("Click", MainKeyClick)
            }
        }

        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        gMainGui.Add("Text", MainKeyLayoutData.WinRect() . GuiTheme_MainKeyCellSuffix(true), "Win")

        versionX := MainKeyLayoutData.TopRowVersionX()
        versionY := MainKeyLayoutData.TopRowVersionY()
        versionW := MainKeyLayoutData.VersionWidth()
        versionH := MainKeyLayoutData.TopRowVersionHeight()
        lineH := 12
        lineGap := 2
        textBlockH := lineH * 2 + lineGap
        line1Y := versionY + Floor((versionH - textBlockH) / 2)
        line2Y := line1Y + lineH + lineGap
        gMainGui.SetFont("s8", GuiTheme_Face)
        MainAdd("Text", "vMainVersionTextLine1 x" versionX " y" line1Y " w" versionW " h" lineH " +Center +0x200", MainWindowText.VersionLine1(__Version))
        MainAdd("Text", "vMainVersionTextLine2 x" versionX " y" line2Y " w" versionW " h" lineH " +Center +0x200", MainWindowText.VersionLine2())
        gMainCtrls["MainClear"] := GuiTheme_FlatTextBtn(gMainGui, "vMainClear x" MainKeyLayoutData.TopRowClearX() " y" MainKeyLayoutData.TopRowY() " w" MainKeyLayoutData.KeyWidth(1) " h" MainKeyLayoutData.Height(), MainWindowText.ClearButton(), MainClear)
    }
}
