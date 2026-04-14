ExPetSkill(){
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if(LoadPreset(presetName, "PetSkillState", false)){
        ShotKey := LoadPreset(presetName, "PetSkillShotKey", "Z")
        SkillKeys := PetSkillLoadKeys(presetName)
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

; 读取预设的触发按键
PetSkillLoadKeys(presetName){
    skillKeysConfig := LoadPreset(presetName, "PetSkillSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|")
    {
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
