#Requires AutoHotkey v2.0

global gZhanFaGui := Gui("+ToolWindow")
global gZhanFaCtrls := Map()
global __ZhanFaSkillKeys := []

gZhanFaGui.OnEvent("Escape", ZhanFaGuiEscape)
gZhanFaGui.OnEvent("Close", ZhanFaGuiClose)

gZhanFaCtrls["ZhanFaKeysListBox"] := gZhanFaGui.Add("ListBox", "vZhanFaKeysListBox x8 y32 w80 h172")
gZhanFaCtrls["ZhanFaShotKey"] := gZhanFaGui.Add("Edit", "vZhanFaShotKey x96 y120 w80 h20 +ReadOnly -WantCtrlA")
gZhanFaGui.Add("Button", "x96 y40 w80 h22", "添加技能键").OnEvent("Click", ZhanFaAddKey)
gZhanFaGui.Add("Button", "x96 y70 w80 h22", "删除技能键").OnEvent("Click", ZhanFaDeleteKey)
gZhanFaGui.Add("Button", "x96 y148 w80 h22", "设置发射键").OnEvent("Click", ZhanFaSetShotKey)
gZhanFaGui.Add("Text", "x8 y8 w80 h20 +0x200", "已添加技能键")
gZhanFaGui.Add("Text", "x96 y100 w80 h20 +0x200", "炫纹发射键")
gZhanFaGui.Add("Button", "x96 y178 w80 h27", "保存").OnEvent("Click", ZhanFaSave)
gZhanFaGui.Add("Button", "x158 y8 w18 h18", "?").OnEvent("Click", ZhanFaHelp)

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
    gZhanFaGui.Show("w184 h210")
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
    key := GetPressKey()
    if IsValueInArray(key, __ZhanFaSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
    } else {
        __ZhanFaSkillKeys.Push(key)
    }
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
    for i, item in __ZhanFaSkillKeys {
        if (item = key) {
            ctrl.Choose(i)
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

ZhanFaSetShotKey(*) {
    ZhanFaGetCtrl("ZhanFaShotKey").Text := GetPressKey()
}

ZhanFaChangeListGui(keys) {
    ctrl := ZhanFaGetCtrl("ZhanFaKeysListBox")
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

ZhanFaSaveConfig() {
    global __ZhanFaSkillKeys
    keysString := ""
    for i, v in __ZhanFaSkillKeys {
        keysString .= v "|"
    }
    keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    SavePreset(GetNowSelectPreset(), "ZhanFaSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "ZhanFaShotKey", ZhanFaGetCtrl("ZhanFaShotKey").Text)
}

ZhanFaLoadConfig() {
    global __ZhanFaSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "ZhanFaShotKey", "Space")
    __ZhanFaSkillKeys := ZhanFaLoadKeys(GetNowSelectPreset())
    ZhanFaChangeListGui(__ZhanFaSkillKeys)
    ZhanFaGetCtrl("ZhanFaShotKey").Text := shotKey
}
