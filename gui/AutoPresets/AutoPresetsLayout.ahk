#Requires AutoHotkey v2.0

class AutoPresetsLayout {
    static Window() => UiContentLayout(16, 24)
    static MarginX() => 16
    static WindowWidth() => 360
    static ContentRight() => 344
    static ListWidth() => 80
    static SkillIconListGap() => 8
    static SkillIconListX() => this.MarginX() + this.ListWidth() + this.SkillIconListGap()
    static SkillIconListWidth() => this.ListWidth()
    static RightX() => 224
    static RightWidth() => 120
    static PreviewWidth() => 120
    static PreviewHeight() => 120
    static PreviewY() => this.ListY()
    static TownListWidth() => 96
    static TownPreviewGap() => 16
    static TownX() => this.MarginX() + this.TownListWidth() + this.TownPreviewGap()
    static TownPreviewWidth() => 120
    static TownPreviewHeight() => 120
    static TownListX() => this.MarginX()
    static TownListY() => this.TownY()
    static TownListHeight() => this.TownPreviewHeight()
    static RowActionY() => this.PreviewY() + this.PreviewHeight() + 12
    static EnableY() => 44
    static HotkeyY() => 78
    static PickBtnY() => this.HotkeyY() + ExLayout.ControlHeight() + 8
    static MiddleY() => this.PickBtnY() + ExLayout.ControlHeight() + 16
    static MiddleLabelY() => this.MiddleY()
    static MiddlePreviewY() => this.MiddleY() + 30
    static TownY() => this.MiddlePreviewY()
    static TownBtnY() => this.TownY() + this.TownPreviewHeight() + 12
    static LowerY() => this.TownBtnY() + ExLayout.ControlHeight() + 4
    static ListY() => this.LowerY() + 24
    static ListHeight() => 120
    static SaveY() => this.ListY() + this.ListHeight() + 48
}
