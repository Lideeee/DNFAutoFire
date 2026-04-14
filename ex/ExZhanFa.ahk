ExZhanFa(){
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if(LoadPreset(presetName, "ZhanFaState", false)){
        ShotKey := LoadPreset(presetName, "ZhanFaShotKey", "Space")
        SkillKeys := ZhanFaLoadKeys(presetName)
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
                    SendIP(keyCode)
                }
            }
            Sleep(1)
        }
    }
}

; 读取预设的连发按键
ZhanFaLoadKeys(presetName){
    skillKeysConfig := LoadPreset(presetName, "ZhanFaSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|")
    {
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}