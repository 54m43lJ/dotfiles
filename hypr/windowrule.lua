-- ~/.config/hypr/windowrule.lua
-- Window rules — always loaded by hyprland.lua

-- Workspace assignments
hl.window_rule({ name = "ws-codium",            match = { class = "^(codium)$" },                                    workspace = "emptym" })
hl.window_rule({ name = "ws-brave",             match = { class = "^([bB]rave-browser)$" },                          workspace = "emptym" })
hl.window_rule({ name = "ws-thunderbird",       match = { class = "^(thunderbird)$", title = ".*(Mozilla Thunderbird)$" }, workspace = "emptym" })
hl.window_rule({ name = "ws-spotify",           match = { title = "^(Spotify|Spotify Premium)$" },                   workspace = "10" })
hl.window_rule({ name = "ws-qqmusic",           match = { class = "^(qqmusic)$" },                                   workspace = "10" })
hl.window_rule({ name = "ws-obsidian",          match = { class = "^(obsidian)$" },                                  workspace = "9" })

-- Application rules
hl.window_rule({ name = "tile-wps",             match = { class = "^(wps|wpp|et|pdf|prometheus|wpsoffice)$" },       tile = true })
hl.window_rule({ name = "fs-mplayer",           match = { class = "^(MPlayer)$" },                                   fullscreen = true })

-- Float rules
hl.window_rule({ name = "float-xdg-portal",     match = { class = "^(xdg-desktop-portal-gtk)$" },                    float = true })
hl.window_rule({ name = "float-nemo",           match = { class = "^(nemo)$" },                                      float = true })
hl.window_rule({ name = "float-calculator",     match = { class = "^(galculator|org\\.gnome\\.Calculator)$" },        float = true })
hl.window_rule({ name = "float-clash",          match = { class = "^(clash-verge)$" },              float = true })
hl.window_rule({ name = "float-network",        match = { class = "^(nm-connection-editor)$" },                      float = true })
hl.window_rule({ name = "float-openrgb",        match = { class = "^(org.openrgb.OpenRGB)$" },                       float = true })
hl.window_rule({ name = "float-polkit",         match = { class = "polkit" },                                        float = true })
hl.window_rule({ name = "float-wechat",         match = { class = "wechat" },                                        float = true })
hl.window_rule({ name = "float-keepass",        match = { class = "^(org\\.keepassxc\\.KeePassXC)$" },                float = true })
hl.window_rule({ name = "float-fcitx5-config",  match = { class = "^(org.fcitx.fcitx5-config-qt)$" },                float = true })

-- Fullscreen rules
hl.window_rule({ name = "fs-qt5ct",             match = { class = "^(qt5ct)$" },                                     float = true })
hl.window_rule({ name = "fs-pavucontrol",       match = { class = "^(pavucontrol)$" },                               float = true })

-- xwayland workarounds
hl.window_rule({ name = "xwayland-fixes",       match = { xwayland = true }, opaque = true, no_blur = true, no_dim = true })
