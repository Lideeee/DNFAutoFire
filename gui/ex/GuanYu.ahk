#Requires AutoHotkey v2.0

global gGuanYuGui := Gui("+ToolWindow")
global gGuanYuCtrls := Map()
global __GuanYuSkillKeys := []

gGuanYuGui.OnEvent("Escape", GuanYuGuiEscape)
gGuanYuGui.OnEvent("Close", GuanYuGuiClose)

gGuanYuCtrls["GuanYuKeysListBox"] := gGuanYuGui.Add("ListBox", "vGuanYuKeysListBox x8 y32 w80 h172")
gGuanYuCtrls["GuanYuShotKey"] := gGuanYuGui.Add("Edit", "vGuanYuShotKey x96 y120 w80 h20 +ReadOnly -WantCtrlA")
gGuanYuCtrls["GuanYuDelay"] := gGuanYuGui.Add("Edit", "vGuanYuDelay x96 y200 w80 h20 +Number")
gGuanYuGui.Add("Button", "x96 y40 w80 h22", "添加技能键").OnEvent("Click", GuanYuAddKey)
gGuanYuGui.Add("Button", "x96 y70 w80 h22", "删除技能键").OnEvent("Click", GuanYuDeleteKey)
gGuanYuGui.Add("Button", "x96 y148 w80 h22", "设置发射键").OnEvent("Click", GuanYuSetShotKey)
gGuanYuGui.Add("Text", "x8 y8 w80 h20 +0x200", "已添加技能键")
gGuanYuGui.Add("Text", "x96 y100 w80 h20 +0x200", "猛攻发射键")
gGuanYuGui.Add("Text", "x96 y180 w80 h20 +0x200", "手动延迟(ms)")
gGuanYuGui.Add("Button", "x96 y232 w80 h27", "保存").OnEvent("Click", GuanYuSave)
gGuanYuGui.Add("Button", "x158 y8 w18 h18", "?").OnEvent("Click", GuanYuHelp)

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
    gGuanYuGui.Show("w184 h270")
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
    key := GetPressKey()
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

GuanYuSetShotKey(*) {
    GuanYuGetCtrl("GuanYuShotKey").Text := GetPressKey()
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
