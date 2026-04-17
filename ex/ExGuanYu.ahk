ExGuanYu(){
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if(LoadPreset(presetName, "GuanYuState", false)){
        shotKey := LoadPreset(presetName, "GuanYuShotKey", "Space")
        delayMs := Round(LoadPreset(presetName, "GuanYuDelay", 300) + 0)
        if (delayMs < 0) {
            delayMs := 0
        } else if (delayMs > 500) {
            delayMs := 500
        }
        skillKeys := GuanYuLoadKeys(presetName)
        if (skillKeys.Length = 0) {
            return
        }
        keyCode := Key2NoVkSC(shotKey)
        pressKeys := []
        keyDownState := Map()
        pendingTriggerAt := Map()
        for sk in skillKeys{
            pressKey := Key2PressKey(sk)
            pressKeys.Push(pressKey)
            keyDownState[pressKey] := false
            pendingTriggerAt[pressKey] := 0
        }
        loop {
            if(WinActive("ahk_group DNF")) {
                now := A_TickCount
                for pressKey in pressKeys{
                    isDown := (GetKeyState(pressKey, "P") || GetKeyState(pressKey))
                    wasDown := keyDownState.Has(pressKey) ? keyDownState[pressKey] : false

                    ; 只在按下边沿登记一次触发，不跟随按住连发
                    if (isDown && !wasDown) {
                        pendingTriggerAt[pressKey] := now + delayMs
                    }

                    ; 到达延迟时间后仅触发一次
                    triggerAt := pendingTriggerAt.Has(pressKey) ? pendingTriggerAt[pressKey] : 0
                    if (triggerAt > 0 && now >= triggerAt) {
                        SendIP(keyCode)
                        pendingTriggerAt[pressKey] := 0
                    }

                    ; 松开后允许下一次按下重新触发
                    if (!isDown) {
                        keyDownState[pressKey] := false
                    } else {
                        keyDownState[pressKey] := true
                    }
                }
            } else {
                ; 切出游戏时清空状态，避免切回后误触发
                for pressKey in pressKeys {
                    keyDownState[pressKey] := false
                    pendingTriggerAt[pressKey] := 0
                }
            }
            Sleep(1)
        }
    }
}

GuanYuLoadKeys(presetName){
    skillKeysConfig := LoadPreset(presetName, "GuanYuSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|")
    {
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
