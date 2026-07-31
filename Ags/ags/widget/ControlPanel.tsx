import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState } from "gnim"
import { panelVisible } from "../lib/state"
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
      marginTop={48}
      marginRight={12}
    >
      <box class="panel-container" orientation={Gtk.Orientation.VERTICAL} spacing={16}>
        {/* Vista Principal */}
        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={16}
          visible={currentView.as((v: string) => v === "main")}
        >
          <PanelHeader />
          <ToggleSection
            onWifiExpand={() => setCurrentView("wifi")}
            onBtExpand={() => setCurrentView("bluetooth")}
          />
          <box orientation={Gtk.Orientation.VERTICAL} spacing={12}>
            <SliderSection />
            <ShortcutSection />
          </box>
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
