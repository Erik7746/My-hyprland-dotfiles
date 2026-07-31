import { Gtk } from "ags/gtk4"
import { safeExec } from "../../lib/utils"

const SHORTCUTS = [
  { icon: "✦", label: "ChatGPT", url: "https://chat.openai.com" },
  { icon: "◈", label: "GitHub", url: "https://github.com" },
  { icon: "▶", label: "YouTube", url: "https://youtube.com" },
  { icon: "◉", label: "Claude", url: "https://claude.ai" },
]

export default function ShortcutSection() {
  return (
    <box class="section" spacing={10} homogeneous>
        {SHORTCUTS.map(s => (
          <button
            class="shortcut-btn"
            onClicked={() => safeExec(`xdg-open ${s.url}`)}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
              <label class="shortcut-icon" label={s.icon} />
              <label class="shortcut-label" label={s.label} />
            </box>
          </button>
        ))}
      </box>
  )
}
