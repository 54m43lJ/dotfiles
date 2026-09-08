- [X] --help 打印 module 信息不应该写死
- [X] 改变互动方式，打印所有可用的 module，互动式的用空格 toggle 是否执行 module，enter 进入下一步，esc 取消执行退出脚本，硬编码的 module 列表当做默认值加载
- [X] 加入--dry-run模式方便开发debug，不执行任何的实际module
- [X] 用 wofi 替换 nwg-bar 的功能，SUPER+Q 应该打开一个特殊 wofi 菜单有各种电源选项
- [X] sddm需要一个极简theme不会因为更新崩掉
- [X] 脚本过程中静默 stdout 输出，只显示出错信息
- [X] fcitx 5 默认配置
	- [X] 加入 pinyin
	- [X] ctrl+space = toggle input method
	- [X] left shift = activate input method
	- [X] left shift = temporarily toggle input method
	- [X] activate input method by default = yes
	- [X] share input state = all
	- [X] default candidates per page = 7
	- [X] classic user interface => font = 14pt
	- [X] classic user interface => theme = breeze light blue
- [X] 拆分 electron-apps 模块：flags 归属各软件的安装模块
	- [X] brave-flags / electron-flags / obsidian user-flags → system 模块
	- [X] 新 vscode 模块：装 code（+AUR code-features/code-marketplace），部署 code-flags.conf
	- [X] argv.json 路径修正为 `~/.vscode/argv.json`，写入 `"password-store": "gnome-libsecret"`（已存在的键不覆盖）
	- [X] dev 模块 vscode 残留清理
- [X] bundle 机制：模块打包批量安装，减少选择次数
	- bundle = 纯数据 module 目录，只定义 `BUNDLE=(...)`，允许嵌套 bundle
	- 拍扁下沉 `lib/flatten.py`：集合去重 + 断环，bundle 本体不进安装清单；main.sh 启动静默强装 python，失败直接退出
	- main.sh/lib.sh 共用 `install_modules()`：拍扁 → 按首次出现序执行叶子
	- 初始三组：bundle-base（system pipewire）、bundle-desktop（嵌套 base + 桌面全家桶）、bundle-dev（vscode dev）
- [X] 修复 minimal 主题实机报错（默认 greeter 是 Qt5 链接的）
	- `import QtQuick 2.15`（Qt5 拒绝无版本导入；2.15 双引擎兼容）
	- `Screen.desktopAvailableHeight` → 根元素 `height`（Qt5 纯 QtQuick 导入下无 Screen 类型）
	- 注意：此类报错进 journald 不进 stderr；test-mode 验收要用两个二进制都跑（`sddm-greeter` = Qt5、`sddm-greeter-qt6` = Qt6）
- [X] yay与python一起作为安装必须依赖安装，失败直接退出脚本（含 `--verbose|-v` 全局输出开关）
- [ ] openrgb自启动和依赖安装
	- [ ] `i2c-tools`
	- [ ] 执行 `sudo sh -c "echo -e \"i2c-dev\ni2c-piix4\" > /etc/modules-load.d/i2c.conf"` 加载必要的 i2c 模组
	- [ ] 实现自动检测系统是 AMD 平台还是 intel 平台，在 intel 平台上用 `i2c-i801` 替代 `i2c-piix4`
- [ ] gnome-keyring初始化
	- 修改 `/etc/pam.d/login`
	- 找到 `auth` 部分，在**末尾**添加一行：
	```
	auth optional pam_gnome_keyring.so
	```
	- 找到 `session` 部分，在**末尾**添加一行：
    ```
    session optional pam_gnome_keyring.so auto_start
    ```
	- 配置 hyprland `hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")`
	- `systemctl --user enable gcr-ssh-agent --now` 启动 ssh agent
- [ ] 重新开发一个兼容qt6的SDDM主题
    - [ ] 带动画效果
    - [ ] 细节待讨论，讨论完再实现
- [ ] sddm 主题自动降级机制（pacman hook + theme-check.sh）
	- theme-check.sh：按优先级顺序（好看主题 → minimal）offscreen 实测，`QT_QPA_PLATFORM=offscreen timeout 15 sddm-greeter-qt6 --test-mode --theme <dir>`，日志 grep 到 `Fallback to embedded theme` / QML error 才判死（避免误杀）
	- 第一个通过的主题写回 `Current=`，修好主题后升级时自动切回（自愈）
	- theme-fallback.hook：Upgrade sddm / qt6-* 时 PostTransaction 触发
	- module.sh 负责安装两者；不做 systemd unit、不参与 boot 路径
- [ ] hyprland在从suspend恢复后（包括hyprlock）会有坏点一样的像素，用hyprctl reload重载以后就没事了，需要调查原因
- [ ] fcitx5 删除 Simplified and Traditional Chinese Translation => Toggle Key 绑定
- [ ] 强制安装 pipewire-jack 替换 jack2