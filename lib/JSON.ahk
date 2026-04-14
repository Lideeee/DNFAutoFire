; 简化版 JSON 读取器：满足本项目更新接口的字段读取需求
JSON2Object(str) {
    obj := Map()
    obj["assets"] := []

    tag := ""
    if RegExMatch(str, '"tag_name"\s*:\s*"((?:\\.|[^"])*)"', &mTag) {
        tag := __JSON_Unescape(mTag[1])
    }

    body := ""
    if RegExMatch(str, '"body"\s*:\s*"((?:\\.|[^"])*)"', &mBody) {
        body := __JSON_Unescape(mBody[1])
    }

    size := 0
    if RegExMatch(str, '"size"\s*:\s*(\d+)', &mSize) {
        size := mSize[1] + 0
    }

    obj["tag_name"] := tag
    obj["body"] := body
    obj["assets"].Push(Map("size", size))
    return obj
}

Object2JSON(obj) {
    throw Error("Object2JSON is not implemented in this project.")
}

__JSON_Unescape(text) {
    text := StrReplace(text, "\\", "\")
    text := StrReplace(text, "\/", "/")
    text := StrReplace(text, '\"', '"')
    text := StrReplace(text, "\r", "`r")
    text := StrReplace(text, "\n", "`n")
    text := StrReplace(text, "\t", "`t")
    return text
}