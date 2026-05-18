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
    static TownX() => 76
    static TownPreviewWidth() => 120
    static TownPreviewHeight() => 120
    static RowActionY() => this.PreviewY() + this.PreviewHeight() + 12
    static EnableY() => 44
    static HotkeyY() => 78
    static MiddleY() => 126
    static MiddleLabelY() => this.MiddleY()
    static MiddlePreviewY() => this.MiddleY() + 30
    static PickBtnY() => this.MiddlePreviewY() + this.TownPreviewHeight() + 14
    static TownBtnY() => this.PickBtnY() + 36
    static LowerY() => this.TownBtnY() + 52
    static ListY() => this.LowerY() + 24
    static ListHeight() => 120
    static TownY() => this.MiddlePreviewY()
    static SaveY() => this.ListY() + this.ListHeight() + 48
}
