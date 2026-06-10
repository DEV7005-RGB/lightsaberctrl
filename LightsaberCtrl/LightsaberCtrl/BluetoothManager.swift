import CoreBluetooth
import Foundation
import Combine
import UIKit

// MARK: - 蓝牙管理器（优化版）
final class BluetoothManager: NSObject, ObservableObject, BladeDeviceManager, BladeDeviceCommands {
    
    // MARK: - Published属性
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var isScanning = false
    @Published private(set) var statusMessage = "未连接"
    @Published private(set) var systemInfo: BladeSystemInfo?
    @Published private(set) var bluetoothState: BluetoothState = .unknown
    @Published private(set) var discoveredDevices: [DiscoveredBladeDevice] = []

    // MARK: - 私有属性
    private var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    private var watchdogTimer: Timer?  // 看门狗定时器（替代系统信息轮询）
    private var lastCommandTime: [String: Date] = [:]
    private var lastSystemInfoUpdate: Date = Date.distantPast
    private var lastMessageTime: Date = Date()  // 最后收到消息时间
    
    // 连接超时管理
    private var connectionTimeoutTimer: Timer?
    private let connectionTimeout: TimeInterval = 10.0
    
    // 自动重连管理
    private var autoReconnectTimer: Timer?
    @Published private(set) var autoReconnectEnabled = false
    private let autoReconnectInterval: TimeInterval = 2.0
    private var isAutoReconnecting = false
    private var reconnectAttempts = 0  // 重连尝试次数
    private let maxReconnectAttempts = 2  // 最大重连次数

    // MARK: - 常量 - 与ESP32固件匹配
    private let serviceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    private let characteristicUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")

    // MARK: - 初始化
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main, options: [
            CBCentralManagerOptionShowPowerAlertKey: false
        ])
    }

    deinit {
        disconnect()
    }

    // MARK: - 连接管理（优化）
    func startScanning() {
        // 快速检查蓝牙状态
        guard centralManager.state == .poweredOn else {
            updateStatusForBluetoothState()
            return
        }

        // 清空旧设备列表
        discoveredDevices.removeAll()
        
        isScanning = true
        statusMessage = "正在搜索..."
        
        // 不允许重复发现，避免卡顿
        centralManager.scanForPeripherals(withServices: nil, options: nil)

        // 扫描超时 - 5秒后自动停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard self?.isScanning == true else { return }
            self?.stopScanning()
        }
    }

    func stopScanning() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        
        // 停止自动重连
        stopAutoReconnect()
        
        // 更新状态
        if isConnected {
            statusMessage = "已连接"
        } else if !discoveredDevices.isEmpty {
            statusMessage = "发现 \(discoveredDevices.count) 个设备"
        } else {
            statusMessage = "未找到设备"
        }
    }

    func disconnect() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
        stopAutoReconnect()
        stopWatchdogTimer()

        if let characteristic = targetCharacteristic, let peripheral = connectedPeripheral {
            peripheral.setNotifyValue(false, for: characteristic)
        }
        targetCharacteristic = nil

        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        connectedPeripheral = nil
        isConnected = false
        isConnecting = false
        statusMessage = "已断开"
        SoundManager.shared.playDisconnectSound()
    }

    // MARK: - 快速连接（优化）
    func connect(to device: DiscoveredBladeDevice) {
        guard let peripheral = device.peripheral else { return }
        guard !isConnecting && !isConnected else { return }
        
        stopScanning()
        guard centralManager.state == .poweredOn else { return }
        
        isConnecting = true
        statusMessage = "正在连接 \(device.name ?? "设备")..."
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        // 启动连接超时计时器
        startConnectionTimeout()
        
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    // MARK: - 连接超时处理
    private func startConnectionTimeout() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeout, repeats: false) { [weak self] _ in
            self?.handleConnectionTimeout()
        }
    }
    
    private func handleConnectionTimeout() {
        guard isConnecting else { return }
        
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        isConnecting = false
        statusMessage = "连接超时"
        connectedPeripheral = nil
    }

    // MARK: - 状态更新
    private func updateStatusForBluetoothState() {
        switch centralManager.state {
        case .poweredOff:
            statusMessage = "请开启蓝牙"
        case .unauthorized:
            statusMessage = "请在设置中开启蓝牙权限"
            openSettings()
        case .unsupported:
            statusMessage = "设备不支持蓝牙"
        case .resetting, .unknown:
            statusMessage = "蓝牙初始化中..."
        case .poweredOn:
            statusMessage = "蓝牙已就绪"
        @unknown default:
            statusMessage = "蓝牙状态未知"
        }
    }

    // MARK: - 命令发送
    func sendCommand(_ command: String) {
        let now = Date()
        
        // 基础防抖，避免极短时间内重复发送
        if let lastTime = lastCommandTime[command],
           now.timeIntervalSince(lastTime) < 0.05 {
            return
        }
        
        lastCommandTime[command] = now

        guard let characteristic = targetCharacteristic else { return }
        guard isConnected else { return }
        guard let data = command.data(using: .utf8) else { return }

        // 使用无响应写入，快速响应
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    // 强制发送命令（忽略防抖）
    func forceSendCommand(_ command: String) {
        lastCommandTime.removeValue(forKey: command)
        sendCommand(command)
    }

    // MARK: - BladeDeviceCommands 实现
    func ignition() { sendCommand(BladeCommands.on + "\r\n") }
    func retract() { sendCommand(BladeCommands.off + "\r\n") }
    func blaster() { sendCommand(BladeCommands.blast + "\r\n") }
    func clash() { sendCommand(BladeCommands.clash + "\r\n") }
    func lockup() { sendCommand(BladeCommands.lockup + "\r\n") }
    func nextPreset() { sendCommand(BladeCommands.next + "\r\n") }
    func prevPreset() { sendCommand(BladeCommands.prev + "\r\n") }

    func setVolume(_ volume: Int) {
        let clamped = min(max(volume, 0), 100)
        sendCommand(BladeCommands.volume(clamped) + "\r\n")
    }

    func setBrightness(_ brightness: Int) {
        let clamped = min(max(brightness, 0), 100)
        sendCommand(BladeCommands.brightness(clamped) + "\r\n")
    }

    func enterColorChangeMode() { sendCommand(BladeCommands.ccmode + "\r\n") }
    func exitColorChangeMode() { sendCommand(BladeCommands.ccexit + "\r\n") }
    func saveColor() { sendCommand(BladeCommands.ccsave + "\r\n") }
    func exitColorMode() { sendCommand(BladeCommands.ccexit + "\r\n") }
    
    func requestSystemInfo() {
        // 连接建立后优先获取信息
        if isConnected {
            forceSendCommand(BladeCommands.getInfo + "\r\n")
        }
    }
    
    func reboot() { sendCommand(BladeCommands.reboot + "\r\n") }

    func volumeUp() {
        guard let current = systemInfo?.volume else { return }
        setVolume(Int(current) + 20)
    }

    func volumeDown() {
        guard let current = systemInfo?.volume else { return }
        setVolume(Int(current) - 20)
    }

    func selectPreset(_ index: Int) {
        sendCommand(BladeCommands.preset(index + 1) + "\r\n")
    }

    func setColor(_ hex: String) {
        let cleanHex = hex.replacingOccurrences(of: "#", with: "")
        sendCommand(BladeCommands.color(cleanHex) + "\r\n")
    }
    
    func switchToWiFi() { sendCommand("SWITCH_WIFI\r\n") }
    func switchToBLE() { sendCommand("SWITCH_BLE\r\n") }
    func changeWiFiPassword(_ newPassword: String) {
        sendCommand("\(BladeCommands.wifiPassword) \(newPassword)\r\n")
    }
    func resetWiFiPassword() {
        sendCommand("\(BladeCommands.wifiResetPassword)\r\n")
    }

    // MARK: - 看门狗定时器（事件驱动模式）
    private func startWatchdogTimer() {
        stopWatchdogTimer()
        
        // 10秒内没收到消息，主动请求一次（兜底机制）
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.requestSystemInfo()
        }
    }

    private func stopWatchdogTimer() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }

    private func resetWatchdog() {
        lastMessageTime = Date()
        stopWatchdogTimer()
        startWatchdogTimer()
    }

    // MARK: - 辅助方法
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - JSON解析（优化）
    private func parseSystemInfo(from jsonString: String) {
        lastSystemInfoUpdate = Date()

        // 清理 JSON 字符串
        let cleanJson = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanJson.hasPrefix("{") && cleanJson.hasSuffix("}") else {
            return
        }

        guard let data = cleanJson.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let newInfo = BladeSystemInfo(
            battery: dict["battery"] as? Float ?? dict["bat"] as? Float ?? 0,
            temperature: dict["temperature"] as? Float ?? dict["temp"] as? Float ?? 0,
            rssi: Int8(dict["rssi"] as? Int ?? -50),
            brightness: UInt8(dict["brightness"] as? Int ?? dict["bri"] as? Int ?? 100),
            volume: UInt8(dict["volume"] as? Int ?? dict["vol"] as? Int ?? 75),
            color: dict["color"] as? String ?? dict["col"] as? String ?? "FFFFFF",
            bladeOn: dict["bladeOn"] as? Bool ?? dict["on"] as? Bool ?? false,
            mode: dict["mode"] as? String ?? "蓝牙",
            firmwareVersion: dict["firmwareVersion"] as? String ?? dict["fw"] as? String,
            currentPreset: dict["currentPreset"] as? Int ?? 1
        )

        // 智能更新 - 值变化明显时才更新
        if shouldUpdateSystemInfo(newInfo) {
            systemInfo = newInfo
        }

        // 处理电池警告消息
        if let message = dict["message"] as? String ?? dict["msg"] as? String,
           message.hasPrefix("BATTERY_LOW:") {
            handleBatteryWarning(message: message, battery: newInfo.battery)
        }
    }

    // 处理电池警告
    private func handleBatteryWarning(message: String, battery: Float) {
        let parts = message.split(separator: ":")
        guard parts.count >= 3 else { return }

        let level = String(parts[2])  // WARNING or CRITICAL
        NotificationCenter.default.post(
            name: NSNotification.Name("BatteryLowWarning"),
            object: nil,
            userInfo: [
                "voltage": battery,
                "level": level
            ]
        )
    }
    
    // 检查是否需要更新UI
    private func shouldUpdateSystemInfo(_ newInfo: BladeSystemInfo) -> Bool {
        guard let current = systemInfo else { return true }
        
        // 电池变化 > 0.1V
        if abs(newInfo.battery - current.battery) > 0.1 { return true }
        // 音量变化 > 5%
        if abs(Int(newInfo.volume) - Int(current.volume)) > 5 { return true }
        // 亮度变化 > 10%
        if abs(Int(newInfo.brightness) - Int(current.brightness)) > 10 { return true }
        // 开关状态变化
        if newInfo.bladeOn != current.bladeOn { return true }
        // 颜色变化
        if newInfo.color != current.color { return true }
        // 预设变化
        if newInfo.currentPreset != current.currentPreset { return true }
        
        return false
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothState = .poweredOn
            if !isConnected && !isConnecting {
                statusMessage = "蓝牙已就绪"
            }
        case .poweredOff:
            bluetoothState = .poweredOff
            statusMessage = "请开启蓝牙"
            isConnected = false
            isConnecting = false
        case .unauthorized:
            bluetoothState = .unauthorized
            statusMessage = "请在设置中开启蓝牙权限"
        case .unsupported:
            bluetoothState = .unsupported
            statusMessage = "设备不支持蓝牙"
        case .resetting:
            bluetoothState = .resetting
            statusMessage = "蓝牙重置中"
        case .unknown:
            bluetoothState = .unknown
            statusMessage = "蓝牙初始化中..."
        @unknown default:
            bluetoothState = .unknown
            statusMessage = "蓝牙状态未知"
        }
    }

    // MARK: - 设备发现
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let deviceId = extractDeviceId(from: name)

        // 过滤RSSI过弱的设备 (-100dBm)
        guard RSSI.intValue > -100 else { return }

        // 检查是否已存在
        if let index = discoveredDevices.firstIndex(where: { $0.peripheral?.identifier == peripheral.identifier }) {
            // 更新现有设备的RSSI
            var device = discoveredDevices[index]
            let alias = loadAlias(for: deviceId ?? "")
            device = DiscoveredBladeDevice(name: name ?? device.name, deviceId: deviceId ?? device.deviceId, alias: alias, rssi: RSSI, peripheral: peripheral)
            discoveredDevices[index] = device

            // 如果是光剑设备，确保排在第一位
            if let deviceName = name?.lowercased(),
               (deviceName.contains("blade") || deviceName.contains("glow") || deviceName.contains("esp32")) {
                let device = discoveredDevices.remove(at: index)
                discoveredDevices.insert(device, at: 0)
            }
            return
        }

        // 添加新设备
        let alias = loadAlias(for: deviceId ?? "")
        let device = DiscoveredBladeDevice(name: name, deviceId: deviceId, alias: alias, rssi: RSSI, peripheral: peripheral)

        // 光剑设备永远排在第一位
        if let deviceName = name?.lowercased(),
           (deviceName.contains("blade") || deviceName.contains("glow") || deviceName.contains("esp32")) {
            discoveredDevices.insert(device, at: 0)
        } else {
            discoveredDevices.append(device)
        }
    }

    // 从设备名称中提取设备ID (如 "lightsaber-A1B2" -> "A1B2")
    private func extractDeviceId(from name: String?) -> String? {
        guard let name = name else { return nil }
        let parts = name.split(separator: "-")
        if parts.count > 1, let lastPart = parts.last, lastPart.count <= 8 {
            return String(lastPart)
        }
        return nil
    }

    // 从UserDefaults加载设备别名
    private func loadAlias(for deviceId: String) -> String? {
        guard !deviceId.isEmpty else { return nil }
        return UserDefaults.standard.string(forKey: "device_alias_\(deviceId)")
    }

    // 保存设备别名到UserDefaults
    func saveAlias(_ alias: String, for deviceId: String) {
        guard !deviceId.isEmpty else { return }
        if alias.isEmpty {
            UserDefaults.standard.removeObject(forKey: "device_alias_\(deviceId)")
        } else {
            UserDefaults.standard.set(alias, forKey: "device_alias_\(deviceId)")
        }
    }

    // 更新发现设备列表中的别名
    func updateDeviceAlias(_ deviceId: String, alias: String?) {
        if let index = discoveredDevices.firstIndex(where: { $0.deviceId == deviceId }) {
            var device = discoveredDevices[index]
            device = DiscoveredBladeDevice(
                name: device.name,
                deviceId: device.deviceId,
                alias: alias,
                rssi: device.rssi,
                peripheral: device.peripheral
            )
            discoveredDevices[index] = device
        }
    }

    // MARK: - 连接结果
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
        stopAutoReconnect()

        isConnecting = false
        isConnected = true
        statusMessage = "连接成功"

        SoundManager.shared.playConnectionSound()

        // 保存上次连接的设备ID
        if let deviceId = extractDeviceId(from: peripheral.name) {
            saveLastConnectedDeviceId(deviceId)
        }

        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    // 保存上次连接的设备ID
    private func saveLastConnectedDeviceId(_ deviceId: String) {
        UserDefaults.standard.set(deviceId, forKey: "lastConnectedDeviceId")
    }

    // 获取上次连接的设备ID
    func getLastConnectedDeviceId() -> String? {
        return UserDefaults.standard.string(forKey: "lastConnectedDeviceId")
    }

    // 检查设备是否是上次连接的
    func isLastConnectedDevice(_ device: DiscoveredBladeDevice) -> Bool {
        guard let lastId = getLastConnectedDeviceId() else { return false }
        return device.deviceId == lastId
    }
    
    // MARK: - 自动重连控制
    func setAutoReconnect(enabled: Bool) {
        autoReconnectEnabled = enabled
        if !enabled {
            stopAutoReconnect()
        }
    }
    
    private func startAutoReconnect() {
        guard autoReconnectEnabled, !isConnected, !isConnecting else { return }
        
        reconnectAttempts = 0  // 重置重连次数
        isAutoReconnecting = true
        statusMessage = "等待设备重启，准备自动重连..."
        
        autoReconnectTimer = Timer.scheduledTimer(withTimeInterval: autoReconnectInterval, repeats: true) { [weak self] _ in
            self?.attemptAutoReconnect()
        }
    }
    
    private func stopAutoReconnect() {
        autoReconnectTimer?.invalidate()
        autoReconnectTimer = nil
        isAutoReconnecting = false
        reconnectAttempts = 0  // 重置重连次数
    }
    
    private func attemptAutoReconnect() {
        guard autoReconnectEnabled, !isConnected, !isConnecting else {
            stopAutoReconnect()
            return
        }
        
        // 检查是否达到最大重连次数
        if reconnectAttempts >= maxReconnectAttempts {
            stopAutoReconnect()
            stopScanning()
            statusMessage = "自动重连失败，请手动连接"
            return
        }
        
        reconnectAttempts += 1
        statusMessage = "自动重连中 (\(reconnectAttempts)/\(maxReconnectAttempts))..."
        
        // 如果没有在扫描，开始扫描
        if !isScanning {
            startScanning()
        }
        
        // 检查是否发现了上次连接的设备
        if let lastDevice = discoveredDevices.first(where: { isLastConnectedDevice($0) }) {
            stopAutoReconnect()
            stopScanning()
            connect(to: lastDevice)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil

        isConnecting = false
        statusMessage = "连接失败"
        connectedPeripheral = nil

        SoundManager.shared.playDisconnectSound()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        targetCharacteristic = nil
        connectedPeripheral = nil
        stopWatchdogTimer()

        SoundManager.shared.playDisconnectSound()

        statusMessage = error != nil ? "连接错误" : "已断开"
        
        // 如果启用了自动重连，并且之前成功连接过设备，则启动自动重连
        if autoReconnectEnabled, getLastConnectedDeviceId() != nil {
            startAutoReconnect()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil,
              let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            // 服务未找到，尝试连接但不使用服务UUID
            // 直接查找特征
            if let services = peripheral.services {
                for service in services {
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                }
            }
            return
        }
        peripheral.discoverCharacteristics([characteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil,
              let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            return
        }
        
        targetCharacteristic = characteristic
        
        // 启用通知
        peripheral.setNotifyValue(true, for: characteristic)
        
        statusMessage = "准备就绪"
        
        // 立即请求一次初始状态（保证连接速度快）
        requestSystemInfo()
        
        // 启动看门狗定时器（事件驱动模式）
        lastMessageTime = Date()
        startWatchdogTimer()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil,
              let data = characteristic.value,
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        // 收到消息时重置看门狗
        resetWatchdog()
        
        parseSystemInfo(from: jsonString)
    }
}

// MARK: - 蓝牙状态
enum BluetoothState {
    case unknown, poweredOff, poweredOn, unauthorized, unsupported, resetting
}
