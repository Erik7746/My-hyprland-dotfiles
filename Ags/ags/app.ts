import app from "ags/gtk4/app"
import style from "./style.scss"
import ControlPanel from "./widget/ControlPanel"
import { setPanelVisible } from "./lib/state"

app.start({
  css: style,
  main() {
    const monitors = app.get_monitors()
    monitors.map(ControlPanel)
  },
  requestHandler(args, res) {
    const [cmd] = args
    switch (cmd) {
      case "toggle":
        setPanelVisible((v) => !v)
        res("toggled")
        break
      case "show":
        setPanelVisible(true)
        res("shown")
        break
      case "hide":
        setPanelVisible(false)
        res("hidden")
        break
      default:
        res(`unknown command: ${cmd}`)
    }
  },
})
