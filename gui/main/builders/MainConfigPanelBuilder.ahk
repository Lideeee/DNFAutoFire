#Requires AutoHotkey v2.0

class MainConfigPanelBuilder {
    static Build() {
        global gMainGui, gMainCtrls
        listTop := MainLayout.ConfigListTop()
        fieldX := MainLayout.ConfigFieldX()
        fieldW := MainLayout.ConfigFieldWidth()
        labelH := MainLayout.ConfigFieldLabelHeight()
        editH := MainLayout.ConfigFieldEditHeight()

        gMainGui.SetFont("s10 norm c64748B", GuiTheme_Face)
        gMainGui.Add("Text", "x" . MainLayout.ConfigHelpX() . " y" . MainLayout.ConfigHelpY() . " w" . MainLayout.ConfigHelpWidth() . " h18 +0x200", MainWindowText.ConfigHelp())

        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        ; RFC: keep the native ListBox for now; revisit a custom preset list after the GUI split settles.
        presetCtrl := GuiTheme_AddListBox(gMainGui, "Preset", MainLayout.ConfigListX(), listTop, MainLayout.ConfigListWidth(), MainLayout.ConfigListHeight())
        gMainCtrls[presetCtrl.Name] := presetCtrl
        presetCtrl.OnEvent("Change", MainChangeListPreset)

        gMainGui.Add("Text", "x" . fieldX . " y" . MainLayout.ConfigFieldLabelY(1) . " w" . fieldW . " h" . labelH . " +0x200", MainWindowText.PresetNameLabel())
        MainAdd("Edit", "vPresetNameEdit x" . fieldX . " y" . MainLayout.ConfigFieldEditY(1) . " w" . fieldW . " h" . editH . " +ReadOnly -E0x200 Border")

        gMainGui.Add("Text", "x" . fieldX . " y" . MainLayout.ConfigFieldLabelY(2) . " w" . fieldW . " h" . labelH . " +0x200", MainWindowText.IntervalLabel())
        ctrlInterval := MainAdd("Edit", "vMainAutoFireInterval x" . fieldX . " y" . MainLayout.ConfigFieldEditY(2) . " w" . fieldW . " h" . editH . " +Number -E0x200 Border")
        ctrlInterval.OnEvent("Change", MainSaveAutoFireInterval)
        ctrlInterval.OnEvent("LoseFocus", MainCommitAutoFireInterval)

        gMainGui.Add("Text", "x" . fieldX . " y" . MainLayout.ConfigFieldLabelY(3) . " w" . fieldW . " h" . labelH . " +0x200", MainWindowText.PressDurationLabel())
        ctrlPressDuration := MainAdd("Edit", "vMainAutoFirePressDuration x" . fieldX . " y" . MainLayout.ConfigFieldEditY(3) . " w" . fieldW . " h" . editH . " +Number -E0x200 Border")
        ctrlPressDuration.OnEvent("Change", MainSaveAutoFirePressDuration)
        ctrlPressDuration.OnEvent("LoseFocus", MainCommitAutoFirePressDuration)

    }
}
