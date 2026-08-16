import Foundation

/// Pure state machine deciding whether the wallpaper video should play.
struct EnergyPolicy {
    var dynamicEnabled = true
    var locked = false
    var sleeping = false
    var onBattery = false
    var lowPowerMode = false
    var powerSaverOn = true

    var shouldPlay: Bool {
        true
    }
}
