--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    match = {
        class = "firefox",
        title = "(.*)(- YouTube)(.*)",
    },

    opacity = "1.0 override 1.0 override",
})

hl.layer_rule({
    match = {
          namespace = "waybar",
    },

    blur = true,
    ignore_alpha = 0.1
})

hl.layer_rule({
    match = {
        namespace = "rofi",
    },

    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    match = {
        namespace = "gtk4-layer-shell",
    },

    blur = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    match = {
        namespace = "logout_dialog",
    },

    blur = true,
    animation = "popin 150%"
})

-- Functions

function rofi_menu_anim(animation_type, menu_select)
    hl.layer_rule({
        match = {
            namespace = "rofi",
        },
        animation = animation_type
    })
    hl.exec_cmd("pkill -x rofi || " .. menu_select)
end
function rofi_menu_anim_global(menu_select)

    hl.layer_rule({
        match = {
            namespace = "rofi",
        },
    })
    hl.exec_cmd("pkill -x rofi || " .. menu_select)
    hl.exec_cmd("hyprctl reload")
end

function toggle_ags_widget_anim(animation_type, request_name)
  hl.layer_rule({
    match = {
        namespace = "gtk4-layer-shell",
    },
    animation = animation_type
  })
  hl.exec_cmd("ags request " .. request_name)
end
