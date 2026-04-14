AutoFire(key){
    ProcessSetPriority("High")
    keyCode := Key2NoVkSC(key)
    pressKey := Key2PressKey(key)
    loop {
        while (GetKeyState(pressKey, "P") || GetKeyState(pressKey)) {
            SendIP(keyCode)
        }
        Sleep(1)
    }
}