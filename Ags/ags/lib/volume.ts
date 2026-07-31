import Gio from "gi://Gio"
import { execAsync } from "ags/process"

export const VOLUME_THRESHOLD = 0.008

export async function readVolume(): Promise<number> {
  const out = await execAsync(
    "sh -c 'wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk \"{print \\$2}\"'",
  )
  const n = parseFloat(out.trim())
  return isNaN(n) ? 0.5 : Math.min(Math.max(n, 0), 1)
}

export async function setVolume(value: number) {
  const clamped = Math.min(Math.max(value, 0), 1)
  await execAsync(`sh -c 'wpctl set-volume @DEFAULT_AUDIO_SINK@ ${clamped.toFixed(3)}'`)
}

/**
 * Sincroniza el volumen con un dispositivo recién conectado.
 * Sube y baja ligeramente el volumen para que el periférico (p. ej. audífonos BT)
 * reciba la notificación del nivel actual del sistema.
 */
export async function bumpVolume() {
  const current = await readVolume()
  const step = 0.05

  if (current >= 1) {
    await setVolume(1 - step)
  } else {
    await setVolume(Math.min(current + step, 1))
  }

  await setVolume(current)
}

/** Inicia un watcher persistente vía pactl subscribe (0% CPU) */
export function startVolumeWatcher(onChange: () => void) {
  try {
    const proc = Gio.Subprocess.new(
      ["pactl", "subscribe"],
      Gio.SubprocessFlags.STDOUT_PIPE,
    )
    const stdout = proc.get_stdout_pipe()
    if (!stdout) {
      console.error("No stdout pipe from pactl")
      return
    }
    const dis = new Gio.DataInputStream({ base_stream: stdout })

    function loop() {
      dis.read_line_async(0, null, (source, res) => {
        try {
          const result = (source as Gio.DataInputStream).read_line_finish_utf8(res)
          const line = Array.isArray(result) ? result[0] : null
          if (line !== null) {
            if (line.includes("sink")) {
              onChange()
            }
            loop()
          }
        } catch (e) {
          console.error("pactl subscribe read error:", e)
        }
      })
    }
    loop()
  } catch (e) {
    console.error("Failed to start pactl subscribe:", e)
  }
}
