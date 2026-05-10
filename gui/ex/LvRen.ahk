#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gLvRenGui := Gui("+ToolWindow -Theme")
global gLvRenCtrls := Map()
global __LvRenSkillKeys := []

GuiTheme_Apply(gLvRenGui)

gLvRenGui.OnEvent("Escape", LvRenGuiEscape)
gLvRenGui.OnEvent("Close", LvRenGuiClose)

gLvRenGui.Add("Text", "x14 y10 w100 h18 +0x200", ExText.LvRenListLabel())
GuiTheme_FlatBtnSmall(gLvRenGui, "x116 y10 w18 h18", GuiText.HelpButton(), LvRenHelp)
gLvRenCtrls["LvRenKeysListBox"] := GuiTheme_AddMainStyleListBox(gLvRenGui, "LvRenKeysListBox", 14, 32, 108, 176)
GuiTheme_FlatBtnCompact(gLvRenGui, "x14 y214 w54 h24", ExText.AddButton(), LvRenAddKey)
GuiTheme_FlatBtnCompact(gLvRenGui, "x76 y214 w54 h24", ExText.DeleteButton(), LvRenDeleteKey)
gLvRenGui.Add("Text", "x128 y36 w100 h24 +0x200", ExText.LvRenShotKeyLabel())
gLvRenCtrls["LvRenShotKey"] := gLvRenGui.Add("Edit", "vLvRenShotKey x234 y36 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gLvRenCtrls["LvRenShotKey"], GetKeycode.AfterCaptureEdit.Bind(gLvRenCtrls["LvRenShotKey"]))
GuiTheme_HRule(gLvRenGui, 14, 252, 280)
GuiTheme_FlatBtn(gLvRenGui, "x78 y260 w152 h34", ExText.SaveButton(), LvRenSave, true)

LvRenGetCtrl(name) {
    global gLvRenCtrls
    return gLvRenCtrls.Has(name) ? gLvRenCtrls[name] : ""
}

ShowGuiLvRen(*) {
    ExWindowHost.ShowOwned(gLvRenGui, ExText.LvRenTitle(), "w308 h312")
    LvRenLoadConfig()
}

HideGuiLvRen() {
    ExWindowHost.HideOwned(gLvRenGui)
}

LvRenGuiEscape(*) {
    HideGuiLvRen()
}

LvRenGuiClose(*) {
    HideGuiLvRen()
}

LvRenHelp(*) {
    MsgBox(ExText.LvRenHelp(), ExText.LvRenHelpTitle(), "Icon!")
}

LvRenAddKey(*) {
    global __LvRenSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.InvalidKey(),, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __LvRenSkillKeys) {
        MsgBox(ExText.DuplicateKey(),, "Icon!")
    } else {
        __LvRenSkillKeys.Push(key)
    }
    LvRenChangeListGui(__LvRenSkillKeys)
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
    displayIdx := 0
    loop __LvRenSkillKeys.Length {
        if !__LvRenSkillKeys.Has(A_Index) {
            continue
        }
        item := __LvRenSkillKeys[A_Index]
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

LvRenDeleteKey(*) {
    global __LvRenSkillKeys
    DeleteValueInArray(LvRenGetCtrl("LvRenKeysListBox").Text, __LvRenSkillKeys)
    LvRenChangeListGui(__LvRenSkillKeys)
}

LvRenSave(*) {
    LvRenSaveConfig()
    HideGuiLvRen()
}

LvRenChangeListGui(keys) {
    ctrl := LvRenGetCtrl("LvRenKeysListBox")
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

LvRenSaveConfig() {
    global __LvRenSkillKeys
    keysString := ""
    loop __LvRenSkillKeys.Length {
        if !__LvRenSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __LvRenSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    SavePreset(GetNowSelectPreset(), "LvRenSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "LvRenShotKey", LvRenGetCtrl("LvRenShotKey").Text)
}

LvRenLoadConfig() {
    global __LvRenSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "LvRenShotKey", "Z")
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    LvRenGetCtrl("LvRenShotKey").Text := cShot != "" ? cShot : "Z"
    __LvRenSkillKeys := []
    for sk in LvRenLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __LvRenSkillKeys.Push(c)
        }
    }
    LvRenChangeListGui(__LvRenSkillKeys)
}
