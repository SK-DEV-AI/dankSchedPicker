# Scheduler Picker

A [DankMaterialShell](https://github.com/AvengeMedia/dms-plugins) bar widget for switching CPU schedulers and power profiles. Interfaces with `scx_loader` (the CachyOS sched-ext manager) via D-Bus.

![screenshot](https://raw.githubusercontent.com/SK-DEV-AI/dankSchedPicker/main/screenshot.png)

## Features

- **12 schedulers** — switch between all available scx schedulers (bpfland, rusty, lavd, flow, etc.) with one click
- **5 power modes** — Auto, Gaming, PowerSave, LowLatency, Server
- **Hover descriptions** — full scheduler information in the tooltip area
- **Self-contained** — no external JS, all logic in QML + a helper shell script

## Requirements

- DankMaterialShell 1.4+
- `scx_loader` (ships with CachyOS; Arch: `scx-scheds` package)
- D-Bus session bus (scx_loader registers on the system bus)

## Installation

1. Open DMS Settings → Plugins
2. Find **Scheduler Picker**
3. Click Install
4. Add the widget to your bar in DMS Bar Settings

Or clone manually:

```sh
mkdir -p ~/.config/DankMaterialShell/plugins
cd ~/.config/DankMaterialShell/plugins
git clone https://github.com/SK-DEV-AI/dankSchedPicker.git
```

Then register it in `settings.json` under `barConfigs[].rightWidgets`:

```json
{"id": "dankSchedPicker", "enabled": true}
```

Restart DMS.

## Usage

- **Left-click** the bolt pill → opens the scheduler picker popout
- **Right-click** the bolt pill → stops the current scheduler
- **Mode buttons** → switch power profile (Auto/Gaming/PowerSave/LowLatency/Server)
- **Scheduler list** → click any to activate; the active one has a left accent bar and check mark
- **Stop** → stops the active scheduler
- **Refresh** → refreshes the list and current state

## Configuration

Available in DMS Settings → Scheduler Picker:

| Setting | Default | Description |
|---------|---------|-------------|
| Poll interval | 3s | How often to check current scheduler state |
| List refresh | 15s | How often to refresh the available scheduler list |
| Auto-refresh | On | Automatically refresh the scheduler list |
| Animate transitions | On | Smooth color transitions in the popout |

## Roadmap

- [ ] Per-scheduler mode presets
- [ ] CPU governor integration
- [ ] Custom scheduler arguments

## License

MIT
