ExPetSkill(){
    SetDNFWindowClass()
    presetName := LoadLastPresetTrimmed()
    if (presetName = "") {
        return
    }
    if(LoadPreset(presetName, "PetSkillState", false)){
        ShotKey := LoadPresetSafe(presetName, "PetSkillShotKey")
        SkillKeys := PetSkillLoadKeys(presetName)
        if (SkillKeys.Length = 0) {
            return
        }
        if (ShotKey = "") {
            return
        }
        keyCode := Key2NoVkSC(ShotKey)
        pressKeys := []
        keyDownState := Map()
        loop SkillKeys.Length {
            if !SkillKeys.Has(A_Index) {
                continue
            }
            pressKey := Key2PressKey(SkillKeys[A_Index])
            pressKeys.Push(pressKey)
            keyDownState[pressKey] := false
        }
        loop {
            if(WinActive("ahk_group DNF")) {
                loop pressKeys.Length {
                    if !pressKeys.Has(A_Index) {
                        continue
                    }
                    pressKey := pressKeys[A_Index]
                    isDown := GetKeyState(pressKey, "P")
                    wasDown := keyDownState.Has(pressKey) ? keyDownState[pressKey] : false
                    ; 只在物理按键从抬起->按下时触发一次，不跟随按住连发
                    if (isDown && !wasDown) {
                        SendIP(keyCode)
                    }
                    keyDownState[pressKey] := isDown
                }
            } else {
                ; 切出游戏时重置边沿状态，避免切回后出现粘连
                for k in pressKeys {
                    keyDownState[k] := false
                }
            }
            Sleep(1)
        }
    }
}

; 读取预设的触发按键
PetSkillLoadKeys(presetName){
    skillKeysConfig := LoadPresetSafe(presetName, "PetSkillSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|")
    {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
