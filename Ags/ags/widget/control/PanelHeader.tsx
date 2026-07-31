import { Gtk } from "ags/gtk4"

export default function PanelHeader() {
  return (
    <label class="panel-title" label="Control Center" halign={Gtk.Align.START} />
  )
}
