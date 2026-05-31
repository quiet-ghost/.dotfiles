-- Change the default Omarchy look'n'feel.

hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,
  },
})

-- Timer floating window rules.
o.window({ class = "^(org.omarchy.terminal)$", title = "^(Timer)$" }, { float = true })
o.window({ class = "^(org.omarchy.terminal)$", title = "^(Timer)$" }, { center = true })
o.window({ class = "^(org.omarchy.terminal)$", title = "^(Timer)$" }, { size = { 875, 600 } })
