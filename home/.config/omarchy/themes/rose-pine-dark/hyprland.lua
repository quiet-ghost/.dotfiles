local active_border_color = {
  colors = { "rgb(ebbcba)", "rgb(31748f)", "rgb(eb6f92)", "rgb(c4a7e7)" },
  angle = 90,
}

hl.config({
  general = {
    col = {
      active_border = active_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
    },
  },
})

o.window({ fullscreen = true }, { border_color = "rgb(eb6f92)" })
