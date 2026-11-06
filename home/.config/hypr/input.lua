hl.config({
  input = {
    kb_layout = "programmer,us",
    kb_options = "ctrl:nocaps",
    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
    },
  },
  misc = {
    middle_click_paste = false,
  },
})

o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Bible needs a faster trackpad rate; leave every other app at its existing speed.
o.window("^bible-rs$", { scroll_touchpad = 1.0 })
