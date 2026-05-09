#Requires AutoHotkey v2.0

global gPetSkillGui := Gui("+ToolWindow -Theme")
global gPetSkillCtrls := Map()
global __PetSkillSkillKeys := []

GuiTheme_Apply(gPetSkillGui)

gPetSkillGui.OnEvent("Escape", PetSkillGuiEscape)
gPetSkillGui.OnEvent("Close", PetSkillGuiClose)

; 布局与关羽 EX 一致（「已添加触发键」与顶栏同宽占位）
gPetSkillGui.Add("Text", "x14 y10 w100 h18 +0x200", "已添加触发键")
GuiTheme_FlatBtnSmall(gPetSkillGui, "x116 y10 w18 h18", "?", PetSkillHelp)
gPetSkillCtrls["PetSkillKeysListBox"] := GuiTheme_AddMainStyleListBox(gPetSkillGui, "PetSkillKeysListBox", 14, 32, 108, 176)
GuiTheme_FlatBtnCompact(gPetSkillGui, "x14 y214 w54 h24", "添加", PetSkillAddKey)
GuiTheme_FlatBtnCompact(gPetSkillGui, "x76 y214 w54 h24", "删除", PetSkillDeleteKey)
gPetSkillGui.Add("Text", "x128 y36 w100 h24 +0x200", "宠物技能键")
gPetSkillCtrls["PetSkillShotKey"] := gPetSkillGui.Add("Edit", "vPetSkillShotKey x234 y36 w56 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gPetSkillCtrls["PetSkillShotKey"], GetKeycode.AfterCaptureEdit.Bind(gPetSkillCtrls["PetSkillShotKey"]))
GuiTheme_HRule(gPetSkillGui, 14, 252, 280)
GuiTheme_FlatBtn(gPetSkillGui, "x78 y260 w152 h34", "保存", PetSkillSave, true)

PetSkillGetCtrl(name) {
    global gPetSkillCtrls
    return gPetSkillCtrls.Has(name) ? gPetSkillCtrls[name] : ""
}

ShowGuiPetSkill(*) {
    global gMainGui, gPetSkillGui
    if IsObject(gMainGui) {
        gPetSkillGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gPetSkillGui.Title := "自动宠物技能"
    gPetSkillGui.Show("w308 h312")
    PetSkillLoadConfig()
    DisableGuiMain()
}

HideGuiPetSkill() {
    gPetSkillGui.Hide()
    EnableGuiMain()
}

PetSkillGuiEscape(*) {
    HideGuiPetSkill()
}

PetSkillGuiClose(*) {
    HideGuiPetSkill()
}

PetSkillHelp(*) {
    MsgBox("1、添加你想触发宠物技能时按下的技能键`n2、设置游戏中的宠物技能键（默认V）`n3、保存配置，启动连发并使用", "如何使用自动宠物技能", "Iconi")
}

PetSkillAddKey(*) {
    global __PetSkillSkillKeys
    raw := GetPressKey()
    key := GetKeycode.CanonMainKey(raw)
    if (key = "") {
        if (raw != "") {
            MsgBox("仅支持主连发键盘上的键。",, "Icon!")
        }
        return
    }
    if IsValueInArray(key, __PetSkillSkillKeys) {
        MsgBox("请勿重复添加按键",, "Icon!")
    } else {
        __PetSkillSkillKeys.Push(key)
    }
    PetSkillChangeListGui(__PetSkillSkillKeys)
    ctrl := PetSkillGetCtrl("PetSkillKeysListBox")
    displayIdx := 0
    loop __PetSkillSkillKeys.Length {
        if !__PetSkillSkillKeys.Has(A_Index) {
            continue
        }
        item := __PetSkillSkillKeys[A_Index]
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

PetSkillDeleteKey(*) {
    global __PetSkillSkillKeys
    DeleteValueInArray(PetSkillGetCtrl("PetSkillKeysListBox").Text, __PetSkillSkillKeys)
    PetSkillChangeListGui(__PetSkillSkillKeys)
}

PetSkillSave(*) {
    PetSkillSaveConfig()
    HideGuiPetSkill()
}

PetSkillChangeListGui(keys) {
    ctrl := PetSkillGetCtrl("PetSkillKeysListBox")
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

PetSkillSaveConfig() {
    global __PetSkillSkillKeys
    keysString := ""
    loop __PetSkillSkillKeys.Length {
        if !__PetSkillSkillKeys.Has(A_Index) {
            continue
        }
        keysString .= __PetSkillSkillKeys[A_Index] "|"
    }
    if (StrLen(keysString) > 0) {
        keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
    }
    SavePreset(GetNowSelectPreset(), "PetSkillSkillKeys", keysString)
    SavePreset(GetNowSelectPreset(), "PetSkillShotKey", PetSkillGetCtrl("PetSkillShotKey").Text)
}

PetSkillLoadConfig() {
    global __PetSkillSkillKeys
    shotKey := LoadPreset(GetNowSelectPreset(), "PetSkillShotKey", "V")
    cShot := GetKeycode.CanonMainKey(Trim(shotKey))
    PetSkillGetCtrl("PetSkillShotKey").Text := cShot != "" ? cShot : "V"
    __PetSkillSkillKeys := []
    for sk in PetSkillLoadKeys(GetNowSelectPreset()) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            __PetSkillSkillKeys.Push(c)
        }
    }
    PetSkillChangeListGui(__PetSkillSkillKeys)
}
