# NX659J LED Controller Service

A Magisk/APatch module for controlling the rear RGB LED on the **RedMagic 5G/5S (NX659J)** running LineageOS.

Supports Material You (Monet) colors, configurable LED effects, and automatic switching based on screen and charging state.

## Features

* Material You dynamic colors
    * Filters (…ish)
* Custom RGB colors
* Solid, flashing, and music-reactive LED effects
* Separate colors and effects for charging, full battery, screen on/off, and boot
* KSU/AP hotinstall

## Installation

Install the module ZIP through your root manager, and if necessary, reboot.

### Building from source

Requires the Android NDK, Make, and standard build tools.

```bash
./scripts/setup-vendor.sh
make
```

Install directly using ADB:

```bash
make install                       # Magisk
make install ROOT_MANAGER=apatch   # APatch
```

## Configuration

Edit `/data/adb/modules/nx659j-led-service/config.sh` to customize LED behavior.

```sh
FULL_COLOR=00ff00
FULL_ANIM=solid

CHARGE_COLOR='$system_accent1_500|hsvsat:1'
CHARGE_ANIM=flash

SCREEN_ON_COLOR='$system_accent1_500|hsvsat:1'
SCREEN_ON_ANIM=solid

SCREEN_OFF_COLOR='$system_accent1_500|hsvsat:1'
SCREEN_OFF_ANIM=music
```

Supported colors: `RRGGBB`, `#RRGGBB`, Material You resources (`$system_*`), or `off`.

Color filters: `boost:<factor, -∞ to +∞>` and `hsvsat:<0 to 1>`.

Effects: `solid`, `flash`, `music`.

Restart the service or reboot to apply configuration changes.

## Compatibility

Designed for **LineageOS** on the **RedMagic 5G/5S (NX659J)**.
Other devices and ROMs are unsupported.

## Credits

- [TinyALSA](https://github.com/tinyalsa/tinyalsa) -- Audio mixer utilities
- [Magisk](https://github.com/topjohnwu/Magisk) -- Module installation framework

Feature requests and well-reviewed AI PRs welcome

## License

[MIT](LICENSE)
