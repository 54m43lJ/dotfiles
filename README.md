# dotfiles

Arch Linux 桌面环境自动化部署工具。Hyprland + Wayland。

## 前置条件

1. 安装 `sudo`，将用户加入 `wheel` 组。
2. 通过 `visudo` 添加免密码 sudo：
   ```
   %wheel ALL=(ALL:ALL) NOPASSWD: ALL
   ```
3. （可选）设置 `http_proxy` / `https_proxy` 环境变量，脚本会优先读取。如果未设置，运行时会提示输入。

## 使用

```bash
./main.sh          # 交互模式
./main.sh --yes    # 非交互模式（自动确认所有提示）
```

## 流程

1. 配置代理（从环境变量读取或提示输入）
2. 配置国内镜像源（pacman / rustup / cargo / go / npm）
3. 安装基础软件包（pacman）
4. 部署所有配置文件到 `~/.config/` 等路径
5. 安装 yay + AUR 包
6. 按需确认并安装可选模块：
   - Nvidia 驱动
   - 笔记本/台式机特定配置
   - HiDPI 显示缩放
   - OpenRGB 灯光控制
   - Breeze 主题
   - Eww 状态栏（源码编译）
   - 开发者环境（VSCode / Neovim）

## 配置

所有应用配置遵循 `conf.d/` 约定：主配置复制到 `~/.config/<app>/`，设备特定的配置通过符号链接放入 `conf.d/` 子目录按需激活。

## 文件结构

```
dotfiles/
├── main.sh                   # 入口
├── lib.sh                    # 共享工具函数
├── pkgs.sh                   # 所有包列表（数据）
├── deploy.sh                 # 基础配置部署
├── modules/                  # 可选模块（按需加载）
│   ├── nvidia.sh
│   ├── laptop.sh
│   ├── hidpi.sh
│   ├── rgb.sh
│   ├── breeze.sh
│   ├── eww.sh
│   └── dev.sh
├── fish/ foot/ hypr/ eww/ ... # 配置目录
└── suspend.sh
```
