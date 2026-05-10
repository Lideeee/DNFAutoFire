#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gZhanFaGui := Gui("+ToolWindow -Theme")
global gZhanFaCtrls := Map()
global __ZhanFaSkillKeys := []

GuiTheme_Apply(gZhanFaGui)

gZhanFaGui.OnEvent("Escape", ZhanFaGuiEscape)
gZhanFaGui.OnEvent("Close", ZhanFaGuiClose)

gZhanFaGui.Add("Text", "x16 y16 w100 h18 +0x200", ExText.ZhanFaListLabel())
GuiTheme_FlatBtnSmall(gZhanFaGui, "x118 y16 w18 h18", GuiText.HelpButton(), ZhanFaHelp)
gZhanFaCtrls["ZhanFaKeysListBox"] := GuiTheme_AddListBox(gZhanFaGui, "ZhanFaKeysListBox", 16, 38, 108, 176)
GuiTheme_FlatBtnCompact(gZhanFaGui, "x16 y220 w54 h24", ExText.AddButton(), ZhanFaAddKey)
GuiTheme_FlatBtnCompact(gZhanFaGui, "x78 y220 w54 h24", ExText.DeleteButton(), ZhanFaDeleteKey)
gZhanFaGui.Add("Text", "x130 y42 w100 h24 +0x200", ExText.ZhanFaShotKeyLabel())
gZhanFaCtrls["ZhanFaShotKey"] := gZhanFaGui.Add("Edit", "vZhanFaShotKey x236 y42 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gZhanFaCtrls["ZhanFaShotKey"], GetKeycode.AfterCaptureEdit.Bind(gZhanFaCtrls["ZhanFaShotKey"]))
GuiTheme_HRule(gZhanFaGui, 16, 254, 276)
GuiTheme_FlatBtn(gZhanFaGui, "x78 y262 w152 h34", ExText.SaveButton(), ZhanFaSave, true)

ZhanFaGetCtrl(name) {
    global gZhanFaCtrls
    return gZhanFaCtrls.Has(name) ? gZhanFaCtrls[name] : ""
}

ShowGuiZhanFa(*) {
    ExWindowHost.ShowOwnedFit(gZhanFaGui, ExText.ZhanFaTitle())
    ZhanFaLoadConfig()
}

HideGuiZhanFa() {
    ExWindowHost.HideOwned(gZhanFaGui)
}

ZhanFaGuiEscape(*) {
    HideGuiZhanFa()
}

ZhanFaGuiClose(*) {
    HideGuiZhanFa()
}

ZhanFaHelp(*) {
    MsgBox(ExText.ZhanFaHelp(), ExText.ZhanFaHelpTitle(), "Icon!")
}

ZhanFaAddKey(*) {
    global __ZhanFaSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox(ExText.InvalidKey(),, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __ZhanFaSkillKeys) {
        MsgBox(ExText.DuplicateKey(),, "Icon!")
    } else {
        __ZhanFaSkillKeys.Push(key)
    }
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
    displayIdx := 0
    loop __ZhanFaSkillKeys.Length {
        if !__ZhanFaSkillKeys.Has(A_Index) {
            continue
        }
        item := __ZhanFaSkillKeys[A_Index]
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

ZhanFaDeleteKey(*) {
    global __ZhanFaSkillKeys
    DeleteValueInArray(ZhanFaGetCtrl("ZhanFaKeysListBox").Text, __ZhanFaSkillKeys)
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
}

ZhanFaSave(*) {
    ZhanFaSaveConfig()
    HideGuiZhanFa()
}

ZhanFaChangeListGui(keys) {
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
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

ZhanFaSaveConfig() {
    global __ZhanFaSkillKeys
    keysString := ""
    loop __ZhanFaSkillKeys.Length {
        if !__ZhanFaSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __ZhanFaSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    SavePreset(GetNowSelectPreset(), "ZhanFaSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "ZhanFaShotKey", ZhanFaGetCtrl("ZhanFaShotKey").Text)
}

ZhanFaLoadConfig() {
    global __ZhanFaSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "ZhanFaShotKey", "Space")
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    ZhanFaGetCtrl("ZhanFaShotKey").Text := cShot != "" ? cShot : "Space"
    __ZhanFaSkillKeys := []
    for sk in ZhanFaLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __ZhanFaSkillKeys.Push(c)
        }
    }
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
}
