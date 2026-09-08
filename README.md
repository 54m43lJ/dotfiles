# dotfiles

Arch Linux 桌面环境自动化部署工具。Hyprland + Wayland。

## 使用

```bash
./main.sh                  # 交互模式：空格勾选模块，Enter 执行，Esc 取消
./main.sh --yes            # 非交互模式（DEFAULTS 列表，当前为空）
./main.sh --dry-run        # 只打印将执行的模块，不做任何变更
./main.sh --verbose        # 打印所有命令输出（默认静默，只显示告警/报错）
```

## Module 规范

- **module**：一个目录，入口是 `module.sh`，对外只暴露一个 `install_module()` 接口。`main.sh` 经 `lib.sh` 的 `install_modules()` 按 `MODULES` 数组顺序调用。
- **bundle**：完全符合 module 规范的 module，实现是基于硬编码的列表调用其它模块（`install_modules a b c ...`），没有任何特殊约束，允许引用其它 bundle。
- **sub-module**：同样符合 module 规范，但存在于其它 module 目录内部，原则上（不加限制）只由直接上层 module 调用（如 `per-device-conf/<device>/module.sh`）。
- **flatten 语义**内建于 `install_modules`：以集合记录本次运行已到达的模块，重复引用只执行一次，环引用自然终止。

## 运行流程

1. 解析参数，`MODULES` 数组即全部可用模块（bundle 在最前，作为打包入口）
2. 交互式勾选或使用 `DEFAULTS`
3. 静默安装硬依赖：`git` / `base-devel`（编译 yay 所需），yay 缺失时从 AUR 构建；任何一步失败整个脚本退出
4. `install_modules` 按序执行选中模块

## 文件结构

```
dotfiles/
├── main.sh                   # 入口：参数解析、硬依赖引导、模块调度
├── lib.sh                    # 共享工具函数（日志、pacman/yay 封装、模块选择器、install_modules）
├── <module>/module.sh        # 每个模块一个目录，入口 module.sh
├── bundle-*/module.sh        # bundle：硬编码列表调用其它模块
├── per-device-conf/          # 设备子模块（pc_beijing/ pc_changsha/ macbookpro/ xiaomi_book/）
│   └── <device>/module.sh    # 子模组，由 per-device-conf 按选择调用
├── <app>/                    # 各应用配置目录（hypr/ foot/ fcitx5/ sddm/ ...）
└── TODO.md
```
