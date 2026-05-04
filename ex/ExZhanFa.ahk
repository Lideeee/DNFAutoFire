ExZhanFa(){
    SetDNFWindowClass()
    presetName := LoadLastPresetTrimmed()
    if (presetName = "") {
        return
    }
    if(LoadPreset(presetName, "ZhanFaState", false)){
        ShotKey := LoadPresetSafe(presetName, "ZhanFaShotKey")
        intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
        if (intervalMs < 1) {
            intervalMs := 1
        } else if (intervalMs > 200) {
            intervalMs := 200
        }
        SkillKeys := ZhanFaLoadKeys(presetName)
        if (SkillKeys.Length = 0) {
            return
        }
        if (ShotKey = "") {
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
ZhanFaLoadKeys(presetName){
    skillKeysConfig := LoadPresetSafe(presetName, "ZhanFaSkillKeys")
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