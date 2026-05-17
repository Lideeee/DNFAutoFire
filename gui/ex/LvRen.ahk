#Requires AutoHotkey v2.0

global gLvRenGui := Gui("-MinimizeBox -MaximizeBox")
global gLvRenCtrls := Map()
global __LvRenSkillKeys := []
global gLvRenLayout := ExLayout.Window()

UiApplyWindow(gLvRenGui)
gLvRenGui.OnEvent("Escape", LvRenGuiEscape)
gLvRenGui.OnEvent("Close", LvRenGuiClose)

UiSkillKeyEditor(gLvRenGui, gLvRenCtrls, "LvRen", exText["LvRenListTitle"], exText["LvRenShotTitle"], exText["LvRenAdd"], exText["LvRenDelete"], exText["SetShotKey"], LvRenAddKey, LvRenDeleteKey, LvRenSetShotKey, LvRenSave, LvRenHelp, exText["CommonSave"], exText["LvRenPageTitle"], "", "", 0, gLvRenLayout)
UiListBoxDragSort_Attach(gLvRenCtrls["LvRenKeysListBox"], LvRenDragGetItems, UiListBoxDragSort_RenderStrings, LvRenDragCommit)

LvRenGetCtrl(name) {
    global gLvRenCtrls
    return gLvRenCtrls.Has(name) ? gLvRenCtrls[name] : ""
}

ShowGuiLvRen(*) {
    global gMainGui, gLvRenGui, gLvRenLayout
    if IsObject(gMainGui) {
        gLvRenGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gLvRenGui.Title := exText["LvRenTitle"]
    gLvRenGui.Show("w" gLvRenLayout.Width() " h" gLvRenLayout.Height())
    LvRenLoadConfig()
    DisableGuiMain()
}

HideGuiLvRen() {
    gLvRenGui.Hide()
    EnableGuiMain()
}

LvRenGuiEscape(*) {
    LvRenSave()
}

LvRenGuiClose(*) {
    LvRenSave()
}

LvRenHelp(*) {
    UiHelpMsgBox(exText["LvRenHelp"], exText["LvRenHelpTitle"])
}

LvRenAddKey(*) {
    global __LvRenSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __LvRenSkillKeys) {
        MsgBox(exText["DuplicateKey"],, "Icon!")
    } else {
        __LvRenSkillKeys.Push(key)
    }
    LvRenChangeListGui(__LvRenSkillKeys)
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
    for i, item in __LvRenSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

LvRenDeleteKey(*) {
    global __LvRenSkillKeys
    DeleteValueInArray(LvRenGetCtrl("LvRenKeysListBox").Text, __LvRenSkillKeys)
    LvRenChangeListGui(__LvRenSkillKeys)
}

LvRenSave(*) {
    LvRenSaveConfig()
    HideGuiLvRen()
}

LvRenSetShotKey(*) {
    LvRenGetCtrl("LvRenShotKey").Text := GetPressKey()
}

LvRenChangeListGui(keys) {
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
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

LvRenDragGetItems(*) {
    global __LvRenSkillKeys
    return UiListBoxDragSort_CopyArray(__LvRenSkillKeys)
}

LvRenDragCommit(items, selectedIndex) {
    global __LvRenSkillKeys
    __LvRenSkillKeys := items
    LvRenChangeListGui(__LvRenSkillKeys)
    if (selectedIndex > 0 && selectedIndex <= __LvRenSkillKeys.Length) {
        try LvRenGetCtrl("LvRenKeysListBox").Choose(selectedIndex)
    }
}

LvRenSaveConfig() {
    global __LvRenSkillKeys
    keysString := ""
    for i, v in __LvRenSkillKeys {
        keysString .= v "|"
    }
    keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    SavePreset(GetNowSelectPreset(), "LvRenSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "LvRenShotKey", LvRenGetCtrl("LvRenShotKey").Text)
}

LvRenLoadConfig() {
    global __LvRenSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "LvRenShotKey", "Z")
    __LvRenSkillKeys := LvRenLoadKeys(GetNowSelectPreset())
    LvRenChangeListGui(__LvRenSkillKeys)
    LvRenGetCtrl("LvRenShotKey").Text := shotKey
}
