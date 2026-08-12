hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")

hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
  },
})

o.window({ class = "^(org.omarchy.terminal)$", title = "^(Timer)$" }, {
  float = true,
  center = true,
  size = { 875, 600 },
})
