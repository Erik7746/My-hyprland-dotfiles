import { createState } from "gnim"
import Gtk from "gi://Gtk"
import GLib from "gi://GLib"

function formatTime() {
  const now = GLib.DateTime.new_now_local()
  return now.format("%H:%M") || ""
}

export default function Clock() {
  const [time, setTime] = createState(formatTime())

  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
    setTime(formatTime())
    return GLib.SOURCE_CONTINUE
  })

  return (
    <menubutton>
      <label label={time} />
      <popover>
        <Gtk.Calendar />
      </popover>
    </menubutton>
  )
}
