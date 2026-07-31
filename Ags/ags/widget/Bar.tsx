import app from "ags/gtk4/app"
import { Astal, Gdk } from "ags/gtk4"
import WelcomeButton from "./bar/WelcomeButton"
import ControlButton from "./bar/ControlButton"
import Clock from "./bar/Clock"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="centerbox">
        <WelcomeButton />
        <box $type="center" />
        <box $type="end" spacing={6} hexpand>
          <ControlButton />
          <Clock />
        </box>
      </centerbox>
    </window>
  )
}
