#Requires AutoHotkey v2.0

global gLvRenGui := Gui("+ToolWindow -Theme")
global gLvRenCtrls := Map()
global __LvRenSkillKeys := []

GuiTheme_Apply(gLvRenGui)

gLvRenGui.OnEvent("Escape", LvRenGuiEscape)
gLvRenGui.OnEvent("Close", LvRenGuiClose)

; 布局与关羽 EX 一致：顶栏收紧、列表 108×176、右侧标签 w100 + 发射键 x234 w56
gLvRenGui.Add("Text", "x14 y10 w100 h18 +0x200", "已添加技能键")
GuiTheme_FlatBtnSmall(gLvRenGui, "x116 y10 w18 h18", "?", LvRenHelp)
gLvRenCtrls["LvRenKeysListBox"] := GuiTheme_AddMainStyleListBox(gLvRenGui, "LvRenKeysListBox", 14, 32, 108, 176)
GuiTheme_FlatBtnCompact(gLvRenGui, "x14 y214 w54 h24", "添加", LvRenAddKey)
GuiTheme_FlatBtnCompact(gLvRenGui, "x76 y214 w54 h24", "删除", LvRenDeleteKey)
gLvRenGui.Add("Text", "x128 y36 w100 h24 +0x200", "流星发射键")
gLvRenCtrls["LvRenShotKey"] := gLvRenGui.Add("Edit", "vLvRenShotKey x234 y36 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gLvRenCtrls["LvRenShotKey"], GetKeycode.AfterCaptureEdit.Bind(gLvRenCtrls["LvRenShotKey"]))
GuiTheme_HRule(gLvRenGui, 14, 252, 280)
GuiTheme_FlatBtn(gLvRenGui, "x78 y260 w152 h34", "保存", LvRenSave, true)

LvRenGetCtrl(name) {
    global gLvRenCtrls
    return gLvRenCtrls.Has(name) ? gLvRenCtrls[name] : ""
}

ShowGuiLvRen(*) {
    global gMainGui, gLvRenGui
    if IsObject(gMainGui) {
        gLvRenGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gLvRenGui.Title := "旅人自动流星"
    gLvRenGui.Show("w308 h312")
    LvRenLoadConfig()
    DisableGuiMain()
}

HideGuiLvRen() {
    gLvRenGui.Hide()
    EnableGuiMain()
}

LvRenGuiEscape(*) {
    HideGuiLvRen()
}

LvRenGuiClose(*) {
    HideGuiLvRen()
}

LvRenHelp(*) {
    MsgBox("1、添加你想要发射流星的技能键`n2、设置游戏中流星的发射键（默认为Z）`n3、保存配置，启动连发并使用`n`nPS：建议和连发功能一起打开，效果更好", "如何使用旅人自动流星", "Iconi")
}

LvRenAddKey(*) {
    global __LvRenSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox("仅支持主连发键盘上的键。",, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __LvRenSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
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
