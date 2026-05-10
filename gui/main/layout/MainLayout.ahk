#Requires AutoHotkey v2.0

#Include ./MainKeyLayoutData.ahk

class MainLayout {
    static StandardMargin() => 16
    static GuiWidth() => MainKeyLayoutData.KeyboardWidth() + 32
    static GuiHeight() => this.BottomY() + 216
    static GuiHeightRunning() => this.GuiHeight() + 8
    static ButtonColumnX() => this.GuiWidth() - this.StandardMargin() - this.ButtonColumnWidth()
    static ButtonColumnWidth() => 96
    static ButtonColumnRightPadding() => this.StandardMargin()
    static KeyPanelHeight() => MainKeyLayoutData.KeyboardHeight() + 22
    static BottomY() => 8 + this.KeyPanelHeight() + 12

    static ConfigHelpX() => 16
    static ConfigHelpY() => this.BottomY() + 6
    static ConfigHelpWidth() => 324
    static ConfigListTop() => this.BottomY() + 26
    static ConfigSectionBottom() => this.GuiHeight() - this.StandardMargin()
    static ConfigListHeight() => this.ConfigSectionBottom() - this.ConfigListTop()
    static ConfigListBottom() => this.ConfigSectionBottom()
    static ConfigListX() => 16
    static ConfigListWidth() => 150
    static ConfigFieldX() => 174
    static ConfigFieldWidth() => 124
    static PresetButtonHeight() => 36
    static PresetButtonY() => this.ConfigListBottom() - this.PresetButtonHeight()

    static ActionButtonWidth() => this.ButtonColumnWidth()
    static ActionButtonHeight() => 60
    static ActionButtonYTop() => this.BottomY() + 5
    static ActionButtonYMiddle() => this.BottomY() + 72
    static ActionButtonYBottom() => this.GuiHeight() - this.StandardMargin() - this.ActionButtonHeight()

    static ExTitleX() => 334
    static ExTitleY() => this.BottomY() + 6
    static ExTitleWidth() => 200
    static ExRowTop() => this.BottomY() + 26
    static ExRowHeight() => 36
    static ExLeftColumnX() => 334
    static ExRightColumnX() => 502
    static ExToggleWidth() => 40
}
