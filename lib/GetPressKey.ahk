GetPressKey(){
    return GetUserInputKey()
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