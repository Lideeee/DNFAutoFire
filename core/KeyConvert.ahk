; 按键转换为只有扫描码
Key2NoVkSC(key){
    sc := GetKeySC(key)
    return Format("vkFFsc{1:02X}", sc)
}

; 按键转换为只有虚拟码
Key2VKNoSC(key){
    vk := GetKeyVK(key)
    return Format("vk{1:02X}scFF", vk)
}

; 按键转换扫描码
Key2SC(key){
    sc := GetKeySC(key)
    return Format("sc{1:02X}", sc)
}

; 按键转换为虚拟码
Key2VK(key){
    vk := GetKeyVK(key)
    return Format("vk{1:02X}", vk)
}

; 按键转换为检测按下的物理按键（供 GetKeyState(..., "P") 等）
Key2PressKey(key){
    ; 左右修饰键用原名最稳，与文档中 GetKeyState("LAlt", "P") 等一致（含自动宠物技能触发键）
    switch key {
        case "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift":
            return key
    }
    newKey := Key2SC(key)
    if (InStr(key, "Num")) {
        newKey := key
    }
    return newKey
}