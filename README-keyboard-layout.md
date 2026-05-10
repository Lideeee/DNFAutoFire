# 键盘区定义公式

这份说明对应当前键盘区布局实现，主要代码在：

- [gui/main/layout/MainKeyLayoutData.ahk](D:/06Code/DNFAutoFire/gui/main/layout/MainKeyLayoutData.ahk)
- [gui/main/layout/MainLayout.ahk](D:/06Code/DNFAutoFire/gui/main/layout/MainLayout.ahk)

## 1. 基础参数

- `BaseX()`：键盘区左边界起点
- `TopRowY()`：最上方 `Esc / F区 / 清空 / 版本信息` 这一排的顶边
- `Unit()`：`1u` 的可见宽度
- `Gap()`：按键之间的间隔
- `Height()`：按键高度，当前规则是 `Unit() - 2`

## 2. 宽度换算公式

- `Pitch() = Unit() + Gap()`
- `KeyWidth(u) = u * Pitch() - Gap()`

含义：

- `1u` 键的可见宽度就是 `Unit()`
- 长按键会把内部本该占用的间隔一起并进总宽度里

## 3. 纵向排布公式

- `MainRowY() = TopRowY() + Height() + Gap()`
- `RowY(index) = MainRowY() + (index - 1) * (Height() + Gap())`

也就是说：

- F 区和主键盘第一排之间固定只隔一个 `Gap()`
- 后面每一排也都是“上一排高度 + 一个间隔”

## 4. 主键区与小键盘分界

- `AlphaBlockRight()`：由主字母区最右边自动推出来的右边界
- `MainBlockRight() = AlphaBlockRight()`
- `NumpadX() = MainBlockRight() + Gap()`

也就是小键盘第一列 `Num / 7 / 4 / 1` 永远贴在主键区右边一个间隔的位置。

## 5. F 区规则

- `Esc` 固定在 `` ` `` 键上方
- `F12` 固定在 `Back` 键上方，并且和 `Back` 右对齐
- `F1-F12` 分成三组：
  - `F1-F4`
  - `F5-F8`
  - `F9-F12`
- 三个大空档分别是：
  - `Esc-F1`
  - `F4-F5`
  - `F8-F9`

大空档算法：

1. 先算出 `Esc` 到 `F12` 这一段总长度
2. 扣掉 13 个按键宽度
3. 再扣掉组内 9 个普通间隔
4. 剩余长度平均分给 3 个大空档
5. 如果除不尽：
   - 余数为 `1`：第一个大空档 `+1px`
   - 余数为 `2`：前两个大空档各 `+1px`

## 6. 顶部右侧规则

- `TopRowClearX()`：`清空` 按钮的位置
- `VersionWidth()`：版本信息区域宽度，定义为“三个单键宽 + 两个间隔”
- `TopRowVersionX()`：版本信息区域左边界

当前键盘区右边界规则：

- `KeyboardRight() = TopRowClearX() + KeyWidth(1)`

也就是整个键盘区总宽只看 `清空` 按钮的右边缘。

## 7. 整个键盘区尺寸

- `KeyboardLeft() = BaseX()`
- `KeyboardTop() = TopRowY()`
- `KeyboardRight() = TopRowClearX() + KeyWidth(1)`
- `KeyboardBottom() = RowY(5) + Height()`

所以：

- `KeyboardWidth() = KeyboardRight() - KeyboardLeft()`
- `KeyboardHeight() = KeyboardBottom() - KeyboardTop()`

## 8. 外层窗口如何使用键盘区尺寸

外层窗口在 [gui/main/layout/MainLayout.ahk](D:/06Code/DNFAutoFire/gui/main/layout/MainLayout.ahk) 里这样取：

- `GuiWidth() = MainKeyLayoutData.KeyboardWidth() + 32`
- `KeyPanelHeight() = MainKeyLayoutData.KeyboardHeight() + 22`

也就是说：

- 键盘本体宽高先由 `MainKeyLayoutData` 计算
- 主窗口再在这个基础上补外围留白
