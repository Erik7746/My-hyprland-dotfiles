import app from "ags/gtk4/app"
import style from "./style.scss"
import ClickOverlay from "./widget/ClickOverlay"
import ControlPanel from "./widget/ControlPanel"
import MusicPlayer from "./widget/MusicPlayer"
import { setPanelVisible, setMusicPlayerVisible } from "./lib/state"

app.start({
  css: style,
  main() {
    const monitors = app.get_monitors()
    /* ClickOverlay se crea primero para quedar detrás de ControlPanel */
    monitors.map(ClickOverlay)
    monitors.map(ControlPanel)
    monitors.map(MusicPlayer)
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
      case "toggle-music":
        setMusicPlayerVisible((v) => !v)
        res("music toggled")
        break
      default:
        res(`unknown command: ${cmd}`)
    }
  },
})
