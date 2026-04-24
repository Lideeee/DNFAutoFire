ExLvRen(){
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if(LoadPreset(presetName, "LvRenState", false)){
        ShotKey := LoadPreset(presetName, "LvRenShotKey", "Z")
        intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
        if (intervalMs < 1) {
            intervalMs := 1
        } else if (intervalMs > 200) {
            intervalMs := 200
        }
        SkillKeys := LvRenLoadKeys(presetName)
        if (SkillKeys.Length = 0) {
            return
        }
        keyCode := Key2NoVkSC(ShotKey)
        pressKeys := []
        nextSendAt := 0
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
                    if (GetKeyState(pressKey, "P")) {
                        isNeedSend := true
                        break
                    }
                }
                now := A_TickCount
                if (isNeedSend) {
                    if (now >= nextSendAt) {
                        SendIP(keyCode)
                        nextSendAt := now + intervalMs
                    }
                } else {
                    ; 松开后重置，下一次按下可立即首发
                    nextSendAt := 0
                }
            } else {
                nextSendAt := 0
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
