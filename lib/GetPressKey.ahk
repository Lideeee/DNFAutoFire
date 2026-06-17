GetPressKey(showTip := true){
    if showTip {
        try ShowTip(GetPressKeyPrompt(), false)
    }
    return GetUserInputKey()
}

GetPressKeyPrompt() {
    global exText
    if IsSet(exText) && IsObject(exText) && exText.Has("PressKeyPrompt") {
        return exText["PressKeyPrompt"]
    }
    return "输入按键.."
}

GetUserInputKey(){
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
}
