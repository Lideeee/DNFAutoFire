#Requires AutoHotkey v2.0

class MainConfigPanelBuilder {
    static Build() {
        listTop := MainLayout.ConfigListTop()
        fieldX := MainLayout.ConfigFieldX()
        fieldW := MainLayout.ConfigFieldWidth()

        gMainGui.SetFont("s10 norm c64748B", GuiTheme_Face)
        gMainGui.Add("Text", "x" . MainLayout.ConfigHelpX() . " y" . MainLayout.ConfigHelpY() . " w" . MainLayout.ConfigHelpWidth() . " h18 +0x200", MainWindowText.ConfigHelp())

        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        ; RFC: keep the native ListBox for now; revisit a custom preset list after the GUI split settles.
        MainAdd("ListBox", GuiTheme_MainCfgPresetListOpts("Preset", MainLayout.ConfigListX(), listTop, MainLayout.ConfigListWidth(), MainLayout.ConfigListHeight()))
        MainGetCtrl("Preset").OnEvent("Change", MainChangeListPreset)

        gMainGui.Add("Text", "x" . fieldX . " y" . listTop . " w" . fieldW . " h24 +0x200", MainWindowText.PresetNameLabel())
        MainAdd("Edit", "vPresetNameEdit x" . fieldX . " y" . (listTop + 24) . " w" . fieldW . " h22 +ReadOnly -E0x200 Border")

        gMainGui.Add("Text", "x" . fieldX . " y" . (listTop + 50) . " w" . fieldW . " h24 +0x200", MainWindowText.IntervalLabel())
        ctrlInterval := MainAdd("Edit", "vMainAutoFireInterval x" . fieldX . " y" . (listTop + 74) . " w" . fieldW . " h22 +Number -E0x200 Border")
        ctrlInterval.OnEvent("Change", MainSaveAutoFireInterval)
        ctrlInterval.OnEvent("LoseFocus", MainCommitAutoFireInterval)

        gMainGui.SetFont("s9 norm c334155", GuiTheme_Face)
        gMainCtrls["MainPresetSkill"] := GuiTheme_FlatTextBtn(gMainGui, "vMainPresetSkill x" . fieldX . " y" . MainLayout.PresetButtonY() . " w" . fieldW . " h" . MainLayout.PresetButtonHeight(), MainWindowText.PresetSkillButton(), MainPresetSkill)
    }
}
