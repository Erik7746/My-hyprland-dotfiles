import { createPoll } from "ags/time"
import Gtk from "gi://Gtk"

export default function Clock() {
  const time = createPoll("", 1000, "date")

  return (
    <menubutton>
      <label label={time} />
      <popover>
        <Gtk.Calendar />
      </popover>
    </menubutton>
  )
}
