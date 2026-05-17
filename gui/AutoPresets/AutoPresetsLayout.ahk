#Requires AutoHotkey v2.0

class AutoPresetsLayout {
    static Window() => UiContentLayout(16, 24)
    static MarginX() => 16
    static WindowWidth() => 360
    static ContentRight() => 344
    static ListWidth() => 120
    static RightX() => 224
    static RightWidth() => 120
    static PreviewWidth() => 120
    static PreviewHeight() => 120
    static PreviewY() => 434
    static CalX() => 76
    static CalPreviewWidth() => 120
    static CalPreviewHeight() => 120
    static TownWidth() => 72
    static RowActionY() => this.PreviewY() + this.PreviewHeight() + 12
    static EnableY() => 44
    static HotkeyY() => 78
    static MiddleY() => 126
    static MiddleLabelY() => this.MiddleY()
    static MiddlePreviewY() => this.MiddleY() + 30
    static PickBtnY() => this.MiddlePreviewY() + this.CalPreviewHeight() + 14
    static CalBtnY() => this.PickBtnY() + 36
    static TownBtnY() => this.CalBtnY() + 32
    static LowerY() => this.TownBtnY() + 52
    static ListY() => this.LowerY() + 24
    static ListHeight() => 120
    static CalY() => this.MiddlePreviewY()
    static CalTownX() => this.CalX() + this.CalPreviewWidth() + 16
    static SaveY() => this.ListY() + this.ListHeight() + 48
}
