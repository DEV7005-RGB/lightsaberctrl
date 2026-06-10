import Foundation
import SwiftUI
import CoreBluetooth
import Combine

// MARK: - 设备命令协议
protocol BladeDeviceCommands {
    func ignition()
    func retract()
    func blaster()
    func clash()
    func lockup()
    func nextPreset()
    func prevPreset()
    func setVolume(_ volume: Int)
    func setBrightness(_ brightness: Int)
    func enterColorChangeMode()
    func exitColorChangeMode()
    func saveColor()
    func exitColorMode()
    func requestSystemInfo()
    func selectPreset(_ index: Int)
    func setColor(_ hex: String)
    func volumeUp()
    func volumeDown()
    func reboot()
    func switchToWiFi()
    func switchToBLE()
    func changeWiFiPassword(_ newPassword: String)
    func resetWiFiPassword()
}

// MARK: - 连接设备管理器协议
protocol BladeDeviceManager: ObservableObject {
    var isConnected: Bool { get }
    var isScanning: Bool { get }
    var statusMessage: String { get }
    var systemInfo: BladeSystemInfo? { get }

    func startScanning()
    func stopScanning()
    func disconnect()
    func sendCommand(_ command: String)
}

// MARK: - 系统信息
struct BladeSystemInfo: Equatable {
    var battery: Float
    var temperature: Float
    var rssi: Int8
    var brightness: UInt8
    var volume: UInt8
    var color: String
    var bladeOn: Bool
    var mode: String
    var firmwareVersion: String?
    var currentPreset: Int  // 当前预设编号 (0-23)

    var colorValue: Color {
        Color(hex: color) ?? .red
    }
}

// MARK: - 发现的设备
struct DiscoveredBladeDevice: Identifiable {
    let id = UUID()
    let name: String?
    let deviceId: String?
    var alias: String?
    let rssi: NSNumber
    let peripheral: CBPeripheral?

    var displayName: String {
        if let alias = alias, !alias.isEmpty {
            return alias
        }
        return name ?? "未知设备"
    }

    var shortId: String {
        if let name = name {
            let parts = name.split(separator: "-")
            if parts.count > 1, let lastPart = parts.last {
                return String(lastPart)
            }
        }
        return deviceId ?? "----"
    }
}

// MARK: - 连接模式
enum ConnectionMode: String, CaseIterable {
    case bluetooth
    case wifi
    
    var displayName: String {
        switch self {
        case .bluetooth: return Strings.bluetooth
        case .wifi: return Strings.wifi
        }
    }

    var icon: String {
        switch self {
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .wifi: return "wifi.circle"
        }
    }
}

// MARK: - 设备命令枚举
enum BladeCommands {
    static let on = "ON"
    static let off = "OFF"
    static let blast = "BLAST"
    static let clash = "CLASH"
    static let lockup = "LOCKUP"
    static let next = "NEXT"
    static let prev = "PREV"
    static let ccmode = "CCMODE"
    static let ccsave = "CCSAVE"
    static let ccexit = "CCEXIT"
    static let reboot = "REBOOT"
    static let getInfo = "GET"

    static func color(_ hex: String) -> String { "COLOR:\(hex)" }
    static func volume(_ value: Int) -> String { "VOL \(value)" }
    static func brightness(_ value: Int) -> String { "BRI \(value)" }
    static func preset(_ index: Int) -> String { "PRESET \(index)" }
    static let wifiPassword = "WIFI_PASS"
    static let wifiResetPassword = "WIFI_RESET"
}

// MARK: - UI常量
enum UIConstants {
    static let cornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 14
    static let gridSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 24
    static let colorButtonSize: CGFloat = 44
    static let colorButtonStrokeWidth: CGFloat = 3
    static let shadowRadius: CGFloat = 8
    static let smallShadowRadius: CGFloat = 4
    static let animationDuration: Double = 0.3
    static let systemInfoUpdateInterval: TimeInterval = 3.0
    static let commandDebounceInterval: TimeInterval = 0.1
    static let scanTimeout: TimeInterval = 10.0
}

// MARK: - 预设颜色枚举
enum BladePresetColor: String, CaseIterable {
    case red, green, blue, yellow, orange, purple, lightBlue, cyan, white

    var color: Color {
        switch self {
        case .red: return Color(red: 255/255, green: 8/255, blue: 0/255)
        case .green: return Color(red: 10/255, green: 255/255, blue: 0/255)
        case .blue: return Color(red: 8/255, green: 35/255, blue: 255/255)
        case .yellow: return Color(red: 255/255, green: 180/255, blue: 2/255)
        case .orange: return Color(red: 255/255, green: 33/255, blue: 0/255)
        case .purple: return Color(red: 120/255, green: 0/255, blue: 255/255)
        case .lightBlue: return Color(red: 10/255, green: 85/255, blue: 255/255)
        case .cyan: return Color(red: 0/255, green: 255/255, blue: 255/255)
        case .white: return Color(red: 120/255, green: 120/255, blue: 120/255)
        }
    }
}

// MARK: - 预设数据结构
struct BladePreset: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let soundFile: String
    let index: Int

    var hasSound: Bool { !soundFile.isEmpty }
}

// MARK: - 预设配置 - 24个预设
let bladePresets: [BladePreset] = [
    BladePreset(name: "Blue", color: Color(red: 0/255, green: 0/255, blue: 255/255), soundFile: "", index: 0),
    BladePreset(name: "Green", color: Color(red: 0/255, green: 255/255, blue: 0/255), soundFile: "", index: 1),
    BladePreset(name: "Red", color: Color(red: 255/255, green: 0/255, blue: 0/255), soundFile: "", index: 2),
    BladePreset(name: "Yellow", color: Color(red: 255/255, green: 255/255, blue: 0/255), soundFile: "", index: 3),
    BladePreset(name: "Sky Blue", color: Color(red: 0/255, green: 102/255, blue: 255/255), soundFile: "", index: 4),
    BladePreset(name: "Purple", color: Color(red: 153/255, green: 0/255, blue: 255/255), soundFile: "", index: 5),
    BladePreset(name: "Cyan", color: Color(red: 0/255, green: 204/255, blue: 255/255), soundFile: "", index: 6),
    BladePreset(name: "Navy", color: Color(red: 30/255, green: 120/255, blue: 200/255), soundFile: "", index: 7),
    BladePreset(name: "Orange Red", color: Color(red: 255/255, green: 0/255, blue: 0/255), soundFile: "", index: 8),
    BladePreset(name: "Orange", color: Color(red: 255/255, green: 140/255, blue: 0/255), soundFile: "", index: 9),
    BladePreset(name: "Lime Green", color: Color(red: 0/255, green: 255/255, blue: 0/255), soundFile: "", index: 10),
    BladePreset(name: "Crimson", color: Color(red: 255/255, green: 0/255, blue: 0/255), soundFile: "", index: 11),
    BladePreset(name: "White", color: Color(red: 255/255, green: 255/255, blue: 255/255), soundFile: "", index: 12),
    BladePreset(name: "Gold", color: Color(red: 255/255, green: 165/255, blue: 0/255), soundFile: "", index: 13),
    BladePreset(name: "Fire", color: Color(red: 255/255, green: 102/255, blue: 0/255), soundFile: "", index: 14),
    BladePreset(name: "Forest", color: Color(red: 0/255, green: 255/255, blue: 0/255), soundFile: "", index: 15),
    BladePreset(name: "Silver", color: Color(red: 136/255, green: 136/255, blue: 136/255), soundFile: "", index: 16),
    BladePreset(name: "Electric", color: Color(red: 120/255, green: 0/255, blue: 255/255), soundFile: "", index: 17),
    BladePreset(name: "Ice", color: Color(red: 0/255, green: 102/255, blue: 255/255), soundFile: "", index: 18),
    BladePreset(name: "Teal", color: Color(red: 0/255, green: 200/255, blue: 180/255), soundFile: "", index: 19),
    BladePreset(name: "Pink", color: Color(red: 255/255, green: 10/255, blue: 80/255), soundFile: "", index: 20),
    BladePreset(name: "Neon", color: Color(red: 0/255, green: 168/255, blue: 255/255), soundFile: "", index: 21),
    BladePreset(name: "Violet", color: Color(red: 153/255, green: 0/255, blue: 255/255), soundFile: "", index: 22),
    BladePreset(name: "Rainbow", color: Color(red: 255/255, green: 255/255, blue: 255/255), soundFile: "", index: 23)
]

// MARK: - 颜色选项 - 每个颜色对应一个预设索引
let colorOptions: [ColorOption] = [
    ColorOption(hex: "#FF0800", name: Strings.red, presetIndex: 2),
    ColorOption(hex: "#0AFF00", name: Strings.green, presetIndex: 1),
    ColorOption(hex: "#0823FF", name: Strings.blue, presetIndex: 0),
    ColorOption(hex: "#FFB402", name: Strings.yellow, presetIndex: 3),
    ColorOption(hex: "#0AC8B4", name: Strings.cyan, presetIndex: 19),
    ColorOption(hex: "#7800FF", name: Strings.purple, presetIndex: 5),
    ColorOption(hex: "#787878", name: Strings.white, presetIndex: 12),
    ColorOption(hex: "#FF2100", name: Strings.orange, presetIndex: 13)
]

struct ColorOption: Identifiable {
    let id = UUID()
    let hex: String
    let name: String
    let presetIndex: Int

    var color: Color {
        Color(hex: hex) ?? .red
    }
}
