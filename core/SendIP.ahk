SendIP(keyCode){
    ; 强行接管发送节奏，不让任何按键插队
    Critical("On")
    
    ; 强制使用 SendEvent，保护键盘钩子绝对不掉线
    ; 第一个 -1：取消 AHK 默认的按键间延迟
    ; 第二个 -1：取消 AHK 默认的按下时长（由下方的 Sleep 亲自精准接管）
    SetKeyDelay(-1, -1)
    
    SendEvent("{Blind}{" keyCode " DownTemp}")
    
    ; 保持 8ms 的按下时间，让 DNF 引擎稳定抓取“按下”指令
    DllCall("Sleep", "UInt", 8)
    
    SendEvent("{Blind}{" keyCode " Up}")
    
    ; 【核心救命点】：强制给出 2ms 的“呼吸缓冲期”
    ; 确保当前按键彻底抬起、且被 DNF 接收后，下一个排队的按键才能执行 Down
    DllCall("Sleep", "UInt", 2)
    
    Critical("Off")
}