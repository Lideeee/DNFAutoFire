#Requires AutoHotkey v2.0

class MainExFeatureBuilder {
    static Build() {
        gMainGui.SetFont("s10 norm c64748B", GuiTheme_Face)
        gMainGui.Add("Text", "x" . MainLayout.ExTitleX() . " y" . MainLayout.ExTitleY() . " w" . MainLayout.ExTitleWidth() . " h18 +0x200", MainWindowText.ExFeatureTitle())
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        this.AddHiddenFeatureCheckboxes()
        this.AddFeatureRows()
        MainExSwitchPaintAll()
    }

    static AddHiddenFeatureCheckboxes() {
        for name in MainExFeatureLayoutData.GetFeatureNames() {
            MainAdd("CheckBox", "v" name " Hidden x-2000 y-2000 w1 h1 -TabStop")
        }
    }

    static AddFeatureRows() {
        for column in MainExFeatureLayoutData.GetColumns(MainLayout.ExLeftColumnX(), MainLayout.ExRightColumnX()) {
            rowIndex := 0
            for row in column.rows {
                rowIndex += 1
                y := MainLayout.ExRowTop() + (rowIndex - 1) * MainLayout.ExRowHeight()
                MainAddExFeatureRow(row.name, column.x, y, MainLayout.ExToggleWidth(), column.linkWidth, row.label, row.handler)
            }
        }
    }
}
