#Requires AutoHotkey v2.0

class ExLayout {
    static MarginLeft() => 16
    static MarginTop() => 16
    static MarginRight() => 16
    static MarginBottom() => 16
    static HelpButtonSize() => 22
    static TitleY() => this.MarginTop()
    static TitleHeight() => 22
    static HelpButtonY() => 12

    static Window() => UiContentLayout(16, 16)

    static ContentRight(contentWidth) => this.MarginLeft() + contentWidth

    static TitleTextWidth(contentRight) => contentRight - this.MarginLeft() - this.HelpButtonSize() - 8
}
