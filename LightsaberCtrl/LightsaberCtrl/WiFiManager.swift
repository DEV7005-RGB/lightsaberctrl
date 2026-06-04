import Foundation
import Combine

// MARK: - WiFi管理器（优化版）
final class WiFiManager: ObservableObject, SaberDeviceManager, SaberDeviceCommands {

    // MARK: - 单例
    static let shared = WiFiManager()

    // MARK: - Published属性
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var isScanning = false
    @Published private(set) var statusMessage = "未连接"
    @Published private(set) var systemInfo: SaberSystemInfo?
    @Published private(set) var availableNetworks: [WiFiNetwork] = []

    // MARK: - 私有属性
    private var pollingTimer: Timer?
    private var lastCommandTime: [String: Date] = [:]
    private var lastSystemInfoUpdate: Date = .distantPast
    private let baseURL = "http://192.168.4.1"
    private let session: URLSession
    
    // 性能优化参数
    private let commandDebounceMs: Int = 100
    private let minSystemInfoInterval: TimeInterval = 1.0

    // MARK: - 结构体
    struct WiFiNetwork: Identifiable {
        let id = UUID()
        let ssid: String
        let signal: Int
    }

    // MARK: - 初始化
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        config.waitsForConnectivity = false
        session = URLSession(configuration: config)
    }

    deinit {
        disconnect()
    }

    // MARK: - 连接管理（优化）
    func startScanning() {
        guard !isScanning else { return }

        isScanning = true
        statusMessage = "正在检测WiFi连接..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkWiFiConnection()
        }
    }

    func stopScanning() {
        isScanning = false
        statusMessage = isConnected ? "已连接" : "已停止检测"
    }

    func disconnect() {
        stopPolling()
        isConnected = false
        isConnecting = false
        statusMessage = "已断开"
        systemInfo = nil
        lastCommandTime.removeAll()
        SoundManager.shared.playDisconnectSound()
    }

    // MARK: - 命令发送（优化版）
    func sendCommand(_ command: String) {
        // 防抖机制
        let now = Date()
        if let lastTime = lastCommandTime[command],
           now.timeIntervalSince(lastTime) < Double(commandDebounceMs) / 1000.0 {
            return
        }
        lastCommandTime[command] = now

        guard isConnected else { return }

        // 使用异步请求，不阻塞主线程
        Task { [weak self] in
            await self?.performCommand(command)
        }
    }
    
    private func performCommand(_ command: String) async {
        guard let encodedCommand = command.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/command?cmd=\(encodedCommand)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 3
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // 命令发送成功
            }
        } catch {
            // 静默处理错误，避免频繁更新UI
        }
    }

    // MARK: - SaberDeviceCommands 实现
    func ignition() { sendCommand(SaberCommands.on + "\n") }
    func retract() { sendCommand(SaberCommands.off + "\n") }
    func blaster() { sendCommand(SaberCommands.blast + "\n") }
    func clash() { sendCommand(SaberCommands.clash + "\n") }
    func lockup() { sendCommand(SaberCommands.lockup + "\n") }
    func nextPreset() { sendCommand(SaberCommands.next + "\n") }
    func prevPreset() { sendCommand(SaberCommands.prev + "\n") }

    func setVolume(_ volume: Int) {
        sendCommand(SaberCommands.volume(volume) + "\n")
    }

    func setBrightness(_ brightness: Int) {
        sendCommand(SaberCommands.brightness(brightness) + "\n")
    }

    func enterColorChangeMode() { sendCommand(SaberCommands.ccmode + "\n") }
    func exitColorChangeMode() { sendCommand(SaberCommands.ccexit + "\n") }
    func saveColor() { sendCommand(SaberCommands.ccsave + "\n") }
    func exitColorMode() { sendCommand(SaberCommands.ccexit + "\n") }
    func reboot() { sendCommand(SaberCommands.reboot + "\n") }

    func selectPreset(_ index: Int) {
        sendCommand(SaberCommands.preset(index + 1) + "\n")
    }

    func setColor(_ hex: String) {
        let cleanHex = hex.replacingOccurrences(of: "#", with: "")
        sendCommand(SaberCommands.color(cleanHex) + "\n")
    }
    
    func volumeUp() {
        guard let current = systemInfo?.volume else { return }
        setVolume(Int(current) + 20)
    }
    
    func volumeDown() {
        guard let current = systemInfo?.volume else { return }
        setVolume(Int(current) - 20)
    }
    
    func switchToWiFi() { sendCommand("SWITCH_WIFI\n") }
    func switchToBLE() {
        sendCommand("SWITCH_BLE\n")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.disconnect()
            self.statusMessage = "已切换到蓝牙模式"
        }
    }

    func changeWiFiPassword(_ newPassword: String) {
        sendCommand("\(SaberCommands.wifiPassword) \(newPassword)\n")
    }

    func resetWiFiPassword() {
        sendCommand("\(SaberCommands.wifiResetPassword)\n")
    }
    
    func requestSystemInfo() {
        // 使用智能更新间隔
        guard Date().timeIntervalSince(lastSystemInfoUpdate) >= minSystemInfoInterval else {
            return
        }
        Task { [weak self] in
            await self?.fetchSystemInfoAsync()
        }
    }

    // MARK: - WiFi特定方法
    func connect() {
        guard !isConnecting && !isConnected else { return }

        isConnecting = true
        statusMessage = "正在连接..."

        Task { [weak self] in
            let success = await self?.fetchSystemInfoAsync() ?? false
            await MainActor.run {
                self?.isConnecting = false
                if success {
                    self?.isConnected = true
                    self?.statusMessage = "已连接"
                    SoundManager.shared.playConnectionSound()
                    self?.startPolling()
                } else {
                    self?.statusMessage = "连接失败"
                }
            }
        }
    }

    // MARK: - 私有方法
    private func checkWiFiConnection() {
        Task { [weak self] in
            let success = await self?.fetchSystemInfoAsync() ?? false
            await MainActor.run {
                self?.isScanning = false
                if success {
                    self?.isConnected = true
                    self?.statusMessage = "已连接到光剑"
                    SoundManager.shared.playConnectionSound()
                    self?.startPolling()
                } else {
                    self?.statusMessage = "未检测到光剑 WiFi"
                }
            }
        }
    }

    // 优化的异步获取系统信息
    private func fetchSystemInfoAsync() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/status") else {
            return false
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.httpMethod = "GET"

        do {
            let (data, _) = try await session.data(for: request)
            
            guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }

            let newInfo = SaberSystemInfo(
                battery: dict["battery"] as? Float ?? dict["bat"] as? Float ?? 0,
                temperature: dict["temperature"] as? Float ?? dict["temp"] as? Float ?? 0,
                rssi: Int8(dict["rssi"] as? Int ?? -50),
                brightness: UInt8(dict["brightness"] as? Int ?? dict["bri"] as? Int ?? 100),
                volume: UInt8(dict["volume"] as? Int ?? dict["vol"] as? Int ?? 75),
                color: dict["color"] as? String ?? dict["col"] as? String ?? "FFFFFF",
                bladeOn: dict["bladeOn"] as? Bool ?? dict["on"] as? Bool ?? false,
                mode: dict["mode"] as? String ?? "WiFi",
                firmwareVersion: dict["firmwareVersion"] as? String ?? dict["version"] as? String,
                currentPreset: dict["currentPreset"] as? Int ?? 1
            )

            // 智能更新机制
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.lastSystemInfoUpdate = Date()
                
                // 只在值真正改变时更新UI
                if self.shouldUpdateSystemInfo(newInfo) {
                    self.systemInfo = newInfo
                }
            }
            
            return true
        } catch {
            return false
        }
    }
    
    // 检查是否需要更新（避免不必要的UI刷新）
    private func shouldUpdateSystemInfo(_ newInfo: SaberSystemInfo) -> Bool {
        guard let current = systemInfo else { return true }
        
        // 电池变化 > 0.1V
        if abs(newInfo.battery - current.battery) > 0.1 { return true }
        // 音量变化 > 5%
        if abs(Int(newInfo.volume) - Int(current.volume)) > 5 { return true }
        // 亮度变化 > 10%
        if abs(Int(newInfo.brightness) - Int(current.brightness)) > 10 { return true }
        // 状态变化立即更新
        if newInfo.bladeOn != current.bladeOn { return true }
        if newInfo.color != current.color { return true }
        // 预设变化立即更新
        if newInfo.currentPreset != current.currentPreset { return true }
        
        return false
    }

    // MARK: - 轮询管理（优化）
    private func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: UIConstants.systemInfoUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            guard self?.isConnected == true else {
                self?.stopPolling()
                return
            }
            self?.requestSystemInfo()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}
