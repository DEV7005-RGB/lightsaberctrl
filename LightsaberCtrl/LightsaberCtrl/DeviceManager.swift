import Foundation
import Combine
import CoreBluetooth

// MARK: - 统一设备管理器
/// 封装蓝牙和WiFi管理器，提供统一接口
final class DeviceManager: ObservableObject {

    // MARK: - 单例
    static let shared = DeviceManager()

    // MARK: - 子管理器
    let bluetooth = BluetoothManager()
    let wifi = WiFiManager.shared

    // MARK: - Published状态
    @Published var currentMode: ConnectionMode = .bluetooth
    @Published var isDemoMode = false
    @Published private(set) var systemInfo: SaberSystemInfo?
    
    // MARK: - 同步子管理器状态（确保UI正确更新）
    @Published private(set) var bluetoothIsScanning = false
    
    // 防止刚点火后误进入颜色选择模式
    private var lastIgnitionTime: Date = .distantPast
    @Published private(set) var bluetoothIsConnected = false
    @Published private(set) var bluetoothIsConnecting = false
    @Published private(set) var bluetoothStatusMessage = "未连接"
    @Published private(set) var bluetoothDiscoveredDevices: [DiscoveredSaberDevice] = []
    @Published private(set) var wifiIsScanning = false
    @Published private(set) var wifiIsConnected = false
    @Published private(set) var wifiStatusMessage = ""
    
    // MARK: - 历史连接状态
    @Published private(set) var hasEverConnected = false
    
    // 自动重连状态
    var autoReconnectEnabled: Bool {
        get { bluetooth.autoReconnectEnabled }
        set { bluetooth.setAutoReconnect(enabled: newValue) }
    }
    
    // MARK: - Combine订阅
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    private init() {
        // 从UserDefaults加载历史连接状态
        hasEverConnected = UserDefaults.standard.bool(forKey: "hasEverConnected")
        setupBindings()
    }
    
    // MARK: - 设置属性绑定
    private func setupBindings() {
        // 蓝牙状态订阅
        bluetooth.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$bluetoothIsScanning)
        
        bluetooth.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$bluetoothIsConnected)
        
        bluetooth.$isConnecting
            .receive(on: DispatchQueue.main)
            .assign(to: &$bluetoothIsConnecting)
        
        bluetooth.$statusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$bluetoothStatusMessage)
        
        bluetooth.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: &$bluetoothDiscoveredDevices)
        
        bluetooth.$systemInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self, !self.isDemoMode else { return }
                if self.currentMode == .bluetooth {
                    self.systemInfo = info
                }
            }
            .store(in: &cancellables)
        
        wifi.$systemInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                guard let self = self, !self.isDemoMode else { return }
                if self.currentMode == .wifi {
                    self.systemInfo = info
                }
            }
            .store(in: &cancellables)
        
        // WiFi状态订阅
        wifi.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$wifiIsScanning)
        
        wifi.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$wifiIsConnected)
        
        wifi.$statusMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$wifiStatusMessage)
        
        // 监听连接状态，设置hasEverConnected
        bluetooth.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.setHasEverConnected(true)
                }
            }
            .store(in: &cancellables)
        
        wifi.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.setHasEverConnected(true)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setHasEverConnected(_ value: Bool) {
        hasEverConnected = value
        UserDefaults.standard.set(value, forKey: "hasEverConnected")
    }

    // MARK: - 统一访问属性
    var isConnected: Bool {
        isDemoMode || (currentMode == .bluetooth ? bluetoothIsConnected : wifiIsConnected)
    }

    var isConnecting: Bool {
        currentMode == .bluetooth ? bluetoothIsConnecting : wifi.isConnecting
    }

    var isScanning: Bool {
        currentMode == .bluetooth ? bluetoothIsScanning : wifiIsScanning
    }

    var statusMessage: String {
        if isDemoMode { return "演示模式" }
        return currentMode == .bluetooth ? bluetoothStatusMessage : wifiStatusMessage
    }

    var discoveredDevices: [DiscoveredSaberDevice] {
        bluetoothDiscoveredDevices
    }

    // MARK: - 连接管理
    func startScanning() {
        if currentMode == .bluetooth {
            bluetooth.startScanning()
        } else {
            wifi.startScanning()
        }
    }

    func stopScanning() {
        if currentMode == .bluetooth {
            bluetooth.stopScanning()
        } else {
            wifi.stopScanning()
        }
    }

    func disconnect() {
        if currentMode == .bluetooth {
            bluetooth.disconnect()
        } else {
            wifi.disconnect()
        }
    }

    func connect(to device: DiscoveredSaberDevice) {
        bluetooth.connect(to: device)
    }

    // MARK: - 命令发送
    func ignition() {
        lastIgnitionTime = Date()  // 记录点火时间
        isDemoMode ? DemoModeManager.shared.ignition() : sendCommand { $0.ignition() }
    }
    
    // 检查是否可以进入颜色选择模式（防止刚点火后误触）
    func canEnterColorChangeMode() -> Bool {
        let timeSinceIgnition = Date().timeIntervalSince(lastIgnitionTime)
        return timeSinceIgnition >= 0.5  // 点火后0.5秒内不允许进入颜色选择模式
    }

    func retract() {
        isDemoMode ? DemoModeManager.shared.retract() : sendCommand { $0.retract() }
    }

    func blaster() {
        isDemoMode ? DemoModeManager.shared.blaster() : sendCommand { $0.blaster() }
    }

    func clash() {
        isDemoMode ? DemoModeManager.shared.clash() : sendCommand { $0.clash() }
    }

    func lockup() {
        isDemoMode ? DemoModeManager.shared.lockup() : sendCommand { $0.lockup() }
    }

    func nextPreset() {
        isDemoMode ? DemoModeManager.shared.nextPreset() : sendCommand { $0.nextPreset() }
    }

    func prevPreset() {
        isDemoMode ? DemoModeManager.shared.prevPreset() : sendCommand { $0.prevPreset() }
    }

    func setVolume(_ volume: Int) {
        isDemoMode ? DemoModeManager.shared.setVolume(volume) : sendCommand { $0.setVolume(volume) }
    }

    func setBrightness(_ brightness: Int) {
        isDemoMode ? DemoModeManager.shared.setBrightness(brightness) : sendCommand { $0.setBrightness(brightness) }
    }

    func enterColorChangeMode() {
        isDemoMode ? DemoModeManager.shared.enterColorChangeMode() : sendCommand { $0.enterColorChangeMode() }
    }

    func exitColorChangeMode() {
        isDemoMode ? DemoModeManager.shared.exitColorChangeMode() : sendCommand { $0.exitColorChangeMode() }
    }

    func saveColor() {
        isDemoMode ? DemoModeManager.shared.saveColor() : sendCommand { $0.saveColor() }
    }

    func exitColorMode() {
        isDemoMode ? DemoModeManager.shared.exitColorMode() : sendCommand { $0.exitColorMode() }
    }

    func selectPreset(_ index: Int) {
        isDemoMode ? DemoModeManager.shared.selectPreset(index) : sendCommand { $0.selectPreset(index) }
    }

    func setColor(_ hex: String) {
        isDemoMode ? DemoModeManager.shared.setColor(hex) : sendCommand { $0.setColor(hex) }
    }

    func requestSystemInfo() {
        if !isDemoMode {
            sendCommand { $0.requestSystemInfo() }
        }
    }
    
    func volumeUp() {
        isDemoMode ? DemoModeManager.shared.setVolume(Int(DemoModeManager.shared.volume) + 20) : sendCommand { $0.volumeUp() }
    }
    
    func volumeDown() {
        isDemoMode ? DemoModeManager.shared.setVolume(Int(DemoModeManager.shared.volume) - 20) : sendCommand { $0.volumeDown() }
    }
    
    func reboot() {
        isDemoMode ? () : sendCommand { $0.reboot() }
    }
    
    func switchToWiFi() {
        isDemoMode ? () : sendCommand { $0.switchToWiFi() }
    }
    
    func switchToBLE() {
        isDemoMode ? () : sendCommand { $0.switchToBLE() }
    }

    func changeWiFiPassword(_ newPassword: String) {
        isDemoMode ? () : bluetooth.changeWiFiPassword(newPassword)
    }

    func resetWiFiPassword() {
        isDemoMode ? () : bluetooth.resetWiFiPassword()
    }

    // MARK: - 私有方法
    private func sendCommand(_ action: (SaberDeviceCommands) -> Void) {
        switch currentMode {
        case .bluetooth:
            action(bluetooth)
        case .wifi:
            action(wifi)
        }
    }
}

// MARK: - 演示模式管理器
final class DemoModeManager: ObservableObject {

    static let shared = DemoModeManager()

    @Published var bladeOn = false
    @Published var volume: Double = 75
    @Published var brightness: Double = 100
    @Published var currentColorHex = "#FF0000"
    @Published var currentPresetIndex = 0
    
    var systemInfo: SaberSystemInfo {
        SaberSystemInfo(
            battery: 85,
            temperature: 25,
            rssi: -65,
            brightness: UInt8(brightness),
            volume: UInt8(volume),
            color: currentColorHex,
            bladeOn: bladeOn,
            mode: "演示模式",
            firmwareVersion: "1.0.0",
            currentPreset: currentPresetIndex
        )
    }

    private init() {}

    func ignition() { bladeOn = true }
    func retract() { bladeOn = false }
    func blaster() {}
    func clash() {}
    func lockup() {}
    func nextPreset() {
        currentPresetIndex = (currentPresetIndex + 1) % saberPresets.count
    }
    func prevPreset() {
        currentPresetIndex = (currentPresetIndex - 1 + saberPresets.count) % saberPresets.count
    }
    func setVolume(_ volume: Int) { self.volume = Double(volume) }
    func setBrightness(_ brightness: Int) { self.brightness = Double(brightness) }
    func enterColorChangeMode() {}
    func exitColorChangeMode() {}
    func saveColor() {}
    func exitColorMode() {}
    func selectPreset(_ index: Int) { currentPresetIndex = index }
    func setColor(_ hex: String) { currentColorHex = hex }
    func requestSystemInfo() {}
}
