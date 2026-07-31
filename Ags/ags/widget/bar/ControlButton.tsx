import { toggleControlPanel } from "../../lib/state"

export default function ControlButton() {
  return (
    <button onClicked={() => toggleControlPanel()}>
      <image iconName="applications-system-symbolic" />
    </button>
  )
}
