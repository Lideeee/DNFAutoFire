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
        for sk in skillKeys{
            pressKeys.Push(Key2PressKey(sk))
        }
        loop {
            if(WinActive("ahk_group DNF")) {
                isNeedSend := false
                for pressKey in pressKeys{
                    if (GetKeyState(pressKey, "P") || GetKeyState(pressKey)) {
                        isNeedSend := true
                        break
                    }
                }
                if (isNeedSend) {
                    if (delayMs > 0) {
                        Sleep(delayMs)
                    }
                    SendIP(keyCode)
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
