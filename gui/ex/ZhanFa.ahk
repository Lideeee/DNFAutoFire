#Requires AutoHotkey v2.0

global gZhanFaGui := Gui("+ToolWindow -Theme")
global gZhanFaCtrls := Map()
global __ZhanFaSkillKeys := []

GuiTheme_Apply(gZhanFaGui)

gZhanFaGui.OnEvent("Escape", ZhanFaGuiEscape)
gZhanFaGui.OnEvent("Close", ZhanFaGuiClose)

; 布局与关羽 EX 一致
gZhanFaGui.Add("Text", "x14 y10 w100 h18 +0x200", "已添加技能键")
GuiTheme_FlatBtnSmall(gZhanFaGui, "x116 y10 w18 h18", "?", ZhanFaHelp)
gZhanFaCtrls["ZhanFaKeysListBox"] := GuiTheme_AddMainStyleListBox(gZhanFaGui, "ZhanFaKeysListBox", 14, 32, 108, 176)
GuiTheme_FlatBtnCompact(gZhanFaGui, "x14 y214 w54 h24", "添加", ZhanFaAddKey)
GuiTheme_FlatBtnCompact(gZhanFaGui, "x76 y214 w54 h24", "删除", ZhanFaDeleteKey)
gZhanFaGui.Add("Text", "x128 y36 w100 h24 +0x200", "炫纹发射键")
gZhanFaCtrls["ZhanFaShotKey"] := gZhanFaGui.Add("Edit", "vZhanFaShotKey x234 y36 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gZhanFaCtrls["ZhanFaShotKey"], GetKeycode.AfterCaptureEdit.Bind(gZhanFaCtrls["ZhanFaShotKey"]))
GuiTheme_HRule(gZhanFaGui, 14, 252, 280)
GuiTheme_FlatBtn(gZhanFaGui, "x78 y260 w152 h34", "保存", ZhanFaSave, true)

ZhanFaGetCtrl(name) {
    global gZhanFaCtrls
    return gZhanFaCtrls.Has(name) ? gZhanFaCtrls[name] : ""
}

ShowGuiZhanFa(*) {
    global gMainGui, gZhanFaGui
    if IsObject(gMainGui) {
        gZhanFaGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gZhanFaGui.Title := "战法自动炫纹"
    gZhanFaGui.Show("w308 h312")
    ZhanFaLoadConfig()
    DisableGuiMain()
}

HideGuiZhanFa() {
    gZhanFaGui.Hide()
    EnableGuiMain()
}

ZhanFaGuiEscape(*) {
    HideGuiZhanFa()
}

ZhanFaGuiClose(*) {
    HideGuiZhanFa()
}

ZhanFaHelp(*) {
    MsgBox("你的数据很差，我现在玩战法每130s只要能射出300次炫纹，每次差不多34824％的等效百分比，就能有相当于10447200％的输出水平，换算过来狠狠地超越了精灵骑士的三觉数据。虽然我作为爆发职业没有一个技能超过3000000％，作为续航职业没有一个技能秒伤能超过90000％，但是我的炫纹已经超越了地下城绝大多数职业(包括你)的水平，这便是战斗法师给我的骄傲的资本。", "你的数据很差", "Iconi")
}

ZhanFaAddKey(*) {
    global __ZhanFaSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox("仅支持主连发键盘上的键。",, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __ZhanFaSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
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
