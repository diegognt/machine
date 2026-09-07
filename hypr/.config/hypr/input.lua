---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Scrolling layout: 3-finger horizontal swipe moves focus between windows
-- along the stream. wrap_focus = true (see look_and_feel.lua) makes the
-- focus wrap from the last window back to the first, and vice versa.
-- Swipe left  -> next window (right in the stream)
-- Swipe right -> previous window (left in the stream)
hl.gesture({
    fingers = 3,
    direction = "left",
    action = function()
        hl.dispatch(hl.dsp.layout("focus r"))
    end,
})

hl.gesture({
    fingers = 3,
    direction = "right",
    action = function()
        hl.dispatch(hl.dsp.layout("focus l"))
    end,
})

-- Workspace switching moved to 4 fingers since 3 fingers now navigate windows
hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace"
})
