import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState } from "gnim"
import { panelVisible } from "../lib/state"
import {
  title,
  artist,
  coverPaintable,
  isPlaying,
  playPause,
  next,
  previous,
} from "../lib/music"
import PanelHeader from "./control/PanelHeader"
import ToggleSection from "./control/ToggleSection"
import SliderSection from "./control/SliderSection"
import ShortcutSection from "./control/ShortcutSection"
import WifiMenu from "./control/WifiMenu"
import BluetoothMenu from "./control/BluetoothMenu"

export default function ControlPanel(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const [currentView, setCurrentView] = createState<"main" | "wifi" | "bluetooth">("main")

  return (
    <window
      name="control-panel"
      class="ControlPanel"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={TOP | RIGHT}
      visible={panelVisible}
      application={app}
      marginTop={5}
      marginRight={15}
    >
      <box class="panel-container" orientation={Gtk.Orientation.VERTICAL} spacing={16}>
        {/* Vista Principal */}
        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={16}
          visible={currentView.as((v: string) => v === "main")}
        >
          <ToggleSection
            onWifiExpand={() => setCurrentView("wifi")}
            onBtExpand={() => setCurrentView("bluetooth")}
          />
          <box orientation={Gtk.Orientation.HORIZONTAL} spacing={12}>
            {/* Mini reproductor */}
            <box
              class="mini-player"
              orientation={Gtk.Orientation.VERTICAL}
              spacing={8}
              valign={Gtk.Align.CENTER}
              heightRequest={100}
            >
              <box
                spacing={4}
              >
                <box
                  class="mini-art-wrapper"
                  orientation={Gtk.Orientation.HORIZONTAL}
                  widthRequest={60}
                  heightRequest={60}
                  valign={Gtk.Align.CENTER}
                  overflow={Gtk.Overflow.HIDDEN}
                > 
                <image
                  class="mini-art"
                  pixelSize={60}
                  paintable={coverPaintable}
                  />
                </box>
              
                <box
                  orientation={Gtk.Orientation.VERTICAL}
                  spacing={8}
                  valign={Gtk.Align.CENTER}
                >
                  <label
                    class="mini-title"
                    label={title}
                    maxWidthChars={8}
                    ellipsize={3}
                  />
                  <label
                    class="mini-artist"
                    label={artist}
                    maxWidthChars={8}
                    ellipsize={3}
                  />
                  </box>
                </box>
              

               <box
                  class="mini-controls"
                  orientation={Gtk.Orientation.HORIZONTAL}
                  spacing={12}
                  valign={Gtk.Align.CENTER}
                >
                  <button
                    class="mini-control-btn"
                    onClicked={() => previous()}
                  >
                    <image
                      iconName="media-skip-backward-symbolic"
                      pixelSize={12}
                    />
                  </button>
                  <button
                    class="mini-control-btn"
                    onClicked={() => playPause()}
                  >
                    <image
                      iconName={isPlaying.as((v: boolean) =>
                        v ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                      )}
                      pixelSize={14}
                    />
                  </button>
                  <button
                    class="mini-control-btn"
                    onClicked={() => next()}
                  >
                  <image
                    iconName="media-skip-forward-symbolic"
                    pixelSize={12}
                  />
                  </button>
                </box>
            </box>
            <SliderSection />
          </box>
          <ShortcutSection />
        </box>

        {/* Vista Wi-Fi */}
        <box
          visible={currentView.as((v: string) => v === "wifi")}
        >
          <WifiMenu onBack={() => setCurrentView("main")} />
        </box>

        {/* Vista Bluetooth */}
        <box
          visible={currentView.as((v: string) => v === "bluetooth")}
        >
          <BluetoothMenu onBack={() => setCurrentView("main")} />
        </box>
      </box>
    </window>
  )
}
