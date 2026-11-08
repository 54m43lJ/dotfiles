# 登录界面数值规范（SDDM + hyprlock）

本文是 SDDM `sugar-dark` greeter 和 hyprlock 的共同布局契约。两个界面使用同一套
几何数值和配色，改版时先改本文，再同步两个实现：

- SDDM：`sddm/sugar-dark/Main.qml`、`Components/*.qml`、`theme.conf`
- hyprlock：`hypr/hyprlock.conf`

> 两个引擎的配置格式不同，无法让同一个文件直接被两边读取。本文是数值来源，
> 两边各自暴露了对应的命名变量/配置项；改动时必须成对更新。

## 1. 基准与缩放

- 设计基准：**1920x1080 逻辑像素**，原点在左上角，x 向右，y 向下。
- 所有百分比都相对输出逻辑尺寸；CSS 式百分比换算见各元素表格。
- **SDDM**
  - root 尺寸 = greeter 实际逻辑尺寸（`SizeRootObjectToView`）。
  - 基础字号：`P = max(1, trunc(H / 80))`，`H` 为逻辑高度。
  - 圆角缩放：`uiScale = H / 1080`，`cornerRadius = RoundCorners * uiScale`。
  - 4K 未开 HiDPI 时 `H=2160`、`P=27`，所有 px 尺寸约为 1080p 的 2 倍。
- **hyprlock**
  - `size` / `position` 的百分比相对输出逻辑尺寸。
  - `position` 的 y 是相对中心点的偏移，**正值向上**。
  - `font_size`、`rounding`、`outline_thickness`、`border_size` 使用 surface
    物理像素，不随 monitor scale 放大。当前数值按 **4K@2x** 调整；换 1x 输出时
    `font_size` 减半，圆角用 `-1` 不受影响。

## 2. 设计令牌

| 令牌 | 值 | 说明 |
| --- | --- | --- |
| 背景图 | `~/.config/hypr/graduation_dark.jpg` | 全屏，SDDM 用 `graduation2.jpg`（同图） |
| 面板底色 | `#444`，alpha `0.6` | 右侧 40% 半透明面板 |
| 主文字 | `#ffffff` | 时间、日期、用户名、会话 |
| 强调色 | `#ca33ac` | 密码框描边、输入校验 |
| 字体 | `Noto Sans` | 两个界面统一 |
| 图标字体 | `Noto Sans Nerd Font` | hyprlock 用户图标 `U+F007` |
| 字段形状 | 完整圆头（胶囊） | SDDM 用 `min(cornerRadius, h/2)`，hyprlock 用 `rounding = -1` |

## 3. 元素定位（1920x1080 逻辑坐标）

| 元素 | 尺寸 | 中心/锚点 | 字号/样式 | 备注 |
| --- | --- | --- | --- | --- |
| 背景 | 1920x1080 | 全屏 | — | 等比裁切填满 |
| 右侧面板 | 768x1080 | x `1152..1920`，`y 0..1080` | `#444` 60% | 无圆角 |
| 时间 | 文本 | `(1536, 196)` = `80%, 18.1%` | SDDM 39pt / hyprlock `$fsClock` | 24 小时制 |
| 日期 | 文本 | `(1536, 239)` = `80%, 22.1%` | SDDM 13pt / hyprlock `$fsText` | `dddd, d of MMMM` |
| 用户框 | 384x39~40 | `(1536, 501)` = `80%, 46.4%` | 白描边 1px、胶囊 | 仅装饰 |
| 用户图标 | 约 15~20px | 左缘 `71.5%`，垂直中心 `46.4%` | `$fsIcon` | `Noto Sans Nerd Font` |
| 用户名 | 文本 | `(1536, 501)` = `80%, 46.4%` | SDDM 13pt / hyprlock `$fsText` | SDDM 首字母大写 |
| 密码框 | 384x39~40 | `(1536, 559)` = `80%, 51.8%` | 强调色描边 2px、胶囊 | 唯一输入 |
| 提交箭头 | 约 31x31 | 右端 `x≈89%`，`y=51.8%` | `→`，SDDM 19.5pt / hyprlock `$fsText` | 点击提交/回车 |
| 会话标签 | 文本 | 左缘 `71.35%`，中心 `y=96.5%` | SDDM 11.7pt / hyprlock `$fsSmall` | `Session: Hyprland` |

界面上**没有**独立的 Login 按钮，也**没有** Welcome 标题。

## 4. SDDM 数值控制

默认值位于 `sddm/sugar-dark/theme.conf`，可在 `theme.conf.user` 覆盖。QML 中通过
`root.<property>` 读取，未配置时回退到括号内默认值。

| 键 | 当前值 | 单位 | 作用 |
| --- | --- | --- | --- |
| `FormWidthPercent` | 40 | 屏幕宽度 % | 右侧表单面板宽度 |
| `FieldWidthPercent` | 50 | 表单宽度 % | 用户名/密码框宽度（等于屏幕 20%） |
| `FieldRowFactor` | 4.5 | 基础字号倍数 | 每个输入行的行高 |
| `FieldHeightFactor` | 3 | 基础字号倍数 | 输入框可见高度 |
| `ClockSlotPercent` | 25 | 屏幕高度 % | 时钟所在的布局槽高 |
| `InputSlotPercent` | 10 | 屏幕高度 % | 输入区所在的布局槽高 |
| `SystemSlotPercent` | 25 | 屏幕高度 % | 电源按钮布局槽高 |
| `ArrowSizeFactor` | 0.8 | 输入框高度倍数 | 箭头按钮方框边长 |
| `ArrowMarginFactor` | 0.2 | 输入框高度倍数 | 箭头距输入框右缘 |
| `ArrowNudgeFactor` | 0.111 | 字号倍数 | 箭头视觉垂直微调 |
| `RoundCorners` | 30 | px @1080 | 圆角基准，按 `H/1080` 缩放 |

派生公式（`H` 根高度，`P` 基础字号，`W` 根宽度）：

```text
formWidth   = W * FormWidthPercent / 100
fieldWidth  = formWidth * FieldWidthPercent / 100
fieldHeight = P * FieldHeightFactor
radius      = min(RoundCorners * H / 1080, fieldHeight / 2)
arrowSize   = fieldHeight * ArrowSizeFactor
arrowMargin = fieldHeight * ArrowMarginFactor
arrowNudge  = P * ArrowNudgeFactor
```

垂直位置仍由 `ColumnLayout` 的槽高和内容高度推导，当前实测中心为：时间 18.1%、
日期 22.1%、用户名 46.4%、密码 51.8%、会话 96.5%。调 `*SlotPercent` 会整体移动
对应区块。

## 5. hyprlock 数值控制

全部集中在 `hypr/hyprlock.conf` 顶部。百分比相对输出；y 偏移正值向上。

| 变量 | 当前值 | 作用 |
| --- | --- | --- |
| `$panelW` | `40%` | 右侧面板宽度 |
| `$centerX` | `30%` | 面板中心 x（屏幕中心右移 30%） |
| `$fieldX` | `-10%` | 字段右缘距屏幕右缘（字段宽 20%） |
| `$fieldW` / `$fieldH` | `20%` / `3.7%` | 输入框尺寸 |
| `$timeY` | `32%` | 时间中心（`50-32=18%`） |
| `$dateY` | `28%` | 日期中心（`22%`） |
| `$userY` | `3.6%` | 用户框/用户名中心（`46.4%`） |
| `$passwordY` | `-1.8%` | 密码框中心（`51.8%`） |
| `$iconX` / `$iconY` | `71.5%` / `3.6%` | 用户图标左缘/垂直中心 |
| `$arrowX` / `$arrowY` | `-10.5%` / `-1.8%` | 箭头右缘/垂直中心 |
| `$sessionX` / `$sessionY` | `71.35%` / `-46.5%` | 会话标签左缘/中心（`96.5%`） |
| `$fsClock` | 76 | 时间字号（surface 值，4K@2x） |
| `$fsText` | 26 | 日期/用户名/密码/箭头字号 |
| `$fsSmall` | 23 | 会话标签字号 |
| `$fsIcon` | 16 | 用户图标字号 |

`rounding = -1` 表示完整圆头，不受 scale 影响；`outline_thickness = 2`、
`border_size = 1` 是 surface 像素。

## 6. 修改流程

1. 改本文的“元素定位”或“数值控制”表。
2. SDDM：改 `theme.conf`（默认）或 `theme.conf.user`（覆盖），重启 greeter。
3. hyprlock：改顶部变量，下次锁屏生效。
4. 两边都跑一遍预览，确认百分比和 px 的换算没有被字号截断影响。

## 7. 测试

```bash
# SDDM：直接跑，2x/HiDPI 下是清晰的；嵌套 cage 只用于隔离，会因缩放发糊
sddm-greeter-qt6 --test-mode --theme ~/Documents/dotfiles/sddm/sugar-dark

# hyprlock
hyprlock --no-fade-in
# 解锁：kill -USR1 "$(pidof hyprlock)"
```

## 8. 已知限制

SDDM 的垂直位置来自 `ColumnLayout`（`*SlotPercent` + 内容高度），不是每个元素
独立的绝对 y 值。当前表格记录的是布局推导后的实测中心；如果要求“每个元素都有
独立可调的绝对坐标”，需要把 `LoginForm.qml` 从 ColumnLayout 改成显式定位。
hyprlock 本身就是逐元素绝对定位，不受此限制。
