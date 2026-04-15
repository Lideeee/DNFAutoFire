ExLvRen(){
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if(LoadPreset(presetName, "LvRenState", false)){
        ShotKey := LoadPreset(presetName, "LvRenShotKey", "Z")
        SkillKeys := LvRenLoadKeys(presetName)
        if (SkillKeys.Length = 0) {
            return
        }
        keyCode := Key2NoVkSC(ShotKey)
        pressKeys := []
        loop SkillKeys.Length {
            if !SkillKeys.Has(A_Index) {
                continue
            }
            pressKeys.Push(Key2PressKey(SkillKeys[A_Index]))
        }
        loop {
            if(WinActive("ahk_group DNF")) {
                isNeedSend := false
                loop pressKeys.Length {
                    if !pressKeys.Has(A_Index) {
                        continue
                    }
                    pressKey := pressKeys[A_Index]
                    if (GetKeyState(pressKey, "P") || GetKeyState(pressKey)) {
                        isNeedSend := true
                        break
                    }
                }
                if (isNeedSend) {
                    Sleep(1)
                    SendIP(keyCode)
                }
            }
            Sleep(1)
        }
    }
}

; 读取预设的连发按键
LvRenLoadKeys(presetName){
    skillKeysConfig := LoadPreset(presetName, "LvRenSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|")
    {
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
