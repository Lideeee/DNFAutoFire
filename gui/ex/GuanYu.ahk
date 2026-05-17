#Requires AutoHotkey v2.0

global gGuanYuGui := Gui("-MinimizeBox -MaximizeBox")
global gGuanYuCtrls := Map()
global __GuanYuSkillKeys := []
global gGuanYuLayout := ExLayout.Window()

UiApplyWindow(gGuanYuGui)
gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

UiSkillKeyEditor(gGuanYuGui, gGuanYuCtrls, "GuanYu", exText["GuanYuListTitle"], exText["GuanYuShotTitle"], exText["GuanYuAdd"], exText["GuanYuDelete"], exText["SetShotKey"], GuanYuAddKey, GuanYuDeleteKey, GuanYuSetShotKey, GuanYuSave, GuanYuHelp, exText["CommonSave"], exText["GuanYuPageTitle"], exText["GuanYuDelayTitle"], "", 0, gGuanYuLayout)
UiListBoxDragSort_Attach(gGuanYuCtrls["GuanYuKeysListBox"], GuanYuDragGetItems, UiListBoxDragSort_RenderStrings, GuanYuDragCommit)

GuanYuGetCtrl(name) {
    global gGuanYuCtrls
    return gGuanYuCtrls.Has(name) ? gGuanYuCtrls[name] : ""
}

ShowGuiGuanYu(*) {
    global gMainGui, gGuanYuGui, gGuanYuLayout
    if IsObject(gMainGui) {
        gGuanYuGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gGuanYuGui.Title := exText["GuanYuTitle"]
    gGuanYuGui.Show("w" gGuanYuLayout.Width() " h" gGuanYuLayout.Height())
    GuanYuLoadConfig()
    DisableGuiMain()
}

HideGuiGuanYu() {
    gGuanYuGui.Hide()
    EnableGuiMain()
}

GuanYuGuiEscape(*) {
    GuanYuSave()
}

GuanYuGuiClose(*) {
    GuanYuSave()
}

GuanYuHelp(*) {
    UiHelpMsgBox(exText["GuanYuHelp"], exText["GuanYuHelpTitle"])
}

GuanYuAddKey(*) {
    global __GuanYuSkillKeys
    key := GetPressKey()
    if IsValueInArray(key, __GuanYuSkillKeys) {
        MsgBox(exText["DuplicateKey"],, "Icon!")
    } else {
        __GuanYuSkillKeys.Push(key)
    }
    GuanYuChangeListGui(__GuanYuSkillKeys)
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
    for i, item in __GuanYuSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
            break
        }
    }
}

GuanYuDeleteKey(*) {
    global __GuanYuSkillKeys
    DeleteValueInArray(GuanYuGetCtrl("GuanYuKeysListBox").Text, __GuanYuSkillKeys)
    GuanYuChangeListGui(__GuanYuSkillKeys)
}

GuanYuSave(*) {
    GuanYuSaveConfig()
    HideGuiGuanYu()
}

GuanYuSetShotKey(*) {
    GuanYuGetCtrl("GuanYuShotKey").Text := GetPressKey()
}

GuanYuChangeListGui(keys) {
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
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

GuanYuDragGetItems(*) {
    global __GuanYuSkillKeys
    return UiListBoxDragSort_CopyArray(__GuanYuSkillKeys)
}

GuanYuDragCommit(items, selectedIndex) {
    global __GuanYuSkillKeys
    __GuanYuSkillKeys := items
    GuanYuChangeListGui(__GuanYuSkillKeys)
    if (selectedIndex > 0 && selectedIndex <= __GuanYuSkillKeys.Length) {
        try GuanYuGetCtrl("GuanYuKeysListBox").Choose(selectedIndex)
    }
}

GuanYuSaveConfig() {
    global __GuanYuSkillKeys
    keysString := ""
    for v in __GuanYuSkillKeys {
        keysString .= v "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    delay := Round((Trim(GuanYuGetCtrl("GuanYuDelay").Text) = "" ? 300 : GuanYuGetCtrl("GuanYuDelay").Text) + 0)
    if (delay < 0) {
        delay := 0
    } else if (delay > 500) {
        delay := 500
    }
    GuanYuGetCtrl("GuanYuDelay").Text := delay
    SavePreset(GetNowSelectPreset(), "GuanYuSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "GuanYuShotKey", GuanYuGetCtrl("GuanYuShotKey").Text)
    SavePreset(GetNowSelectPreset(), "GuanYuDelay", delay)
}

GuanYuLoadConfig() {
    global __GuanYuSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "GuanYuShotKey", "Space")
    delay := Round(LoadPreset(GetNowSelectPreset(), "GuanYuDelay", 300) + 0)
    if (delay < 0) {
        delay := 0
    } else if (delay > 500) {
        delay := 500
    }
    __GuanYuSkillKeys := GuanYuLoadKeys(GetNowSelectPreset())
    GuanYuChangeListGui(__GuanYuSkillKeys)
    GuanYuGetCtrl("GuanYuShotKey").Text := shotKey
    GuanYuGetCtrl("GuanYuDelay").Text := delay
}
