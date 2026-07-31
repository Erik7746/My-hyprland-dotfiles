import { Gtk } from "ags/gtk4"
import { createState } from "gnim"
import { safeExec } from "../../lib/utils"
import {
  readBrightness,
  startBrightnessWatcher,
  BRIGHTNESS_THRESHOLD,
} from "../../lib/brightness"
import {
  readVolume,
  startVolumeWatcher,
  VOLUME_THRESHOLD,
} from "../../lib/volume"

export default function SliderSection() {
  /* ── Brillo ── */
  const [brightness, setBrightness] = createState(0.8)
  readBrightness().then(v => setBrightness(v)).catch(() => {})
  startBrightnessWatcher(() => {
    readBrightness().then(v => {
      const current = brightness()
      if (Math.abs(v - current) > BRIGHTNESS_THRESHOLD) {
        setBrightness(v)
      }
    }).catch(() => {})
  })

  /* ── Volumen ── */
  const [volume, setVolume] = createState(0.5)
  readVolume().then(v => setVolume(v)).catch(() => {})
  startVolumeWatcher(() => {
    readVolume().then(v => {
      const current = volume()
      if (Math.abs(v - current) > VOLUME_THRESHOLD) {
        setVolume(v)
      }
    }).catch(() => {})
  })

  return (
    <box class="section" spacing={16}>
      {/* Brightness */}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <slider
          class="control-slider"
          orientation={Gtk.Orientation.VERTICAL}
          inverted={true}
          heightRequest={140}
          value={brightness}
          onValueChanged={self => {
            const val = self.value
            const current = brightness()
            if (Math.abs(val - current) < BRIGHTNESS_THRESHOLD) return
            safeExec(`brightnessctl set ${Math.round(val * 100)}%`)
          }}
        />
        <image
          iconName="display-brightness-symbolic"
          pixelSize={18}
          halign={Gtk.Align.CENTER}
        />
      </box>

      {/* Volume */}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <slider
          class="control-slider"
          orientation={Gtk.Orientation.VERTICAL}
          inverted={true}
          heightRequest={140}
          value={volume}
          onValueChanged={self => {
            const val = self.value
            const current = volume()
            if (Math.abs(val - current) < VOLUME_THRESHOLD) return
            safeExec(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${val.toFixed(2)}`)
            if (val <= 0) safeExec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 1")
            else safeExec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0")
          }}
        />
        <image
          iconName="audio-volume-high-symbolic"
          pixelSize={18}
          halign={Gtk.Align.CENTER}
        />
      </box>
    </box>
  )
}
