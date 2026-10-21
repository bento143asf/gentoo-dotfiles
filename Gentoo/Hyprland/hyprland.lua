local function try(label, fn)
    local ok, err = pcall(fn)
    if not ok then
        hl.print("[hyprland.lua] " .. label .. " falhou: " .. tostring(err))
    end
end

local failed = {}

local function opt(path, value)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end
    local tbl = value
    for i = #parts, 1, -1 do
        tbl = { [parts[i]] = tbl }
    end
    local ok, err = pcall(hl.config, tbl)
    if not ok then
        failed[#failed + 1] = path
        hl.print("[hyprland.lua] opção '" .. path .. "' ignorada: " .. tostring(err))
    end
end

local function bind(keys, action, opts)
    local ok, err = pcall(hl.bind, keys, action, opts)
    if not ok then
        hl.print("[hyprland.lua] atalho '" .. keys .. "' falhou: " .. tostring(err))
    end
end

local function if_installed(bins, cmd)
    local checks = {}
    for _, b in ipairs(bins) do
        checks[#checks + 1] = "command -v " .. b .. " >/dev/null 2>&1"
    end
    return table.concat(checks, " && ") .. " && " .. cmd
end

local function rgba(hex, alpha)
    return "rgba(" .. hex .. alpha .. ")"
end

local function starts_with_any(text, prefixes)
    for _, p in ipairs(prefixes) do
        if text:sub(1, #p) == p then
            return true
        end
    end
    return false
end

local function round(n)
    return math.floor(n + 0.5)
end

local ok_home, home_env = pcall(function() return os.getenv("HOME") end)
local HOME = (ok_home and home_env) or "/home/et"
local SCRIPTS = HOME .. "/.config/hypr/scripts"

local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "dolphin"
local browser     = "firefox"
local launcher    = "rofi -show drun"

local MONITOR = "DP-1"

local GAPS_INNER  = 10
local GAPS_OUTER  = 25
local BORDER_SIZE = 2
local ROUNDING    = 0
local BORDER_SPIN = true

local VOLUME_STEP  = "5%"
local VOLUME_LIMIT = "1.0"

local CURSOR_THEME = "Vanilla-DMZ"
local CURSOR_SIZE  = 24

local C = {
    accent     = "B5B0E8",
    accent_alt = "E5B9F4",
    inactive_a = "AAA5D8",
    inactive_b = "958ECA",
    shadow     = "0b0a14",
}

hl.env("XCURSOR_THEME", CURSOR_THEME)
hl.env("XCURSOR_SIZE", tostring(CURSOR_SIZE))
hl.env("XCURSOR_PATH", table.concat({
    "/usr/share/cursors/xorg-x11",
    "/usr/share/icons",
    HOME .. "/.local/share/icons",
    HOME .. "/.icons",
    "/usr/share/pixmaps",
}, ":"))
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

local MONITOR_RULE = {
    output   = MONITOR,
    mode     = "highrr",
    position = "0x0",
    scale    = "1",
}
hl.monitor(MONITOR_RULE)

local function report_failures()
    if #failed == 0 then
        return
    end
    pcall(hl.notification.create, {
        text = "Opções ignoradas: " .. table.concat(failed, ", "),
        duration = 6000,
        icon = "warning",
    })
end

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor " .. CURSOR_THEME .. " " .. CURSOR_SIZE)
    hl.exec_cmd("bash " .. SCRIPTS .. "/wallpaper.sh init; exec hyprpaper")
    hl.exec_cmd("wpctl set-volume -l " .. VOLUME_LIMIT .. " @DEFAULT_AUDIO_SINK@ 50%")
    hl.exec_cmd(if_installed({ "cliphist", "wl-paste" }, "wl-paste --type text --watch cliphist store"))
    hl.exec_cmd(if_installed({ "cliphist", "wl-paste" }, "wl-paste --type image --watch cliphist store"))
    report_failures()
end)

hl.config({
    general = {
        gaps_in     = GAPS_INNER,
        gaps_out    = GAPS_OUTER,
        border_size = BORDER_SIZE,
        layout      = "dwindle",

        col = {
            active_border = {
                colors = { rgba(C.accent_alt, "ff"), rgba(C.accent, "ff") },
                angle  = 45,
            },
            inactive_border = {
                colors = { rgba(C.inactive_a, "55"), rgba(C.inactive_b, "55") },
                angle  = 90,
            },
            nogroup_border_active = {
                colors = { rgba(C.accent_alt, "ff"), rgba(C.accent, "ff") },
                angle  = 45,
            },
            nogroup_border = {
                colors = { rgba(C.inactive_a, "55"), rgba(C.inactive_b, "55") },
                angle  = 45,
            },
        },

        no_focus_fallback = true,
        resize_on_border  = true,
    },

    decoration = {
        rounding = ROUNDING,

        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.12,
        dim_special  = 0.2,
        dim_around   = 0.4,

        blur = {
            enabled            = true,
            size               = 9,
            passes             = 3,
            ignore_opacity     = true,
            new_optimizations  = true,
            xray               = false,
            noise              = 0.02,
            special            = true,
            popups             = true,
            popups_ignorealpha = 0.2,
        },

        shadow = {
            enabled        = true,
            range          = 28,
            render_power   = 3,
            sharp          = false,
            color          = rgba(C.shadow, "99"),
            color_inactive = rgba(C.shadow, "55"),
            scale          = 1.0,
        },
    },

    animations = {
        enabled              = true,
        workspace_wraparound = false,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },

    input = {
        kb_layout  = "br",
        kb_model   = "abnt2",
        kb_variant = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,
    },
})

opt("decoration.blur.vibrancy", 0.17)
opt("decoration.blur.contrast", 0.95)
opt("misc.mouse_move_enables_dpms", true)
opt("misc.key_press_enables_dpms", true)
opt("misc.animate_manual_resizes", true)
opt("misc.animate_mouse_windowdragging", true)
opt("input.repeat_rate", 35)
opt("input.repeat_delay", 250)
opt("input.numlock_by_default", true)
opt("input.accel_profile", "flat")
opt("cursor.hide_on_key_press", true)
opt("ecosystem.no_update_news", true)
opt("ecosystem.no_donation_nag", true)

hl.curve("jellySpring",      { type = "bezier", points = { { 0.25,  1.4   }, { 0.42, 1    } } })
hl.curve("jellyInContained", { type = "bezier", points = { { 0.175, 0.885 }, { 0.32, 1.15 } } })
hl.curve("smoothJelly",      { type = "bezier", points = { { 0.34,  1.25  }, { 0.64, 1    } } })
hl.curve("subtleJelly",      { type = "bezier", points = { { 0.16,  1     }, { 0.28, 1.04 } } })
hl.curve("softGlide",        { type = "bezier", points = { { 0.25,  1     }, { 0.5,  1    } } })
hl.curve("fastExit",         { type = "bezier", points = { { 0.32,  0     }, { 0.67, 0    } } })
hl.curve("linear",           { type = "bezier", points = { { 0,     0     }, { 1,    1    } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6.0, bezier = "jellySpring" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5.8, bezier = "jellyInContained", style = "popin 65%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4.5, bezier = "fastExit",         style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5.4, bezier = "subtleJelly" })

hl.animation({ leaf = "layers",    enabled = true, speed = 6.0, bezier = "jellySpring",      style = "popin 75%" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 5.5, bezier = "jellyInContained", style = "popin 75%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4.2, bezier = "fastExit",         style = "popin 75%" })

hl.animation({ leaf = "fade",          enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 4.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeLayers",    enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 5.0, bezier = "softGlide" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 4.0, bezier = "softGlide" })

hl.animation({ leaf = "border", enabled = true, speed = 6.0, bezier = "softGlide" })
if BORDER_SPIN then
    hl.animation({ leaf = "borderangle", enabled = true, speed = 90.0, bezier = "linear", style = "loop" })
else
    hl.animation({ leaf = "borderangle", enabled = true, speed = 16.0, bezier = "linear" })
end

hl.animation({ leaf = "workspaces",          enabled = true, speed = 6.5, bezier = "softGlide", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn",        enabled = true, speed = 6.5, bezier = "softGlide", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut",       enabled = true, speed = 6.5, bezier = "softGlide", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 6.5, bezier = "softGlide", style = "slidefadevert 15%" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 6.5, bezier = "softGlide", style = "slidefadevert 15%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 6.5, bezier = "softGlide", style = "slidefadevert 15%" })

hl.animation({ leaf = "zoomFactor",   enabled = true, speed = 5.5, bezier = "smoothJelly" })
hl.animation({ leaf = "monitorAdded", enabled = true, speed = 5.8, bezier = "jellyInContained" })

hl.window_rule({
    name    = "kitty-translucido",
    match   = { class = "^(kitty)$" },
    opacity = "0.92 0.80",
})

hl.window_rule({
    name       = "janelas-flutuantes",
    match      = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|qt6ct|xdg-desktop-portal-gtk|org.kde.polkit-kde-authentication-agent-1)$" },
    float      = true,
    center     = true,
    dim_around = true,
})

hl.window_rule({
    name         = "nao-dormir-em-tela-cheia",
    match        = { class = ".*" },
    idle_inhibit = "fullscreen",
})

try("regras de camada", function()
    hl.layer_rule({
        name         = "blur-shell",
        match        = { namespace = "^(rofi|quickshell-.*)$" },
        blur         = true,
        ignore_alpha = 0.3,
    })
end)

try("regras de workspace", function()
    hl.workspace_rule({ workspace = "1", default = true, persistent = true })
    for i = 2, 9 do
        hl.workspace_rule({ workspace = tostring(i), persistent = true })
    end
    hl.workspace_rule({ workspace = "special:scratch", on_created_empty = terminal })
end)

local canvas_api = {
    toggle   = function() end,
    shuffle  = function() end,
    zoom_out = function() end,
    zoom_in  = function() end,
    leave    = function() end,
    recover  = function() end,
}

local drag_handle = hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

try("workspace infinita", function()
    local WS       = "infinito"
    local WS_SEL   = "name:" .. WS
    local LEVELS   = { 1.0, 0.8, 0.64, 0.5, 0.4, 0.32, 0.25 }
    local CELL_GAP = 60
    local PAN_TICK = 16
    local PAN_IDLE = 2500
    local DEBOUNCE = 70

    local state = {
        active  = false,
        busy    = false,
        level   = 1,
        target  = 1,
        ox      = 0,
        oy      = 0,
        total_w = 0,
        total_h = 0,
        cell_w  = 0,
        cell_h  = 0,
        sized_k = nil,
        items   = {},
        origin  = nil,
        pan     = nil,
        timer   = nil,
        warned  = false,
    }

    local function monitor()
        return hl.get_active_monitor()
    end

    local function actual_scale()
        local s = tonumber(monitor().scale)
        if s and s > 0 then
            return s
        end
        return 1
    end

    local function set_scale(s)
        if math.abs(actual_scale() - s) < 0.001 then
            return actual_scale()
        end
        local rule = {}
        for k, v in pairs(MONITOR_RULE) do
            rule[k] = v
        end
        rule.scale = tostring(s)
        local ok, err = pcall(hl.monitor, rule)
        if not ok then
            hl.print("[hyprland.lua] escala do monitor falhou: " .. tostring(err))
        end
        return actual_scale()
    end

    local function viewport(scale)
        local m = monitor()
        local r = m.reserved or {}
        local left, top = r.left or 0, r.top or 0
        local right, bottom = r.right or 0, r.bottom or 0
        local mx, my = m.x or 0, m.y or 0
        local x0 = mx + left + GAPS_OUTER
        local y0 = my + top + GAPS_OUTER
        local lw, lh = m.width / scale, m.height / scale
        local w = lw - left - right - 2 * GAPS_OUTER
        local h = lh - top - bottom - 2 * GAPS_OUTER
        return { w = w, h = h, cx = x0 + w / 2, cy = y0 + h / 2, mx = mx, my = my, lw = lw, lh = lh }
    end

    local function ws_selector(ws)
        local name = ws.name or tostring(ws.id)
        if tonumber(name) then
            return name
        end
        return "name:" .. name
    end

    local function win_by_address(address)
        local ok, w = pcall(hl.get_window, "address:" .. address)
        if ok then
            return w
        end
        return nil
    end

    local function clamp_view()
        local mx = state.cell_w * 0.5
        local my = state.cell_h * 0.5
        state.ox = math.max(-mx, math.min(state.total_w + mx, state.ox))
        state.oy = math.max(-my, math.min(state.total_h + my, state.oy))
    end

    local function render()
        local scale = actual_scale()
        local v = viewport(scale)
        local k = LEVELS[state.level] / scale
        local resize = state.sized_k == nil or math.abs(state.sized_k - k) > 0.0001
        for _, item in ipairs(state.items) do
            local win = win_by_address(item.address)
            if win then
                local w, h = item.vw * k, item.vh * k
                local x = v.cx + (item.vx + item.vw / 2 - state.ox) * k - w / 2
                local y = v.cy + (item.vy + item.vh / 2 - state.oy) * k - h / 2
                if resize then
                    hl.dispatch(hl.dsp.window.resize({ x = round(w), y = round(h), relative = false, window = win }))
                end
                hl.dispatch(hl.dsp.window.move({ x = round(x), y = round(y), relative = false, window = win }))
            end
        end
        state.sized_k = k
    end

    local function animations(enabled)
        pcall(function()
            hl.animation({ leaf = "windows",     enabled = enabled, speed = 6.0, bezier = "jellySpring" })
            hl.animation({ leaf = "windowsMove", enabled = enabled, speed = 5.4, bezier = "subtleJelly" })
        end)
    end

    local function stop_pan()
        local pan = state.pan
        if not pan then
            return
        end
        state.pan = nil
        pcall(function() pan.timer:cancel() end)
        animations(true)
    end

    local function start_pan()
        if not state.active or state.busy or state.pan then
            return
        end
        local p = hl.get_cursor_pos()
        if not p then
            return
        end
        local pan = { x = p.x, y = p.y, idle = 0 }
        state.pan = pan
        animations(false)
        pan.timer = hl.timer(function()
            if state.pan ~= pan or not state.active then
                return
            end
            local ok = pcall(function()
                local c = hl.get_cursor_pos()
                local dx, dy = c.x - pan.x, c.y - pan.y
                if dx ~= 0 or dy ~= 0 then
                    local k = LEVELS[state.level] / actual_scale()
                    pan.x, pan.y, pan.idle = c.x, c.y, 0
                    state.ox = state.ox - dx / k
                    state.oy = state.oy - dy / k
                    clamp_view()
                    render()
                else
                    pan.idle = pan.idle + PAN_TICK
                    if pan.idle >= PAN_IDLE then
                        stop_pan()
                    end
                end
            end)
            if not ok then
                stop_pan()
            end
        end, { timeout = PAN_TICK, type = "repeat" })
    end

    local pan_press, pan_release, esc_bind

    local function set_canvas_binds(on)
        pcall(function() pan_press:set_enabled(on) end)
        pcall(function() pan_release:set_enabled(on) end)
        pcall(function() esc_bind:set_enabled(on) end)
        pcall(function() drag_handle:set_enabled(not on) end)
    end

    local function collect()
        local list = {}
        local active = hl.get_active_window()
        for _, w in ipairs(hl.get_windows({})) do
            local ws = w.workspace
            if ws and not ws.special then
                if active and w.address == active.address then
                    table.insert(list, 1, w)
                else
                    list[#list + 1] = w
                end
            end
        end
        return list, active
    end

    local function enter()
        local list, active = collect()
        if #list == 0 then
            return false
        end
        state.busy = true
        set_scale(1)
        local v = viewport(1)
        local n = #list
        local cols = math.ceil(math.sqrt(n))
        local rows = math.ceil(n / cols)
        local px = v.w + CELL_GAP
        local py = v.h + CELL_GAP

        state.items = {}
        state.origin = ws_selector((active and active.workspace) or list[1].workspace)
        for i, w in ipairs(list) do
            local c = (i - 1) % cols
            local r = math.floor((i - 1) / cols)
            state.items[i] = {
                address   = w.address,
                workspace = ws_selector(w.workspace),
                floating  = w.floating and true or false,
                at        = { x = w.at and w.at.x or 0, y = w.at and w.at.y or 0 },
                size      = { x = w.size and w.size.x or 0, y = w.size and w.size.y or 0 },
                vx = c * px, vy = r * py, vw = v.w, vh = v.h,
            }
        end

        for _, w in ipairs(list) do
            hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
            hl.dispatch(hl.dsp.window.move({ workspace = WS_SEL, follow = false, window = w }))
        end

        state.cell_w, state.cell_h = v.w, v.h
        state.total_w = cols * px - CELL_GAP
        state.total_h = rows * py - CELL_GAP
        state.active = true
        state.level = 1
        state.target = 1
        state.sized_k = nil
        state.ox = v.w / 2
        state.oy = v.h / 2

        set_canvas_binds(true)
        hl.dispatch(hl.dsp.focus({ workspace = WS_SEL }))
        if active then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. active.address }))
        end
        render()
        state.busy = false
        return true
    end

    local function item_at_cursor()
        local p = hl.get_cursor_pos()
        if not p then
            return state.items[1]
        end
        local scale = actual_scale()
        local v = viewport(scale)
        local k = LEVELS[state.level] / scale
        local x = state.ox + (p.x - v.cx) / k
        local y = state.oy + (p.y - v.cy) / k
        for _, item in ipairs(state.items) do
            if x >= item.vx and x <= item.vx + item.vw and y >= item.vy and y <= item.vy + item.vh then
                return item
            end
        end
        return state.items[1]
    end

    local function leave()
        if not state.active then
            return
        end
        state.busy = true
        set_canvas_binds(false)
        stop_pan()
        if state.timer then
            pcall(function() state.timer:cancel() end)
            state.timer = nil
        end
        local target = item_at_cursor()
        local known = {}
        for _, item in ipairs(state.items) do
            known[item.address] = true
        end
        state.active = false
        set_scale(1)

        for _, item in ipairs(state.items) do
            local win = win_by_address(item.address)
            if win then
                hl.dispatch(hl.dsp.window.move({ workspace = item.workspace, follow = false, window = win }))
                if item.floating then
                    hl.dispatch(hl.dsp.window.resize({ x = item.size.x, y = item.size.y, relative = false, window = win }))
                    hl.dispatch(hl.dsp.window.move({ x = item.at.x, y = item.at.y, relative = false, window = win }))
                else
                    hl.dispatch(hl.dsp.window.float({ action = "unset", window = win }))
                end
            end
        end

        for _, w in ipairs(hl.get_windows({})) do
            if w.workspace and w.workspace.name == WS and not known[w.address] then
                hl.dispatch(hl.dsp.window.move({ workspace = state.origin, follow = false, window = w }))
            end
        end

        local dest = (target and target.workspace) or state.origin
        state.items = {}
        state.level = 1
        state.target = 1
        if dest then
            hl.dispatch(hl.dsp.focus({ workspace = dest }))
        end
        if target then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
        end
        state.busy = false
    end

    local function apply_level(idx, centered)
        local old_scale = actual_scale()
        local vo = viewport(old_scale)
        local k_old = LEVELS[state.level] / old_scale
        local p = hl.get_cursor_pos() or { x = vo.cx, y = vo.cy }
        local fx = (p.x - vo.mx) / vo.lw
        local fy = (p.y - vo.my) / vo.lh
        local vpx = state.ox + (p.x - vo.cx) / k_old
        local vpy = state.oy + (p.y - vo.cy) / k_old

        state.level = idx
        local new_scale = set_scale(LEVELS[idx])
        if math.abs(new_scale - LEVELS[idx]) > 0.01 and not state.warned then
            state.warned = true
            pcall(hl.notification.create, {
                text = "O monitor não aceitou escala menor que 1: o zoom vai encolher as janelas",
                duration = 5000,
                icon = "warning",
            })
        end

        if not centered then
            local vn = viewport(new_scale)
            local k_new = LEVELS[idx] / new_scale
            local px = vn.mx + fx * vn.lw
            local py = vn.my + fy * vn.lh
            state.ox = vpx - (px - vn.cx) / k_new
            state.oy = vpy - (py - vn.cy) / k_new
        end
        clamp_view()
        render()
    end

    local function schedule_apply()
        if state.timer then
            pcall(function() state.timer:cancel() end)
        end
        state.timer = hl.timer(function()
            state.timer = nil
            if not state.active then
                return
            end
            if state.target <= 1 then
                leave()
            elseif state.target ~= state.level then
                apply_level(state.target, false)
            end
        end, { timeout = DEBOUNCE, type = "oneshot" })
    end

    local function request(delta)
        if state.busy then
            return
        end
        if not state.active then
            if delta < 0 or not enter() then
                return
            end
        end
        state.target = math.max(1, math.min(#LEVELS, state.target + delta))
        schedule_apply()
    end

    local function shuffle()
        if not state.active or state.busy then
            return
        end
        local n = #state.items
        if n < 2 then
            return
        end
        local slots = {}
        for i, item in ipairs(state.items) do
            slots[i] = { x = item.vx, y = item.vy }
        end
        for i = n, 2, -1 do
            local j = math.random(1, i - 1)
            slots[i], slots[j] = slots[j], slots[i]
        end
        for i, item in ipairs(state.items) do
            item.vx, item.vy = slots[i].x, slots[i].y
        end
        render()
    end

    local function toggle()
        if state.busy then
            return
        end
        if state.active then
            leave()
            return
        end
        if not enter() then
            return
        end
        local scale_x = state.total_w > 0 and (viewport(1).w / state.total_w) or 1
        local scale_y = state.total_h > 0 and (viewport(1).h / state.total_h) or 1
        local fit = math.min(scale_x, scale_y)
        local idx = 1
        for i, s in ipairs(LEVELS) do
            idx = i
            if s <= fit then
                break
            end
        end
        state.ox = state.total_w / 2
        state.oy = state.total_h / 2
        state.target = idx
        if idx > 1 then
            apply_level(idx, true)
        end
    end

    local function recover()
        if state.active then
            return
        end
        for _, w in ipairs(hl.get_windows({})) do
            if w.workspace and w.workspace.name == WS then
                hl.dispatch(hl.dsp.window.move({ workspace = "1", follow = false, window = w }))
                hl.dispatch(hl.dsp.window.float({ action = "unset", window = w }))
            end
        end
    end

    pcall(function()
        pan_press   = hl.bind(mainMod .. " + mouse:272", start_pan)
        pan_release = hl.bind(mainMod .. " + mouse:272", stop_pan, { release = true })
        esc_bind    = hl.bind("Escape", leave, { non_consuming = true })
    end)
    set_canvas_binds(false)

    hl.on("workspace.active", function(ws)
        if state.active and not state.busy and ws and ws.name ~= WS then
            leave()
        end
    end)

    pcall(function() math.randomseed(os.time()) end)

    canvas_api.toggle   = toggle
    canvas_api.shuffle  = shuffle
    canvas_api.zoom_out = function() request(1) end
    canvas_api.zoom_in  = function() request(-1) end
    canvas_api.leave    = leave
    canvas_api.recover  = recover
end)

local function go(ws)
    return function()
        canvas_api.leave()
        hl.dispatch(hl.dsp.focus({ workspace = ws }))
    end
end

local function send(ws)
    return function()
        canvas_api.leave()
        hl.dispatch(hl.dsp.window.move({ workspace = ws }))
    end
end

bind(mainMod .. " + D", hl.dsp.exec_cmd(launcher))
bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox-bin"))
bind(mainMod .. " + W", hl.dsp.exec_cmd("bash " .. SCRIPTS .. "/wallpaper.sh random"))
bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("bash " .. SCRIPTS .. "/wallpaper.sh pick"))
bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("bash " .. SCRIPTS .. "/keys.sh"))
bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || pkill -x Hyprland"))
bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd(if_installed({ "hyprlock" }, "hyprlock")))
bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd(if_installed({ "cliphist", "rofi", "wl-copy" },
    "cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy")))

bind(mainMod .. " + C", hl.dsp.window.close())
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind("F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind(mainMod .. " + V", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())
end)
bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + P", hl.dsp.window.pseudo())
bind(mainMod .. " + Y", hl.dsp.window.pin({ action = "toggle" }))
bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))
bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

bind("Print", hl.dsp.exec_cmd("sh " .. SCRIPTS .. "/screenshot.sh output"))
bind("CTRL + Print", hl.dsp.exec_cmd("sh " .. SCRIPTS .. "/screenshot.sh region"))
bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("sh " .. SCRIPTS .. "/screenshot.sh region"))

bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l " .. VOLUME_LIMIT .. " @DEFAULT_AUDIO_SINK@ " .. VOLUME_STEP .. "-"), { locked = true, repeating = true })
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l " .. VOLUME_LIMIT .. " @DEFAULT_AUDIO_SINK@ " .. VOLUME_STEP .. "+"), { locked = true, repeating = true })
bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"), { locked = true })
bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"), { locked = true })

local directions = {
    { "Left",  "H", "left",  -40, 0 },
    { "Right", "L", "right", 40,  0 },
    { "Up",    "K", "up",    0,   -40 },
    { "Down",  "J", "down",  0,   40 },
}
for _, d in ipairs(directions) do
    bind(mainMod .. " + " .. d[1], hl.dsp.focus({ direction = d[3] }))
    bind(mainMod .. " + " .. d[2], hl.dsp.focus({ direction = d[3] }))
    bind(mainMod .. " + SHIFT + " .. d[1], hl.dsp.window.move({ direction = d[3] }))
    bind(mainMod .. " + SHIFT + " .. d[2], hl.dsp.window.move({ direction = d[3] }))
    local grow = hl.dsp.window.resize({ x = d[4], y = d[5], relative = true })
    bind(mainMod .. " + ALT + " .. d[1], grow, { repeating = true })
    bind(mainMod .. " + ALT + " .. d[2], grow, { repeating = true })
end

for i = 1, 9 do
    bind(mainMod .. " + " .. i, go(i))
    bind(mainMod .. " + SHIFT + " .. i, send(i))
end

bind(mainMod .. " + CTRL + Left",       go("e-1"))
bind(mainMod .. " + CTRL + Right",      go("e+1"))
bind(mainMod .. " + CTRL + mouse_up",   go("e-1"))
bind(mainMod .. " + CTRL + mouse_down", go("e+1"))

bind(mainMod .. " + mouse_down", function() canvas_api.zoom_out() end)
bind(mainMod .. " + mouse_up",   function() canvas_api.zoom_in() end)
bind(mainMod .. " + mouse:274",  function() canvas_api.leave() end)
bind(mainMod .. " + Z",          function() canvas_api.toggle() end)
bind(mainMod .. " + SHIFT + Z",  function() canvas_api.shuffle() end)

try("scratchpad", function()
    bind(mainMod .. " + S",       hl.dsp.workspace.toggle_special("scratch"))
    bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratch" }))
end)

try("modo foco", function()
    local focus_mode = false
    bind(mainMod .. " + G", function()
        focus_mode = not focus_mode
        hl.config({
            general = {
                gaps_in     = focus_mode and 0 or GAPS_INNER,
                gaps_out    = focus_mode and 0 or GAPS_OUTER,
                border_size = focus_mode and 1 or BORDER_SIZE,
            },
        })
    end)
end)

try("regras por título", function()
    local prefixes = { "Open", "Abrir", "Select", "Selecionar", "Save", "Salvar", "Choose", "Escolher", "Enviar" }
    hl.on("window.title", function(w)
        local title = w.title or ""
        if w.class == "org.kde.dolphin" and starts_with_any(title, prefixes) then
            hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
        end
        if w.class == "firefox" and title == "Picture-in-Picture" then
            hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
            hl.dispatch(hl.dsp.window.pin({ action = "set", window = w }))
        end
    end)
end)

try("aviso de reload", function()
    hl.on("config.reloaded", function()
        canvas_api.recover()
        local text = "Configuração recarregada"
        if #failed > 0 then
            text = text .. " · ignoradas: " .. table.concat(failed, ", ")
        end
        pcall(hl.notification.create, {
            text = text,
            duration = 3000,
            icon = (#failed > 0) and "warning" or "ok",
        })
    end)
end)
