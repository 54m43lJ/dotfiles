-- ~/.config/hypr/monitor_control.lua
--
-- Monitor profiles with three match modes:
--
--   dual         connector + description  (most specific)
--   connector    connector only
--   description  description only
--
-- Priority is dual > connector > description.  Within the same mode the
-- last definition wins.  A profile only matches when its keys are exact:
-- no prefix matching, no wildcards.
--
-- Native Hyprland monitor rules are single-key:
--   output = "DP-2"            -> connector only
--   output = "desc:HKC ..."    -> description only (prefix match)
-- Neither can express "this exact panel on this exact port".  That matters
-- when one panel is wired twice (dGPU DP and dock HDMI) or when another
-- monitor is plugged into the same connector.
--
-- The description is Hyprland's short description, i.e. the "description"
-- field printed by `hyprctl monitors -j` / `mon.description` in Lua.
-- Hyprland strips commas from EDIDs; this module normalizes commas and
-- surrounding whitespace before comparing/storing.
--
-- Profile fields are the hl.monitor() fields (minus output) plus:
--   connector    optional non-empty connector name, e.g. "DP-2"
--   description  optional short description, e.g. "HKC ... 0000000000001"
-- At least one of connector/description is required.
-- Unknown fields are rejected so a typo cannot silently do nothing.
--
-- This module owns both the profile rules and the default layout for
-- unmanaged monitors.  Scale is intentionally optional: when omitted it is
-- inferred from the profile mode / available_modes (position auto-right,
-- 1x/2x height heuristic, reserved top=-5).  hyprland.lua no longer has a
-- separate scale pass.
--
-- Custom scripts that want to inspect or extend the concrete rule should
-- use resolve()/default_layout()/effective_scale() instead of calling
-- hl.monitor() with a bare field.

local M = {}

local RECORDS = {}
local KEYS = {}
local SEEN = {}

local DUAL = {}
local BY_CONNECTOR = {}
local BY_DESCRIPTION = {}

local META = {
    connector = true,
    description = true,
}

-- Keep in sync with HL.MonitorSpec (scripts/generateLuaStubs.py).
local ALLOWED = {
    bitdepth = true,
    cm = true,
    disabled = true,
    icc = true,
    max_avg_luminance = true,
    max_luminance = true,
    min_luminance = true,
    mirror = true,
    mode = true,
    position = true,
    reserved = true,
    reserved_area = true,
    scale = true,
    sdr_eotf = true,
    sdr_max_luminance = true,
    sdr_min_luminance = true,
    sdrbrightness = true,
    sdrsaturation = true,
    supports_hdr = true,
    supports_wide_color = true,
    transform = true,
    vrr = true,
}

-- require() re-executes this module on config reload (Hyprland clears
-- package.loaded), but hl.timer callbacks survive.  Cancel the previous
-- reload's one-shot VRR retries so they cannot re-apply a profile that the
-- new config removed.
if _G.__monitor_control_timers then
    for _, timer in ipairs(_G.__monitor_control_timers) do
        pcall(function() timer:set_enabled(false) end)
    end
end
local TIMERS = {}
_G.__monitor_control_timers = TIMERS

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize_description(description)
    if description == nil then
        return ""
    end
    return trim(tostring(description):gsub(",", ""))
end

local function profile_mode(profile)
    local has_connector   = profile.connector ~= nil
    local has_description = profile.description ~= nil

    if has_connector and has_description then
        return "dual"
    elseif has_connector then
        return "connector"
    else
        return "description"
    end
end

local function profile_key(mode, connector, description)
    if mode == "dual" then
        return "d\0" .. connector .. "\0" .. normalize_description(description)
    elseif mode == "connector" then
        return "c\0" .. connector
    else
        return "s\0" .. normalize_description(description)
    end
end

local function display_key(mode, connector, description)
    if mode == "dual" then
        return "dual|" .. connector .. "|" .. normalize_description(description)
    elseif mode == "connector" then
        return "connector|" .. connector
    else
        return "description|" .. normalize_description(description)
    end
end

local function real_monitors(all)
    local out = {}
    for _, mon in ipairs(hl.get_monitors(all and { all = true } or nil)) do
        if mon.name ~= "FALLBACK" then
            out[#out + 1] = mon
        end
    end
    return out
end

-- The height the profile's mode will most likely land on.  Hyprland picks
-- the actual mode, but mirroring its preference order here lets auto-scale
-- pick 2x when a highrr/highres profile moves a 1080p panel to 4K.  If the
-- mode table is unavailable (early config parse), fall back to the current
-- pixel height.
local function mode_height(mon, mode)
    if type(mode) ~= "string" or mode == "" then
        return mon.height
    end

    local height = mode:match("^%s*%d+%s*x%s*(%d+)")
    if height then
        return tonumber(height)
    end

    local modes = mon.available_modes
    if type(modes) ~= "table" or #modes == 0 then
        return mon.height
    end

    if mode:match("^pref") then
        for _, candidate in ipairs(modes) do
            if candidate.preferred then
                return candidate.height
            end
        end
        return mon.height
    end

    if mode ~= "highrr" and mode ~= "highres" and mode ~= "maxwidth" then
        -- Custom modeline or an unknown keyword: leave the heuristic to the
        -- current mode instead of guessing the first available mode.
        return mon.height
    end

    local best
    for _, candidate in ipairs(modes) do
        if candidate.width and candidate.height then
            if not best then
                best = candidate
            elseif mode == "highrr" then
                if candidate.refresh_rate > best.refresh_rate + 1
                    or (math.abs(candidate.refresh_rate - best.refresh_rate) <= 1
                        and candidate.width * candidate.height > best.width * best.height) then
                    best = candidate
                end
            elseif mode == "highres" then
                if candidate.width * candidate.height > best.width * best.height
                    or (candidate.width * candidate.height == best.width * best.height
                        and candidate.refresh_rate > best.refresh_rate) then
                    best = candidate
                end
            elseif mode == "maxwidth" then
                if candidate.width > best.width
                    or (candidate.width == best.width and candidate.refresh_rate > best.refresh_rate) then
                    best = candidate
                end
            end
        end
    end

    return best and best.height or mon.height
end

local function default_scale(mon, spec)
    local height = mode_height(mon, spec.mode) or mon.height
    return (height and height > 1080) and 2 or 1
end

-- Public: the auto-scale heuristic used when a profile omits `scale`.
function M.default_scale(mon, spec)
    return default_scale(mon, spec or {})
end

-- Public: layout fields a profile would get if it omitted them.  `spec` is
-- optional and may contain position/scale/reserved/reserved_area/mode.
-- Returns a table with position/scale and, only when the caller did not set
-- reserved/reserved_area, reserved.
function M.default_layout(mon, spec)
    spec = spec or {}

    local layout = {
        position = spec.position ~= nil and spec.position or "auto-right",
        scale    = spec.scale ~= nil and spec.scale or default_scale(mon, spec),
    }

    if spec.reserved == nil and spec.reserved_area == nil then
        layout.reserved = { top = -5 }
    end

    return layout
end

local function validate_profile(profile, index)
    if type(profile) ~= "table" then
        error(("monitor_control: profile #%d must be a table"):format(index), 0)
    end

    local has_connector   = profile.connector ~= nil
    local has_description = profile.description ~= nil

    if not has_connector and not has_description then
        error(("monitor_control: profile #%d: at least one of connector/description is required"):format(index), 0)
    end

    if has_connector and (type(profile.connector) ~= "string" or profile.connector == "") then
        error(("monitor_control: profile #%d: connector must be a non-empty string"):format(index), 0)
    end

    if has_description and type(profile.description) ~= "string" then
        error(("monitor_control: profile #%d: description must be a string"):format(index), 0)
    end

    for field in pairs(profile) do
        if not META[field] and not ALLOWED[field] then
            error(("monitor_control: profile #%d: unknown field '%s'"):format(index, tostring(field)), 0)
        end
    end

    if profile.reserved ~= nil and profile.reserved_area ~= nil then
        error(("monitor_control: profile #%d: use reserved or reserved_area, not both"):format(index), 0)
    end

    if profile.reserved ~= nil
        and type(profile.reserved) ~= "table"
        and type(profile.reserved) ~= "number" then
        error(("monitor_control: profile #%d: reserved must be a number or a CSS-gap table"):format(index), 0)
    end
end

-- define(profiles)
--   profiles: array of tables, or a single profile table.
--
--   { connector = "DP-2", description = "..." }  dual
--   { connector = "DP-2" }                       connector only
--   { description = "..." }                      description only
--
-- Defining the same key twice replaces the earlier entry; the last
-- definition wins within that mode.  A dual profile always beats a
-- connector-only or description-only profile for the same monitor.
--
-- The definitions are applied immediately so a rule created during config
-- parsing is visible to CConfigManager's ensureVRR() pass at the end of the
-- same reload.
function M.define(profiles)
    if type(profiles) ~= "table" then
        error("monitor_control: define() expects an array of profiles", 0)
    end

    -- Allow define({ connector = ..., ... }) for a single profile.  A table
    -- with keys but no array part is a single (possibly invalid) profile;
    -- wrap it so validate_profile() can report the missing keys instead of
    -- silently doing nothing.
    if profiles.connector ~= nil or profiles.description ~= nil
        or (#profiles == 0 and next(profiles) ~= nil) then
        profiles = { profiles }
    end

    local count = 0
    for index, profile in ipairs(profiles) do
        validate_profile(profile, index)

        local mode = profile_mode(profile)
        local key  = profile_key(mode, profile.connector, profile.description)

        if not SEEN[key] then
            SEEN[key] = true
            KEYS[#KEYS + 1] = key
        end

        RECORDS[key] = {
            mode        = mode,
            connector   = profile.connector,
            description = profile.description,
            profile     = profile,
        }

        if mode == "dual" then
            DUAL[profile.connector .. "\0" .. normalize_description(profile.description)] = profile
        elseif mode == "connector" then
            BY_CONNECTOR[profile.connector] = profile
        else
            BY_DESCRIPTION[normalize_description(profile.description)] = profile
        end

        count = count + 1
    end

    for _, mon in ipairs(real_monitors(true)) do
        M.apply_monitor(mon)
    end

    return count
end

-- match(monitor) -> profile | nil, mode | nil
--   Priority: dual > connector > description.
function M.match(mon)
    if not mon or not mon.name or mon.name == "FALLBACK" then
        return nil
    end

    local description = normalize_description(mon.description)

    local profile = DUAL[mon.name .. "\0" .. description]
    if profile then
        return profile, "dual"
    end

    profile = BY_CONNECTOR[mon.name]
    if profile then
        return profile, "connector"
    end

    profile = BY_DESCRIPTION[description]
    if profile then
        return profile, "description"
    end

    return nil
end

-- match_mode(monitor) -> "dual" | "connector" | "description" | nil
function M.match_mode(mon)
    local _, mode = M.match(mon)
    return mode
end

-- is_managed(monitor) -> boolean
function M.is_managed(mon)
    return M.match(mon) ~= nil
end

-- key(connector, description) -> stable diagnostic key
function M.key(connector, description)
    if connector ~= nil and description ~= nil then
        return display_key("dual", connector, description)
    elseif connector ~= nil then
        return display_key("connector", connector)
    else
        return display_key("description", nil, description)
    end
end

-- resolve(monitor, profile) -> concrete hl.monitor() spec
--   Useful for custom scripts that want to tweak one field without losing
--   the profile's mode/scale/VRR/layout.  Returns nil for FALLBACK.
function M.resolve(mon, profile)
    if not mon or not mon.name or not profile or mon.name == "FALLBACK" then
        return nil
    end

    local spec = {}
    for field, value in pairs(profile) do
        if not META[field] then
            spec[field] = value
        end
    end

    spec.output = mon.name

    for field, value in pairs(M.default_layout(mon, spec)) do
        spec[field] = value
    end

    return spec
end

-- effective_scale(monitor, profile) -> number|string|nil
function M.effective_scale(mon, profile)
    local spec = M.resolve(mon, profile)
    return spec and spec.scale or nil
end

-- apply(monitor, profile, retry)
--   retry defaults to true.  hl.monitor() schedules a monitor-state refresh,
--   but the refresh can run before ensureMonitorStatus() applies the new
--   rule; ensureVRR() then sees the old rule and VRR never changes.  A
--   one-shot re-apply after the first reload makes the follow-up refresh
--   evaluate VRR against the now-active rule.  The retry re-apply itself
--   must not schedule another retry.
local RETRY_MS = 250

function M.apply(mon, profile, retry)
    local spec = M.resolve(mon, profile)
    if not spec then
        return false
    end

    hl.monitor(spec)

    if retry ~= false then
        local name        = mon.name
        local description = mon.description
        local timer = hl.timer(function()
            local current = hl.get_monitor(name)
            if not current or current.description ~= description then
                return
            end
            local match = M.match(current)
            if match then
                M.apply(current, match, false)
            end
        end, { timeout = RETRY_MS, type = "oneshot" })
        TIMERS[#TIMERS + 1] = timer
    end

    return true
end

-- apply_default(monitor)
--   Layout-only rule for monitors without a profile.  Keep the legacy
--   desc: rule key so a device-specific desc rule's mode/VRR stays
--   additive; scale comes from the same auto heuristic as profiles.
function M.apply_default(mon)
    if not mon or not mon.name or mon.name == "FALLBACK" then
        return false
    end

    local layout = M.default_layout(mon)
    local output = mon.description and ("desc:" .. mon.description) or mon.name

    hl.monitor({
        output   = output,
        position = layout.position,
        scale    = layout.scale,
        reserved = layout.reserved,
    })

    return true
end

-- apply_monitor(monitor) -> boolean
--   Profile if one matches, otherwise the auto-layout fallback for enabled
--   monitors.  Disabled unmanaged monitors are left alone.
function M.apply_monitor(mon)
    if not mon or not mon.name or mon.name == "FALLBACK" then
        return false
    end

    local profile = M.match(mon)
    if profile then
        return M.apply(mon, profile)
    end

    if mon.enabled then
        return M.apply_default(mon)
    end

    return false
end

-- apply_all()
function M.apply_all()
    local applied = 0
    -- all=true covers monitors kept disabled by a rule; re-applying their
    -- profile on config.reloaded keeps them disabled.
    for _, mon in ipairs(real_monitors(true)) do
        if M.apply_monitor(mon) then
            applied = applied + 1
        end
    end
    return applied
end

-- status() -> plain Lua table, useful from a keybind or a debug console.
function M.status()
    local profiles = {}
    for _, key in ipairs(KEYS) do
        local record = RECORDS[key]
        profiles[#profiles + 1] = {
            mode        = record.mode,
            connector   = record.connector,
            description = record.description ~= nil and normalize_description(record.description) or nil,
            key         = display_key(record.mode, record.connector, record.description),
        }
    end

    local monitors = {}
    for _, mon in ipairs(real_monitors(true)) do
        local profile, mode = M.match(mon)
        local scale = profile and M.effective_scale(mon, profile)
            or (mon.enabled and M.default_scale(mon, {}) or nil)

        monitors[#monitors + 1] = {
            name        = mon.name,
            description = mon.description,
            enabled     = mon.enabled,
            matched     = profile ~= nil,
            mode        = mode,
            key         = profile and display_key(mode, profile.connector, profile.description) or nil,
            scale       = scale,
        }
    end

    return {
        profiles = profiles,
        monitors = monitors,
    }
end

-- Keep per-monitor application self-contained.  hyprland.lua no longer has
-- a separate scale/layout pass; it only handles workspaces, wake recovery
-- and autostart.
hl.on("hyprland.start", function()
    M.apply_all()
end)

hl.on("monitor.added", function(mon)
    M.apply_monitor(mon)
end)

hl.on("config.reloaded", function()
    M.apply_all()
end)

return M
