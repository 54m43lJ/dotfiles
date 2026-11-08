# 登录界面数值规范（SDDM + hyprlock）

本文是 SDDM `sugar-dark` greeter 和 hyprlock 的**唯一数值来源**。这里只定义一套
共享数值和标准单位；两个组件各自把这些值换算成自己的配置文件。

## 1. 标准单位

- **画布**：1920×1080 设计画布。
- **几何位置/尺寸**：百分比（`%`），相对画布宽/高。组件直接把它当作相对实际输出
  逻辑尺寸的锚点。
- **字号**：`pt`，指 1080p 画布下的目标字号。
- **细节尺寸**：`U`，指 1080p 画布下的逻辑像素（描边、圆角、图标框等）。
- 除特别注明外，本文不写某个组件的实际配置值；组件自行取整和换算。

通用缩放规则（逻辑单位）：

```text
logicalScale = output_logical_height / 1080
pt           -> pt * logicalScale
U            -> U * logicalScale
```

百分比本身已经是相对的，不乘 `logicalScale`。高宽比变化时，x 方向百分比相对宽度、
y 方向百分比相对高度。hyprlock 的配置使用 surface 像素，换算时改用
`surfaceScale = output_physical_height / 1080 = logicalScale * monitorScale`。

## 2. 设计令牌

| 令牌 | 值 |
| --- | --- |
| 背景图 | `~/.config/hypr/graduation_dark.jpg`（SDDM 侧为同图的 `graduation2.jpg`） |
| 面板底色 | `#444`，alpha `0.6` |
| 主文字 | `#ffffff` |
| 强调色 | `#ca33ac` |
| 字体 | `Noto Sans` |
| 图标字体 | `Noto Sans Nerd Font`，用户图标 `U+F007` |
| 胶囊 | 完整圆头；半径 = 高度的一半 |

## 3. 共享布局数值

坐标为中心点（除非写“左缘”），单位见上。画布 1920×1080。

| 元素 | 锚点 | 位置 | 尺寸 | 字号 | 细节 |
| --- | --- | --- | --- | --- | --- |
| 背景 | 全屏 | — | 100% × 100% | — | 等比裁切填满 |
| 右侧面板 | 右缘 | x 60%–100%，y 0–100% | 40% × 100% | — | `#444` 60%，无圆角 |
| 时间 | 面板中心 | (80%, 18.1%) | — | 38pt | `HH:mm`，24 小时制 |
| 日期 | 面板中心 | (80%, 22.1%) | — | 13pt | `dddd, d of MMMM` |
| 用户框 | 面板中心 | (80%, 46.4%) | 20% × 3.7% | — | 白描边 1U，胶囊，透明底 |
| 用户图标 | 用户框左侧 | (72%, 46.4%) | 16U × 16U | — | 白色 |
| 用户名 | 面板中心 | (80%, 46.4%) | — | 13pt | 白色 |
| 密码框 | 面板中心 | (80%, 51.8%) | 20% × 3.7% | — | 强调色描边 2U，胶囊，透明底 |
| 提交箭头 | 密码框右端 | (89%, 51.8%) | 约 23U × 12U | 19.5pt | `→`，点击提交 |
| 会话标签 | 面板左下 | 左缘 71.35%，中心 y 96.5% | — | 11.5pt | `Session: <桌面>` |

界面上没有独立的 Login 按钮，也没有 Welcome 标题。

## 4. 组件推导指导

这里只讲换算方法，不重复上面的数值。

### SDDM

- 百分比直接用于锚点和宽高比例；面板右缘对齐屏幕右缘。
- 基础正文 13pt 是参照值，实际字号按根高度取整：
  `base = max(1, trunc(root.height / 80))`。
- `U` 细节按 `root.height / 1080` 缩放；圆角再按 `height / 2` 夹紧成胶囊。
- 垂直位置由表单的 `ColumnLayout` 槽高和内容高度推导；上表的中心点是目标值，
  实现时用槽高和间距逼近它。
- 输入框、箭头、图标等组件内部字号/尺寸都由上表的 `pt`/`U` 推导，不在本文另列。

### hyprlock

- hyprlock 的 `position` 是相对中心的偏移，且 **y 正方向向上**：
  ```text
  position_x = center_x - 50%
  position_y = 50% - center_y
  ```
- `size` 直接使用上表的百分比。
- `font_size` 和 `U` 细节使用 surface 像素，按 `surfaceScale` 换算：4K@2x 下为 2，
  1080p@1x 下为 1。
- 胶囊用 `rounding = -1`；描边/边框按 `U * surfaceScale` 推导。
- 图标是字体字形，选一个字号让字形视觉高度接近 16U 即可。

## 5. 实现入口

- SDDM：`sddm/sugar-dark/theme.conf` 暴露换算后的比例/系数，`Main.qml`、
  `Components/*.qml` 消费它们。
- hyprlock：`hypr/hyprlock.conf` 顶部的命名变量。
- 两边都从本文推导；改数值时先改本文，再按上面的换算更新各自的实现。

## 6. 测试

```bash
# SDDM：直接跑，HiDPI 下清晰；嵌套 cage 会因缩放发糊
sddm-greeter-qt6 --test-mode --theme ~/Documents/dotfiles/sddm/sugar-dark

# hyprlock
hyprlock --no-fade-in
# 解锁：kill -USR1 "$(pidof hyprlock)"
```

## 7. 已知限制

- SDDM 的纵向位置由 `ColumnLayout` 推导，不是每个元素独立的绝对 y 坐标；本文给出
  的是目标中心点。若要求逐元素绝对定位，需要把 `LoginForm.qml` 改成显式定位。
- 两个组件没有共享的机器可读配置文件；本文是人工维护的单一来源。若以后需要自动
  生成两边配置，可以再加一层从本文表格到配置的生成脚本。
