#Requires AutoHotkey v2.0

global gPetSkillGui := Gui("+ToolWindow")
global gPetSkillCtrls := Map()
global __PetSkillSkillKeys := []

gPetSkillGui.OnEvent("Escape", PetSkillGuiEscape)
gPetSkillGui.OnEvent("Close", PetSkillGuiClose)

gPetSkillCtrls["PetSkillKeysListBox"] := gPetSkillGui.Add("ListBox", "vPetSkillKeysListBox x8 y32 w80 h172")
gPetSkillCtrls["PetSkillShotKey"] := gPetSkillGui.Add("Edit", "vPetSkillShotKey x96 y120 w80 h20 +ReadOnly -WantCtrlA")
gPetSkillGui.Add("Button", "x96 y40 w80 h22", "添加触发键").OnEvent("Click", PetSkillAddKey)
gPetSkillGui.Add("Button", "x96 y70 w80 h22", "删除触发键").OnEvent("Click", PetSkillDeleteKey)
gPetSkillGui.Add("Button", "x96 y148 w80 h22", "设置宠物键").OnEvent("Click", PetSkillSetShotKey)
gPetSkillGui.Add("Text", "x8 y8 w80 h20 +0x200", "已添加触发键")
gPetSkillGui.Add("Text", "x96 y100 w80 h20 +0x200", "宠物技能键")
gPetSkillGui.Add("Button", "x96 y178 w80 h27", "保存").OnEvent("Click", PetSkillSave)
gPetSkillGui.Add("Button", "x158 y8 w18 h18", "?").OnEvent("Click", PetSkillHelp)

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
    gPetSkillGui.Show("w184 h210")
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
    MsgBox("1、添加你想触发宠物技能时按下的技能键`n2、设置游戏中的宠物技能键（默认Z）`n3、保存配置，启动连发并使用", "如何使用自动宠物技能", "Iconi")
}

PetSkillAddKey(*) {
    global __PetSkillSkillKeys
    key := GetPressKey()
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

PetSkillSetShotKey(*) {
    PetSkillGetCtrl("PetSkillShotKey").Text := GetPressKey()
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
    shotKey := LoadPreset(GetNowSelectPreset(), "PetSkillShotKey", "Z")
    __PetSkillSkillKeys := PetSkillLoadKeys(GetNowSelectPreset())
    PetSkillChangeListGui(__PetSkillSkillKeys)
    PetSkillGetCtrl("PetSkillShotKey").Text := shotKey
}
