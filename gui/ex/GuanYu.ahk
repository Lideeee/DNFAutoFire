#Requires AutoHotkey v2.0

global gGuanYuGui := Gui("+ToolWindow -Theme")
global gGuanYuCtrls := Map()
global __GuanYuSkillKeys := []

GuiTheme_Apply(gGuanYuGui)

gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

; 顶区收紧；列表略缩宽为右侧标签留出完整「手动延迟(ms)」宽度
gGuanYuGui.Add("Text", "x14 y10 w100 h18 +0x200", "已添加技能键")
GuiTheme_FlatBtnSmall(gGuanYuGui, "x116 y10 w18 h18", "?", GuanYuHelp)
gGuanYuCtrls["GuanYuKeysListBox"] := GuiTheme_AddMainStyleListBox(gGuanYuGui, "GuanYuKeysListBox", 14, 32, 108, 176)
GuiTheme_FlatBtnCompact(gGuanYuGui, "x14 y214 w54 h24", "添加", GuanYuAddKey)
GuiTheme_FlatBtnCompact(gGuanYuGui, "x76 y214 w54 h24", "删除", GuanYuDeleteKey)
; 标签同宽 w100 容纳「手动延迟(ms)」；两枚 Edit 同 x234、同 w56，仅 y 不同
gGuanYuGui.Add("Text", "x128 y36 w100 h24 +0x200", "猛攻发射键")
gGuanYuCtrls["GuanYuShotKey"] := gGuanYuGui.Add("Edit", "vGuanYuShotKey x234 y36 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gGuanYuCtrls["GuanYuShotKey"], GetKeycode.AfterCaptureEdit.Bind(gGuanYuCtrls["GuanYuShotKey"]))
gGuanYuGui.Add("Text", "x128 y68 w100 h24 +0x200", "手动延迟(ms)")
gGuanYuCtrls["GuanYuDelay"] := gGuanYuGui.Add("Edit", "vGuanYuDelay x234 y68 w56 h24 +Number -E0x200 Border")
GuiTheme_HRule(gGuanYuGui, 14, 252, 280)
GuiTheme_FlatBtn(gGuanYuGui, "x78 y260 w152 h34", "保存", GuanYuSave, true)

GuanYuGetCtrl(name) {
    global gGuanYuCtrls
    return gGuanYuCtrls.Has(name) ? gGuanYuCtrls[name] : ""
}

ShowGuiGuanYu(*) {
    global gMainGui, gGuanYuGui
    if IsObject(gMainGui) {
        gGuanYuGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gGuanYuGui.Title := "关羽自动战戟猛攻"
    gGuanYuGui.Show("w308 h312")
    GuanYuLoadConfig()
    DisableGuiMain()
}

HideGuiGuanYu() {
    gGuanYuGui.Hide()
    EnableGuiMain()
}

GuanYuGuiEscape(*) {
    HideGuiGuanYu()
}

GuanYuGuiClose(*) {
    HideGuiGuanYu()
}

GuanYuHelp(*) {
    MsgBox("1、添加触发猛攻的技能键`n2、设置游戏中猛攻的发射键（默认Space）`n3、可手动设置发射前延迟(ms，默认300)`n4、保存配置，启动连发并使用", "如何使用关羽自动战戟猛攻", "Iconi")
}

GuanYuAddKey(*) {
    global __GuanYuSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox("仅支持主连发键盘上的键。",, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __GuanYuSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
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
