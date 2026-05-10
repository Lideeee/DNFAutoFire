#Requires AutoHotkey v2.0

#Include ./layout/MainLayout.ahk
#Include ./MainKeyGrid.ahk
#Include ./MainFeaturePanel.ahk
#Include ./MainPresetPanel.ahk
#Include ./MainWindow.ahk
#Include ./MainController.ahk

global gPresetContextMenu := Menu()
global gPresetBlankContextMenu := Menu()
global gPresetDragStartIndex := 0
global gPresetDragHoverIndex := 0
global gPresetDragDown := false
global gPresetDragPreviewing := false
global gPresetSuppressChange := false
global gPresetDragPreviewList := []
global gPresetDragCurrentFromIndex := 0
global gPresetDragItemName := ""
global gKeyIntervalMenu := Menu()
global gKeyIntervalMenuTarget := ""
global gMainMutedLinks := []
global gMainKeyCaps := Map()
global __QuickSwitchHotkey := ""

MainAdd(ctrlType, options, text := "") {
    global gMainGui, gMainCtrls
    ; v2: list-like controls need an array for empty initial items.
    if (ctrlType = "ListBox" || ctrlType = "DropDownList" || ctrlType = "ComboBox") && (text = "") {
        ctrl := gMainGui.Add(ctrlType, options, [])
    } else {
        if (ctrlType = "Hotkey" && text = "") {
            ctrl := gMainGui.Add(ctrlType, options)
        } else {
            ctrl := gMainGui.Add(ctrlType, options, text)
        }
    }
    if (ctrl.Name != "") {
        gMainCtrls[ctrl.Name] := ctrl
    }
    if (ctrlType = "ListBox") {
        try GuiTheme_RegisterListBoxWheel(ctrl)
    }
    return ctrl
}

MainGetCtrl(name) {
    global gMainCtrls
    return gMainCtrls.Has(name) ? gMainCtrls[name] : ""
}

MainWindow.EnsureBuilt()

gPresetContextMenu.Add(MainWindowText.MenuNewPreset(), MainCreatePreset)
gPresetContextMenu.Add(MainWindowText.MenuRenamePreset(), MainRenamePreset)
gPresetContextMenu.Add(MainWindowText.MenuClonePreset(), MainClonePreset)
gPresetContextMenu.Add(MainWindowText.MenuDeletePreset(), MainDeletePreset)
gPresetBlankContextMenu.Add(MainWindowText.MenuNewPreset(), MainCreatePreset)

gKeyIntervalMenu.Add(MainWindowText.MenuEditKeyInterval(), MainKeyIntervalMenuEdit)
gKeyIntervalMenu.Add(MainWindowText.MenuClearKeyInterval(), MainKeyIntervalMenuClear)

AutoFireController.RegisterMainSetKeyState(MainSetKeyState)

ShowGuiMain(*) => MainController.Show()
HideGuiMain(*) => MainController.Hide()
MainGuiEscape(*) => MainController.Hide()
MainGuiClose(*) => MainController.Hide()
DisableGuiMain() => MainController.Disable()
EnableGuiMain() => MainController.Enable()
MainStart(*) => MainController.Start()
MainClear(*) => MainController.Clear()
MainSetting(*) => MainController.OpenSetting()
MainOpenSettingAbout(*) => MainController.OpenSettingAbout()
MainAutoPreset(*) => MainController.OpenAutoPreset()
MainSaveEx() => MainController.SaveMainViewState()
MainLoadEx() => MainController.LoadMainViewState()
MainNormalizeAutoFireInterval() => MainController.NormalizeAutoFireInterval()
MainSaveAutoFireInterval(*) => MainController.SaveAutoFireInterval()
MainCommitAutoFireInterval(*) => MainController.CommitAutoFireInterval()
MainNormalizeAutoFirePressDuration() => MainController.NormalizeAutoFirePressDuration()
MainSaveAutoFirePressDuration(*) => MainController.SaveAutoFirePressDuration()
MainCommitAutoFirePressDuration(*) => MainController.CommitAutoFirePressDuration()
MainSaveExToggle(*) => MainController.SaveExToggle()
MainPruneObsoleteKeyIntervals(presetName) => MainController.PruneObsoleteKeyIntervals(presetName)
MainSaveCurrentPreset() => MainController.SaveCurrentPreset()
QuickChangeHotKey_RegisterOnly(keyWithoutTildeDollar) => MainController.RegisterQuickSwitchOnly(keyWithoutTildeDollar)
QuickChangeHotKey_PersistAndRegister(newKey) => MainController.PersistAndRegisterQuickSwitch(newKey)
QuickChangeHotKey_SyncFromConfig() => MainController.SyncQuickSwitchFromConfig()
