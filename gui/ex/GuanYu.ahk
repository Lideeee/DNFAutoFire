#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gGuanYuGui := Gui("+ToolWindow -Theme")
global gGuanYuCtrls := Map()
global __GuanYuSkillKeys := []

GuiTheme_Apply(gGuanYuGui)

gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

gGuanYuGui.Add("Text", "x14 y10 w100 h18 +0x200", ExText.GuanYuListLabel())
GuiTheme_FlatBtnSmall(gGuanYuGui, "x116 y10 w18 h18", GuiText.HelpButton(), GuanYuHelp)
gGuanYuCtrls["GuanYuKeysListBox"] := GuiTheme_AddMainStyleListBox(gGuanYuGui, "GuanYuKeysListBox", 14, 32, 108, 176)
GuiTheme_FlatBtnCompact(gGuanYuGui, "x14 y214 w54 h24", ExText.AddButton(), GuanYuAddKey)
GuiTheme_FlatBtnCompact(gGuanYuGui, "x76 y214 w54 h24", ExText.DeleteButton(), GuanYuDeleteKey)
gGuanYuGui.Add("Text", "x128 y36 w100 h24 +0x200", ExText.GuanYuShotKeyLabel())
gGuanYuCtrls["GuanYuShotKey"] := gGuanYuGui.Add("Edit", "vGuanYuShotKey x234 y36 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gGuanYuCtrls["GuanYuShotKey"], GetKeycode.AfterCaptureEdit.Bind(gGuanYuCtrls["GuanYuShotKey"]))
gGuanYuGui.Add("Text", "x128 y68 w100 h24 +0x200", ExText.GuanYuDelayLabel())
gGuanYuCtrls["GuanYuDelay"] := gGuanYuGui.Add("Edit", "vGuanYuDelay x234 y68 w56 h24 +Number -E0x200 Border")
GuiTheme_HRule(gGuanYuGui, 14, 252, 280)
GuiTheme_FlatBtn(gGuanYuGui, "x78 y260 w152 h34", ExText.SaveButton(), GuanYuSave, true)

GuanYuGetCtrl(name) {
    global gGuanYuCtrls
    return gGuanYuCtrls.Has(name) ? gGuanYuCtrls[name] : ""
}

ShowGuiGuanYu(*) {
    ExWindowHost.ShowOwned(gGuanYuGui, ExText.GuanYuTitle(), "w308 h312")
    GuanYuLoadConfig()
}

HideGuiGuanYu() {
    ExWindowHost.HideOwned(gGuanYuGui)
}

GuanYuGuiEscape(*) {
    HideGuiGuanYu()
}

GuanYuGuiClose(*) {
    HideGuiGuanYu()
}

GuanYuHelp(*) {
    MsgBox(ExText.GuanYuHelp(), ExText.GuanYuHelpTitle(), "Icon!")
}

GuanYuAddKey(*) {
    global __GuanYuSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.InvalidKey(),, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __GuanYuSkillKeys) {
        MsgBox(ExText.DuplicateKey(),, "Icon!")
    } else {
        __GuanYuSkillKeys.Push(key)
    }
    GuanYuChangeListGui(__GuanYuSkillKeys)
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
    displayIdx := 0
    loop __GuanYuSkillKeys.Length {
        if !__GuanYuSkillKeys.Has(A_Index) {
            continue
        }
        item := __GuanYuSkillKeys[A_Index]
        if (item = "") {
            continue
        }
        displayIdx++
        if (item = key) {
            ctrl.Choose(displayIdx)
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

GuanYuChangeListGui(keys) {
    ctrl := GuanYuGetCtrl("GuanYuKeysListBox")
    ctrl.Delete()
    cnt := 0
    if !IsObject(keys) {
        keys := []
    }
    loop keys.Length {
        if !keys.Has(A_Index) {
            continue
        }
        key := keys[A_Index]
        if (key != "") {
            ctrl.Add([key])
            cnt++
        }
    }
    if (cnt > 0) {
        ctrl.Choose(1)
    }
}

GuanYuSaveConfig() {
    global __GuanYuSkillKeys
    keysString := ""
    loop __GuanYuSkillKeys.Length {
        if !__GuanYuSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __GuanYuSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    delay := Round((Trim(GuanYuGetCtrl("GuanYuDelay").Text) = "" ? 300 : GuanYuGetCtrl("GuanYuDelay").Text) + 0)
    if (delay < 20) {
        delay := 20
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
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    delay := Round(LoadPreset(GetNowSelectPreset(), "GuanYuDelay", 300) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 500) {
        delay := 500
    }
    __GuanYuSkillKeys := []
    for sk in GuanYuLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __GuanYuSkillKeys.Push(c)
        }
    }
    GuanYuChangeListGui(__GuanYuSkillKeys)
    GuanYuGetCtrl("GuanYuShotKey").Text := cShot != "" ? cShot : "Space"
    GuanYuGetCtrl("GuanYuDelay").Text := delay
}
