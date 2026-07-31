import Gio from "gi://Gio"
import { execAsync } from "ags/process"

export const BRIGHTNESS_THRESHOLD = 0.008

export async function readBrightness(): Promise<number> {
  const [cur, max] = await Promise.all([
    execAsync("brightnessctl g"),
    execAsync("brightnessctl m"),
  ])
  const c = parseFloat(cur)
  const m = parseFloat(max)
  if (isNaN(c) || isNaN(m) || m === 0) return 0.8
  return Math.min(Math.max(c / m, 0), 1)
}

/** Inicia un watcher persistente vía udevadm (netlink, 0% CPU) */
export function startBrightnessWatcher(onChange: () => void) {
  try {
    const proc = Gio.Subprocess.new(
      ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"],
      Gio.SubprocessFlags.STDOUT_PIPE,
    )
    const stdout = proc.get_stdout_pipe()
    if (!stdout) {
      console.error("No stdout pipe from udevadm")
      return
    }
    const dis = new Gio.DataInputStream({ base_stream: stdout })

    function loop() {
      dis.read_line_async(0, null, (source, res) => {
        try {
          const result = (source as Gio.DataInputStream).read_line_finish_utf8(res)
          const line = Array.isArray(result) ? result[0] : null
          if (line !== null) {
            onChange()
            loop()
          }
        } catch (e) {
          console.error("udevadm read error:", e)
        }
      })
    }
    loop()
  } catch (e) {
    console.error("Failed to start udevadm monitor:", e)
  }
}
