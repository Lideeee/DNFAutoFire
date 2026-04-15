GetPressKey(){
    return GetUserInputKey()
}

GetUserInputKey(){
    ; 给出可见提示，避免用户误以为按钮无响应
    ToolTip("请按下一个按键...")
    try {
        ih := InputHook("L0")
        ih.KeyOpt("{All}", "E")
        ih.KeyOpt("{LWin}{RWin}{AppsKey}", "-E")
        ih.Start()
        ih.Wait()
        key := ih.EndKey
        if(StrLen(key) == 1){
            key := Format("{:U}",key)
        }
        return key
    } finally {
        ToolTip()
    }
}