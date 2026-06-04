import SwiftUI
import CoreBluetooth

// MARK: - 连接视图
struct ConnectionView: View {

    @ObservedObject var deviceManager: DeviceManager
    @State private var showDemoMode = false
    @State private var showPasswordChangeDialog = false
    @State private var newWiFiPassword = ""
    @State private var passwordChangeSuccess = false
    @State private var passwordChangeMessage = ""

    private var currentMode: ConnectionMode { deviceManager.currentMode }
    private var isConnected: Bool { deviceManager.isConnected }
    private var isScanning: Bool { deviceManager.bluetoothIsScanning }
    private var isWifiScanning: Bool { deviceManager.wifiIsScanning }
    private var statusMessage: String { deviceManager.statusMessage }

    var body: some View {
        ZStack {
            buildBackground()
            buildContent()
        }
        .sheet(isPresented: $showPasswordChangeDialog) {
            WiFiPasswordChangeSheet(
                isPresented: $showPasswordChangeDialog,
                newPassword: $newWiFiPassword,
                onResetDefault: {
                    deviceManager.resetWiFiPassword()
                    passwordChangeMessage = "WiFi密码已重置为默认密码: lightsaber"
                },
                onChangePassword: {
                    if !newWiFiPassword.isEmpty {
                        deviceManager.changeWiFiPassword(newWiFiPassword)
                        passwordChangeMessage = "WiFi密码已修改"
                        newWiFiPassword = ""
                    }
                }
            )
        }
        .alert("提示", isPresented: .init(
            get: { !passwordChangeMessage.isEmpty },
            set: { if !$0 { passwordChangeMessage = "" } }
        )) {
            Button("确定", role: .cancel) {
                passwordChangeMessage = ""
            }
        } message: {
            Text(passwordChangeMessage)
        }
    }

    // MARK: - 背景
    private func buildBackground() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.08, green: 0.03, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 150, y: -100)
            
            Circle()
                .fill(Color.purple.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: -100, y: 200)
        }
    }

    // MARK: - 内容
    private func buildContent() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                buildHeader()
                buildModeSelector()
                buildConnectionSection()
                buildDemoModeToggle()
            }
            .padding(20)
        }
    }

    // MARK: - 头部
    @ViewBuilder
    private func buildHeader() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.3, blue: 0.6), Color(red: 0.45, green: 0.25, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("设备连接")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.95, blue: 0.98), Color(red: 0.7, green: 0.65, blue: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Spacer()
            }
            .padding(.horizontal, 4)
            
            Text(statusMessage)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.vertical, 16)
    }

    // MARK: - 模式选择器
    @ViewBuilder
    private func buildModeSelector() -> some View {
        HStack(spacing: 8) {
            ForEach(ConnectionMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        deviceManager.currentMode = mode
                    }
                }) {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(mode.displayName)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(
                        currentMode == mode ?
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [Color.secondary, Color.secondary.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                currentMode == mode ?
                                LinearGradient(
                                    colors: [
                                        (mode == .bluetooth ? Color.blue : Color.green).opacity(0.35),
                                        (mode == .bluetooth ? Color.blue : Color.green).opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                currentMode == mode ?
                                LinearGradient(
                                    colors: [
                                        (mode == .bluetooth ? Color.blue : Color.green).opacity(0.6),
                                        (mode == .bluetooth ? Color.blue : Color.green).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: currentMode == mode ? (mode == .bluetooth ? Color.blue : Color.green).opacity(0.25) : Color.clear, radius: 10, x: 0, y: 5)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.14, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.07, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: - 连接区域
    @ViewBuilder
    private func buildConnectionSection() -> some View {
        VStack(spacing: 20) {
            if currentMode == .bluetooth {
                buildBluetoothSection()
            } else {
                buildWiFiSection()
            }
        }
    }

    // MARK: - 蓝牙连接区域
    @ViewBuilder
    private func buildBluetoothSection() -> some View {
        VStack(spacing: 20) {
            Button(action: toggleScanning) {
                ZStack {
                    ScanningIndicator(isScanning: isScanning, mode: .bluetooth)
                    
                    if isScanning {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 50, y: 50)
                            .shadow(color: Color.red.opacity(0.6), radius: 8)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isScanning ? "停止搜索" : "开始搜索")

            buildBluetoothDeviceList()

            if isConnected {
                VStack(spacing: 14) {
                    ModernActionButton(
                        title: "断开连接",
                        icon: "xmark.circle.fill",
                        color: Color.red,
                        action: { deviceManager.disconnect() }
                    )
                    
                    ModernActionButton(
                        title: "启用 Wi-Fi",
                        icon: "wifi",
                        color: Color.orange,
                        action: { deviceManager.bluetooth.switchToWiFi() }
                    )
                    
                    ModernActionButton(
                        title: "修改WiFi密码",
                        icon: "key.fill",
                        color: Color.purple,
                        action: { showPasswordChangeDialog = true }
                    )
                }
            } else if isScanning {
                ModernActionButton(
                    title: "停止搜索",
                    icon: "stop.fill",
                    color: Color.orange,
                    action: { deviceManager.stopScanning() }
                )
            }
        }
    }
    
    // MARK: - 切换扫描状态
    private func toggleScanning() {
        if isScanning {
            deviceManager.stopScanning()
        } else {
            deviceManager.startScanning()
        }
    }

    // MARK: - 蓝牙设备列表
    @ViewBuilder
    private func buildBluetoothDeviceList() -> some View {
        let devices = deviceManager.discoveredDevices
        let sortedDevices = devices.sorted { device1, device2 in
            let isLast1 = deviceManager.bluetooth.isLastConnectedDevice(device1)
            let isLast2 = deviceManager.bluetooth.isLastConnectedDevice(device2)
            if isLast1 && !isLast2 { return true }
            if !isLast1 && isLast2 { return false }

            let isSaber1 = device1.name?.lowercased().contains("saber") ?? false
            let isSaber2 = device2.name?.lowercased().contains("saber") ?? false
            if isSaber1 && !isSaber2 { return true }
            if !isSaber1 && isSaber2 { return false }

            return device1.rssi.intValue > device2.rssi.intValue
        }

        VStack(alignment: .leading, spacing: 16) {
            if !devices.isEmpty {
                // 设备数量和上次连接提示
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14))
                        Text("发现 \(devices.count) 个设备")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.9, green: 0.85, blue: 0.95), Color(red: 0.6, green: 0.55, blue: 0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()

                    if let lastId = deviceManager.bluetooth.getLastConnectedDeviceId(),
                       let lastDevice = devices.first(where: { $0.deviceId == lastId }),
                       !isConnected {
                        Button(action: {
                            deviceManager.connect(to: lastDevice)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 12))
                                Text(lastDevice.alias ?? lastDevice.name ?? "上次设备")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                            )
                        }
                    }
                }

                // 提示信息
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("点击铅笔图标可自定义设备名称")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.secondary.opacity(0.75))
                .padding(.horizontal, 4)

                // 设备列表
                ForEach(sortedDevices) { device in
                    let isThisDeviceConnected = isConnected && deviceManager.bluetooth.connectedPeripheral?.identifier == device.peripheral?.identifier
                    let isThisDeviceConnecting = deviceManager.isConnecting && deviceManager.bluetooth.connectedPeripheral?.identifier == device.peripheral?.identifier
                    let isLastConnected = deviceManager.bluetooth.isLastConnectedDevice(device)

                    ModernDeviceCard(
                        name: device.name ?? "未知设备",
                        deviceId: device.deviceId,
                        alias: device.alias,
                        rssi: device.rssi.intValue,
                        isConnected: isThisDeviceConnected,
                        isConnecting: isThisDeviceConnecting,
                        isLastConnected: isLastConnected,
                        onAliasChanged: { newAlias in
                            if let deviceId = device.deviceId {
                                deviceManager.bluetooth.saveAlias(newAlias, for: deviceId)
                                deviceManager.bluetooth.updateDeviceAlias(deviceId, alias: newAlias.isEmpty ? nil : newAlias)
                            }
                        }
                    ) {
                        deviceManager.connect(to: device)
                    }
                }
            } else if isScanning {
                // 扫描中提示
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    Text("正在搜索 saber 设备...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            } else {
                // 未搜索且无设备
                HStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.6, blue: 0.95), Color(red: 0.2, green: 0.4, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("点击上方按钮搜索设备")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.14, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.07, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
    }

    @ViewBuilder
    private func buildWiFiSection() -> some View {
        VStack(spacing: 20) {
            Button(action: toggleWiFiConnection) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 7
                        )
                        .frame(width: 170, height: 170)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.15), Color.green.opacity(0.07)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 135, height: 135)

                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.25), Color.green.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 95, height: 95)

                            Image(systemName: "wifi.circle")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                                .symbolEffect(.pulse, isActive: isWifiScanning)
                        }

                        if isConnected {
                            Text("已连接")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else if isWifiScanning {
                            Text("连接中...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isConnected ? "断开连接" : (isWifiScanning ? "取消连接" : "连接设备"))

            VStack(spacing: 12) {
                Text("Lightsaber WiFi")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.95, blue: 0.98), Color(red: 0.7, green: 0.65, blue: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text(Strings.ensureWifiConnected)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            buildWiFiInstructions()

            if isConnected {
                VStack(spacing: 14) {
                    ModernActionButton(
                        title: "断开连接",
                        icon: "xmark.circle.fill",
                        color: Color.red,
                        action: { deviceManager.disconnect() }
                    )
                    
                    ModernActionButton(
                        title: "恢复蓝牙模式",
                        icon: "antenna.radiowaves.left.and.right",
                        color: Color.blue,
                        action: { deviceManager.wifi.switchToBLE() }
                    )
                }
            }
        }
    }
    
    // MARK: - WiFi使用说明
    @ViewBuilder
    private func buildWiFiInstructions() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "info.circle")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("使用说明")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.95, blue: 1), Color(red: 0.65, green: 0.6, blue: 0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ModernInstructionStep(number: 1, text: "确保光剑已开机并进入WiFi模式")
                ModernInstructionStep(number: 2, text: "在手机WiFi设置中连接 \"Lightsaber-xxxx\"")
                ModernInstructionStep(number: 3, text: "Wi-Fi默认密码lightsaber")
                ModernInstructionStep(number: 4, text: "返回此应用，点击上方WiFi图标")
                ModernInstructionStep(number: 5, text: "连接成功后即可远程控制光剑")
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.blue.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - 切换WiFi连接状态
    private func toggleWiFiConnection() {
        if isConnected {
            deviceManager.disconnect()
        } else if isWifiScanning {
            deviceManager.stopScanning()
        } else {
            deviceManager.startScanning()
        }
    }

    // MARK: - 演示模式
    @ViewBuilder
    private func buildDemoModeToggle() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.25), Color.orange.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("其他功能")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.95, blue: 1), Color(red: 0.65, green: 0.6, blue: 0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding(.horizontal, 4)

            Toggle(isOn: $deviceManager.isDemoMode) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.25), Color.orange.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.demoMode)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(Strings.demoModeDesc)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.95, green: 0.3, blue: 0.6)))
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.14, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.07, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.2), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
            )
        }
    }
}

// MARK: - 现代化操作按钮
struct ModernActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.9), color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.45), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.7), color.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 现代化设备卡片
struct ModernDeviceCard: View {
    let name: String
    let deviceId: String?
    let alias: String?
    let rssi: Int
    let isConnected: Bool
    let isConnecting: Bool
    var isLastConnected: Bool = false
    let onAliasChanged: (String) -> Void
    let action: () -> Void

    @State private var showAliasEditor = false
    @State private var editedAlias = ""

    var signalStrength: Int {
        if rssi >= -50 { return 4 }
        if rssi >= -60 { return 3 }
        if rssi >= -70 { return 2 }
        return 1
    }

    var displayName: String {
        alias ?? name
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack(alignment: .topTrailing) {
                    ModernSignalStrengthIndicator(strength: signalStrength)

                    if isLastConnected && !isConnected {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.95))
                                .frame(width: 20, height: 20)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .offset(x: 10, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if isLastConnected && !isConnected {
                            Text("上次")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange.opacity(0.25), Color.orange.opacity(0.12)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text(alias != nil ? "ID: \(deviceId ?? "----")" : name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if deviceId != nil {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    
                    HStack(spacing: 6) {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isConnecting ? "连接中..." : "信号强度: \(abs(rssi)) dBm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isConnected {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                } else if isConnecting {
                    EmptyView()
                } else {
                    Button(action: {
                        editedAlias = alias ?? ""
                        showAliasEditor = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.25), Color.orange.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(
                Group {
                    if isConnecting {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else if isLastConnected && !isConnected {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.07)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.14, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.07, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.2), Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAliasEditor) {
            DeviceAliasEditor(
                alias: $editedAlias,
                isPresented: $showAliasEditor,
                onSave: { onAliasChanged(editedAlias) }
            )
        }
    }
}

// MARK: - 设备别名编辑器
struct DeviceAliasEditor: View {
    @Binding var alias: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("设备别名", text: $alias)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("编辑别名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 现代化信号强度指示器
struct ModernSignalStrengthIndicator: View {
    let strength: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(1...4, id: \.self) { index in
                let isActive = index <= strength
                let fillHeight: CGFloat = isActive ? 8 + CGFloat(index) * 4 : 4
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        isActive ?
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [Color.secondary.opacity(0.4), Color.secondary.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: fillHeight)
            }
        }
        .frame(width: 44, height: 44)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.12), Color.green.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// MARK: - 现代化使用说明步骤
struct ModernInstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
