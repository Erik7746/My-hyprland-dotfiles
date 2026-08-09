import { Gtk } from "ags/gtk4"
import { Astal, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { panelVisible, setPanelVisible } from "../lib/state"

export default function ClickOverlay(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      name="click-overlay"
      class="ClickOverlay"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.NONE}
      anchor={
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.BOTTOM |
        Astal.WindowAnchor.LEFT |
        Astal.WindowAnchor.RIGHT
      }
      visible={panelVisible}
      application={app}
    >
      <box
        hexpand
        vexpand
        $={self => {
          const gesture = new Gtk.GestureClick()
          gesture.set_button(0)
          gesture.connect("pressed", () => {
            setPanelVisible(false)
          })
          self.add_controller(gesture)
        }}
      />
    </window>
  )
}
