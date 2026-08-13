import QtQuick
import qs.Ui

BarIndicator {
  id: root

  readonly property var timerService: bar && bar.shell ? bar.shell.serviceFor("local.timer") : null

  active: timerService ? timerService.active : false
  activeText: timerService && timerService.active ? "󰔛" : "󰔛"
  inactiveText: "󰔛"
  activeTooltipText: timerService && timerService.active
    ? timerService.displayTime + " · " + timerService.label + " · click to cancel"
    : "Timer"
  inactiveTooltipText: "Start 20 minute timer"

  function toggle() {
    if (!root.timerService) return
    if (root.timerService.active) root.timerService.cancel()
    else root.timerService.startMinutes(20, "20 minute timer")
  }

  onPressed: function() { root.toggle() }
}
