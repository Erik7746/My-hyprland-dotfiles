import GLib from "gi://GLib"
import { Gtk } from "ags/gtk4"

export default function WelcomeButton() {
  const hostname = GLib.get_host_name()

  return (
    <button $type="start" hexpand halign={Gtk.Align.CENTER}>
      <label label={hostname} />
    </button>
  )
}
