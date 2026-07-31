import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"

export default function WelcomeButton() {
  return (
    <button
      $type="start"
      onClicked={() => execAsync("echo hello").then(console.log)}
      hexpand
      halign={Gtk.Align.CENTER}
    >
      <label label="Welcome to AGS!" />
    </button>
  )
}
