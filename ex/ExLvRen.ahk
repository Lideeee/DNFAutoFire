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
        for i, sk in SkillKeys{
            pressKeys.Push(Key2PressKey(sk))
        }
        loop {
            if(WinActive("ahk_group DNF")) {
                isNeedSend := false
                for j, pressKey in pressKeys{
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
