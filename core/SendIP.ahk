SendIP(keyCode){
    Critical("On")

    SetKeyDelay(-1, -1)
    
    SendEvent("{Blind}{" keyCode " DownTemp}")
    DllCall("Sleep", "UInt", 8)
    SendEvent("{Blind}{" keyCode " Up}")
    DllCall("Sleep", "UInt", 2)
    
    Critical("Off")
}