#Requires AutoHotkey v2.0

global gPetSkillGui := Gui("-MinimizeBox -MaximizeBox")
global gPetSkillCtrls := Map()
global __PetSkillSkillKeys := []
global gPetSkillLayout := ExLayout.Window()

UiApplyWindow(gPetSkillGui)
gPetSkillGui.OnEvent("Escape", PetSkillGuiEscape)
gPetSkillGui.OnEvent("Close", PetSkillGuiClose)

UiSkillKeyEditor(gPetSkillGui, gPetSkillCtrls, "PetSkill", exText["PetSkillListTitle"], exText["PetSkillShotTitle"], exText["PetSkillAdd"], exText["PetSkillDelete"], exText["PetSkillSet"], PetSkillAddKey, PetSkillDeleteKey, PetSkillSetShotKey, PetSkillSave, PetSkillHelp, exText["CommonSave"], exText["PetSkillPageTitle"], "", "", 0, gPetSkillLayout, PetSkillSaveToAll, exText["CommonSaveToAll"])
UiListBoxDragSort_Attach(gPetSkillCtrls["PetSkillKeysListBox"], PetSkillDragGetItems, UiListBoxDragSort_RenderStrings, PetSkillDragCommit)

PetSkillGetCtrl(name) {
    global gPetSkillCtrls
    return gPetSkillCtrls.Has(name) ? gPetSkillCtrls[name] : ""
}

ShowGuiPetSkill(*) {
    global gMainGui, gPetSkillGui, gPetSkillLayout
    if IsObject(gMainGui) {
        gPetSkillGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPetSkillGui.Title := exText["PetSkillTitle"]
    gPetSkillGui.Show("w" gPetSkillLayout.Width() " h" gPetSkillLayout.Height())
    PetSkillLoadConfig()
    DisableGuiMain()
}

HideGuiPetSkill() {
    gPetSkillGui.Hide()
    EnableGuiMain()
}

PetSkillGuiEscape(*) {
    PetSkillSave()
}

PetSkillGuiClose(*) {
    PetSkillSave()
}

PetSkillHelp(*) {
    UiHelpMsgBox(exText["PetSkillHelp"], exText["PetSkillHelpTitle"])
}

PetSkillAddKey(*) {
    global __PetSkillSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __PetSkillSkillKeys) {
        MsgBox(exText["DuplicateKey"],, "Icon!")
    } else {
        __PetSkillSkillKeys.Push(key)
    }
    PetSkillChangeListGui(__PetSkillSkillKeys)
    ctrl := PetSkillGetCtrl("PetSkillKeysListBox")
    for i, item in __PetSkillSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

PetSkillDeleteKey(*) {
    global __PetSkillSkillKeys
    DeleteValueInArray(PetSkillGetCtrl("PetSkillKeysListBox").Text, __PetSkillSkillKeys)
    PetSkillChangeListGui(__PetSkillSkillKeys)
}

PetSkillSave(*) {
    PetSkillSaveConfig(GetNowSelectPreset())
    HideGuiPetSkill()
}

PetSkillSaveToAll(*) {
    for presetName in LoadAllPreset() {
        PetSkillSaveConfig(presetName)
    }
    HideGuiPetSkill()
}

PetSkillSetShotKey(*) {
    PetSkillGetCtrl("PetSkillShotKey").Text := GetPressKey()
}

PetSkillChangeListGui(keys) {
    ctrl := PetSkillGetCtrl("PetSkillKeysListBox")
    ctrl.Delete()
    cnt := 0
    for key in keys {
        if (key != "") {
            ctrl.Add([key])
            cnt++
        }
    }
    if (cnt > 0) {
        ctrl.Choose(1)
    }
}

PetSkillDragGetItems(*) {
    global __PetSkillSkillKeys
    return UiListBoxDragSort_CopyArray(__PetSkillSkillKeys)
}

PetSkillDragCommit(items, selectedIndex) {
    global __PetSkillSkillKeys
    __PetSkillSkillKeys := items
    PetSkillChangeListGui(__PetSkillSkillKeys)
    if (selectedIndex > 0 && selectedIndex <= __PetSkillSkillKeys.Length) {
        try PetSkillGetCtrl("PetSkillKeysListBox").Choose(selectedIndex)
    }
}

PetSkillSaveConfig(presetName) {
    global __PetSkillSkillKeys
    keysString := ""
    for i, v in __PetSkillSkillKeys {
        keysString .= v "|"
    }
    keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    SavePreset(presetName, "PetSkillSkillKeys", keysString)
    SavePreset(presetName, "PetSkillShotKey", PetSkillGetCtrl("PetSkillShotKey").Text)
}

PetSkillLoadConfig() {
    global __PetSkillSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "PetSkillShotKey", "Z")
    __PetSkillSkillKeys := PetSkillLoadKeys(GetNowSelectPreset())
    PetSkillChangeListGui(__PetSkillSkillKeys)
    PetSkillGetCtrl("PetSkillShotKey").Text := shotKey
}
