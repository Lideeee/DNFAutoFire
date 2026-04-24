ExJianZong(){
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if(LoadPreset(presetName, "JianZongState", false)){
        skillKey := LoadPreset(presetName, "JianZongSkillKey", "A")
        delay := LoadPreset(presetName, "JianZongDelay", 200)
        if (skillKey = "") {
            return
        }
        keyCode := Key2NoVkSC(skillKey)
        pressKey := Key2PressKey(skillKey)
        counterTime := 0
        time := A_TickCount
        loop {
            if(WinActive("ahk_group DNF")) {
                while (GetKeyState(pressKey, "P")){
                    counterTime := A_TickCount - time
                    if(counterTime > delay){
                        SendIP(keyCode)
                    }
                }
                counterTime := 0
                time := A_TickCount
            }
            Sleep(1)
        }
    }
}