import XCTest
@testable import TQwallpaper

final class EnergyPolicyTests: XCTestCase {
    func testPlaysByDefaultOnACPower() {
        var policy = EnergyPolicy()
        policy.onBattery = false
        policy.lowPowerMode = false
        XCTAssertTrue(policy.shouldPlay)
    }

    func testStopsWhenDynamicDisabled() {
        var policy = EnergyPolicy()
        policy.dynamicEnabled = false
        XCTAssertFalse(policy.shouldPlay)
    }

    func testStopsWhenLocked() {
        var policy = EnergyPolicy()
        policy.locked = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testStopsWhenSleeping() {
        var policy = EnergyPolicy()
        policy.sleeping = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testStopsOnBatteryWithPowerSaver() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = true
        policy.onBattery = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testPlaysOnBatteryWhenPowerSaverOff() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = false
        policy.onBattery = true
        XCTAssertTrue(policy.shouldPlay)
    }

    func testStopsInLowPowerModeWithPowerSaver() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = true
        policy.lowPowerMode = true
        XCTAssertFalse(policy.shouldPlay)
    }

    func testPlaysInLowPowerModeWhenPowerSaverOff() {
        var policy = EnergyPolicy()
        policy.powerSaverOn = false
        policy.lowPowerMode = true
        XCTAssertTrue(policy.shouldPlay)
    }
}
