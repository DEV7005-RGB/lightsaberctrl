
import SwiftUI
import Combine

// MARK: - 主视图
struct ContentView: View {
    
    // MARK: - 状态
    @StateObject private var deviceManager = DeviceManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var selectedTab = 0
    @State private var volume: Double = 75
    @State private var brightness: Double = 100
    @State private var selectedColorHex = "#FF0000"
    @State private var currentPresetIndex = 0
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var showBatteryWarning = false
    @State private var batteryWarningLevel = ""
    @State private var batteryWarningVoltage: Float = 0
    
    private let userDefaults = UserDefaults.standard
    private let batteryWarningCountKey = "BatteryWarningCount"

    // MARK: - 常量
    private let tabs = [Strings.control, Strings.connect, Strings.info]

    // MARK: - 计算属性
    private var isConnected: Bool { deviceManager.isConnected }
    private var currentMode: ConnectionMode { deviceManager.currentMode }
    private var isDemoMode: Bool { deviceManager.isDemoMode }

    private var bladeOnState: Bool {
        isDemoMode ? DemoModeManager.shared.bladeOn : (deviceManager.systemInfo?.bladeOn ?? false)
    }

    private var currentBladeColor: Color {
        if isDemoMode {
            return Color(hex: DemoModeManager.shared.currentColorHex) ?? .red
        }
        return deviceManager.systemInfo?.colorValue ?? .red
    }

    // MARK: - 主体
    var body: some View {
        ZStack {
            buildBackground()
            
            VStack(spacing: 0) {
                buildTabContent()
                buildModernTabBar()
            }
            .ignoresSafeArea(.keyboard)
        }
        .id(languageManager.language) // Force refresh when language changes
        .onAppear {
            deviceManager.requestSystemInfo()
            setupBatteryWarningObserver()
        }
        .alert(isPresented: $showBatteryWarning) {
            Alert(
                title: Text(batteryWarningLevel == "CRITICAL" ? Strings.batteryCritical : Strings.batteryLow),
                message: Text(String(format: Strings.batteryVoltage, batteryWarningVoltage) + "\n" + Strings.pleaseCharge),
                dismissButton: .default(Text(Strings.gotIt))
            )
        }
    }

    // MARK: - 电池警告监听
    private func setupBatteryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("BatteryLowWarning"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let voltage = userInfo["voltage"] as? Float,
               let level = userInfo["level"] as? String {
                var currentCount = self.userDefaults.integer(forKey: self.batteryWarningCountKey)
                if currentCount < 2 {
                    self.batteryWarningVoltage = voltage
                    self.batteryWarningLevel = level
                    self.showBatteryWarning = true
                    currentCount += 1
                    self.userDefaults.set(currentCount, forKey: self.batteryWarningCountKey)
                }
            }
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

    // MARK: - 现代化Tab栏
    @ViewBuilder
    private func buildModernTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        let iconNames = ["gamecontroller.fill", "link.circle.fill", "info.circle.fill"]
                        
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.25),
                                                Color(red: 0.45, green: 0.25, blue: 0.9).opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.95, green: 0.3, blue: 0.6),
                                                        Color(red: 0.45, green: 0.25, blue: 0.9)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            
                            Image(systemName: iconNames[index])
                                .font(.system(size: 24, weight: selectedTab == index ? .bold : .semibold))
                                .foregroundStyle(
                                    selectedTab == index ?
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.3, blue: 0.6),
                                                Color(red: 0.45, green: 0.25, blue: 0.9)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.4, blue: 0.5),
                                                Color(red: 0.25, green: 0.25, blue: 0.35)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                )
                                .shadow(color: selectedTab == index ? Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.4) : .clear, radius: 6, x: 0, y: 3)
                        }
                        .frame(height: 52)

                        Text(tabs[index])
                            .font(.system(size: 12, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundStyle(
                                selectedTab == index ?
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.3, blue: 0.6),
                                            Color(red: 0.45, green: 0.25, blue: 0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.4, blue: 0.5),
                                            Color(red: 0.25, green: 0.25, blue: 0.35)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )

                        if selectedTab == index {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.3, blue: 0.6),
                                            Color(red: 0.45, green: 0.25, blue: 0.9)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 24, height: 3)
                                .shadow(color: Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.6), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .padding(.top, 8)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.08, blue: 0.18),
                        Color(red: 0.08, green: 0.06, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Color.black.opacity(0.3)
            }
        )
        .overlay(
            LinearGradient(
                colors: [Color.clear, Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.2), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: -10)
    }

    // MARK: - Tab内容
    @ViewBuilder
    private func buildTabContent() -> some View {
        TabView(selection: $selectedTab) {
            ModernControlView(
                deviceManager: deviceManager,
                volume: $volume,
                brightness: $brightness,
                selectedColorHex: $selectedColorHex,
                currentPresetIndex: $currentPresetIndex,
                showSuccessMessage: $showSuccessMessage,
                successMessage: $successMessage
            )
            .tag(0)

            ConnectionView(deviceManager: deviceManager)
                .tag(1)

            InfoView(deviceManager: deviceManager)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

// MARK: - 现代化控制视图
struct ModernControlView: View {
    
    @ObservedObject var deviceManager: DeviceManager
    @Binding var volume: Double
    @Binding var brightness: Double
    @Binding var selectedColorHex: String
    @Binding var currentPresetIndex: Int
    @Binding var showSuccessMessage: Bool
    @Binding var successMessage: String

    private var isConnected: Bool { deviceManager.isConnected }
    private var currentMode: ConnectionMode { deviceManager.currentMode }
    private var isDemoMode: Bool { deviceManager.isDemoMode }

    private var bladeOnState: Bool {
        isDemoMode ? DemoModeManager.shared.bladeOn : (deviceManager.systemInfo?.bladeOn ?? false)
    }

    private var currentBladeColor: Color {
        if isDemoMode {
            return Color(hex: DemoModeManager.shared.currentColorHex) ?? .red
        }
        return deviceManager.systemInfo?.colorValue ?? .red
    }

    private var currentPreset: SaberPreset {
        saberPresets[currentPresetIndex]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                buildModernHeaderSection()
                buildModernQuickActionsSection()
                buildModernSettingsSection()
                buildModernPresetSection()
                Spacer().frame(height: 32)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
        .background(
            SuccessToast(message: successMessage, isShowing: $showSuccessMessage)
        )
        .onReceive(deviceManager.bluetooth.$systemInfo.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)) { info in
            updateStateFromSystemInfo(info)
        }
        .onReceive(deviceManager.wifi.$systemInfo.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)) { info in
            updateStateFromSystemInfo(info)
        }
    }

    // MARK: - 现代化头部区域
    @ViewBuilder
    private func buildModernHeaderSection() -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.25),
                                    Color(red: 0.45, green: 0.25, blue: 0.9).opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.3, blue: 0.6),
                                            Color(red: 0.45, green: 0.25, blue: 0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.3), radius: 12, x: 0, y: 6)

                    Image(systemName: "wand.and.rays.inverse")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.3, blue: 0.6),
                                    Color(red: 0.45, green: 0.25, blue: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Lightsaber Ctrl")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.95, blue: 0.98),
                                    Color(red: 0.8, green: 0.75, blue: 0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text(Strings.smartSaberController)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.65, green: 0.6, blue: 0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 4)

            buildModernConnectionStatus()
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.1, blue: 0.2),
                                    Color(red: 0.1, green: 0.07, blue: 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.3),
                                            Color(red: 0.45, green: 0.25, blue: 0.9).opacity(0.15)
                                        ],
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

    @ViewBuilder
    private func buildModernConnectionStatus() -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        (isConnected ? Color.green : Color.orange).opacity(0.15)
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                (isConnected ? Color.green : Color.orange).opacity(0.5),
                                lineWidth: 1
                            )
                    )

                Circle()
                    .fill(isConnected ? Color.green : Color.orange)
                    .frame(width: 18, height: 18)
                    .shadow(color: (isConnected ? Color.green : Color.orange).opacity(0.8), radius: 10, x: 0, y: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(isConnected ? Strings.connected : Strings.disconnected)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isConnected ? .green : .orange)

                Text(isConnected ? Strings.saberReady : Strings.pleasePairFirst)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            ModernConnectionStatusBadge(isConnected: isConnected, mode: currentMode)
        }
    }

    // MARK: - 现代化快速操作区域
    @ViewBuilder
    private func buildModernQuickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ModernSectionHeader(
                icon: "bolt.fill",
                title: Strings.quickActions,
                color1: Color(red: 1, green: 0.6, blue: 0.1),
                color2: Color(red: 0.95, green: 0.25, blue: 0.4)
            )

            VStack(spacing: 18) {
                HStack(spacing: 16) {
                    ModernSaberActionButton(
                        title: Strings.ignition,
                        icon: "flame.fill",
                        color: bladeOnState ? currentPreset.color : Color(red: 1, green: 0.3, blue: 0.1),
                        isActive: bladeOnState,
                        size: .large
                    ) {
                        deviceManager.ignition()
                        showSuccess(bladeOnState ? "Blade Ignited" : "Igniting...")
                    }

                    ModernSaberActionButton(
                        title: Strings.retract,
                        icon: "wind",
                        color: bladeOnState ? Color(red: 0.15, green: 0.45, blue: 0.95) : currentPreset.color,
                        isActive: !bladeOnState,
                        size: .large
                    ) {
                        deviceManager.retract()
                        showSuccess(bladeOnState ? "Retracting..." : "Blade Retracted")
                    }
                }

                HStack(spacing: 14) {
                    ModernSaberActionButton(
                        title: Strings.blaster,
                        icon: "sparkles",
                        color: bladeOnState ? currentPreset.color : Color(red: 0.95, green: 0.75, blue: 0.1),
                        isActive: false,
                        size: .small
                    ) {
                        deviceManager.blaster()
                        showSuccess("Blaster Effect")
                    }

                    ModernSaberActionButton(
                        title: Strings.clash,
                        icon: "bolt",
                        color: bladeOnState ? currentPreset.color : Color(red: 1, green: 0.4, blue: 0.1),
                        isActive: false,
                        size: .small
                    ) {
                        deviceManager.clash()
                        showSuccess("Clash Effect")
                    }

                    ModernSaberActionButton(
                        title: Strings.lockup,
                        icon: "lock.fill",
                        color: bladeOnState ? currentPreset.color : Color(red: 0.65, green: 0.2, blue: 0.95),
                        isActive: false,
                        size: .small
                    ) {
                        deviceManager.lockup()
                        showSuccess("Lockup Effect")
                    }
                }
            }
        }
        .modernSectionStyle()
    }

    // MARK: - 现代化参数调节区域
    @ViewBuilder
    private func buildModernSettingsSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ModernSectionHeader(
                icon: "slider.horizontal.3",
                title: Strings.settings,
                color1: Color(red: 0.2, green: 0.7, blue: 0.95),
                color2: Color(red: 0.4, green: 0.35, blue: 0.95)
            )

            VStack(spacing: 22) {
                ModernSlider(
                    value: $volume,
                    range: 0...100,
                    label: Strings.volume,
                    unit: "%",
                    color1: Color(red: 0.8, green: 0.25, blue: 0.95),
                    color2: Color(red: 0.45, green: 0.15, blue: 0.95)
                ) {
                    deviceManager.setVolume(Int(volume))
                }

                ModernSlider(
                    value: $brightness,
                    range: 0...100,
                    label: Strings.brightness,
                    unit: "%",
                    color1: Color(red: 1, green: 0.8, blue: 0.25),
                    color2: Color(red: 0.95, green: 0.5, blue: 0.1)
                ) {
                    deviceManager.setBrightness(Int(brightness))
                }
            }
        }
        .modernSectionStyle()
    }

    // MARK: - 现代化预设切换区域
    @ViewBuilder
    private func buildModernPresetSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ModernSectionHeader(
                icon: "list.bullet.rectangle.portrait.fill",
                title: Strings.presets,
                color1: Color(red: 0.3, green: 0.85, blue: 0.45),
                color2: Color(red: 0.15, green: 0.6, blue: 0.85)
            )

            VStack(spacing: 20) {
                buildModernPresetNavigation()
                buildModernPresetGrid()
            }
        }
        .modernSectionStyle()
    }

    @ViewBuilder
    private func buildModernPresetNavigation() -> some View {
        HStack(spacing: 20) {
            ModernNavButton(
                direction: .left,
                isEnabled: bladeOnState,
                color: currentPreset.color
            ) {
                previousPreset()
            }

            VStack(spacing: 14) {
                Text("\(currentPresetIndex + 1) / \(saberPresets.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )

                ZStack {
                    Circle()
                        .fill(currentPreset.color.opacity(0.15))
                        .frame(width: 92, height: 92)
                        .shadow(color: currentPreset.color.opacity(0.25), radius: 18, x: 0, y: 10)

                    Circle()
                        .fill(currentPreset.color.opacity(0.35))
                        .frame(width: 76, height: 76)
                        .shadow(color: currentPreset.color.opacity(0.5), radius: 14, x: 0, y: 8)

                    Circle()
                        .fill(currentPreset.color)
                        .frame(width: 60, height: 60)
                        .shadow(color: currentPreset.color.opacity(0.85), radius: 12, x: 0, y: 6)

                    Image(systemName: "wand.and.stars.inverse")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(1.08)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPresetIndex)

                Text(currentPreset.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.98, blue: 1),
                                Color(red: 0.7, green: 0.65, blue: 0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)

            ModernNavButton(
                direction: .right,
                isEnabled: bladeOnState,
                color: currentPreset.color
            ) {
                nextPreset()
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func buildModernPresetGrid() -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8),
            spacing: 12
        ) {
            ForEach(saberPresets) { preset in
                ModernPresetButton(
                    preset: preset,
                    isSelected: preset.index == currentPresetIndex,
                    isDisabled: !bladeOnState
                ) {
                    selectPreset(preset)
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }

    private func selectPreset(_ preset: SaberPreset) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentPresetIndex = preset.index
        }
        deviceManager.selectPreset(preset.index)
        showSuccess(String.localizedStringWithFormat(Strings.presetChanged, preset.name))
    }

    private func nextPreset() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentPresetIndex = (currentPresetIndex + 1) % saberPresets.count
        }
        deviceManager.nextPreset()
        showSuccess(String.localizedStringWithFormat(Strings.next, saberPresets[currentPresetIndex].name))
    }

    private func previousPreset() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentPresetIndex = (currentPresetIndex - 1 + saberPresets.count) % saberPresets.count
        }
        deviceManager.prevPreset()
        showSuccess(String.localizedStringWithFormat(Strings.previous, saberPresets[currentPresetIndex].name))
    }

    private func updateStateFromSystemInfo(_ info: SaberSystemInfo?) {
        guard let info = info else { return }
        volume = Double(info.volume)
        brightness = Double(info.brightness)
        selectedColorHex = "#\(info.color)"
        let newPresetIndex = max(0, min(info.currentPreset, saberPresets.count - 1))
        if currentPresetIndex != newPresetIndex {
            currentPresetIndex = newPresetIndex
        }
    }
}

// MARK: - 现代化SectionHeader
struct ModernSectionHeader: View {
    let icon: String
    let title: String
    let color1: Color
    let color2: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                color1.opacity(0.2),
                                color2.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color1.opacity(0.6),
                                        color2.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color1, color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: color1.opacity(0.25), radius: 8, x: 0, y: 4)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.98, blue: 1),
                            Color(red: 0.65, green: 0.6, blue: 0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

// MARK: - 现代化ViewModifier
extension View {
    func modernSectionStyle() -> some View {
        self
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.1, blue: 0.2),
                                Color(red: 0.1, green: 0.06, blue: 0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.3, blue: 0.6).opacity(0.25),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 12)
            )
    }
}

// MARK: - 现代化连接状态徽章
struct ModernConnectionStatusBadge: View {
    let isConnected: Bool
    let mode: ConnectionMode

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode == .bluetooth ? "dot.radiowaves.left.and.right" : "wifi")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isConnected ? .blue : .secondary)

            Text(mode == .bluetooth ? "Bluetooth" : "WiFi")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isConnected ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isConnected ? Color.blue.opacity(0.12) : Color(.systemGray5).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isConnected ? Color.blue.opacity(0.3) : Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - 现代化导航按钮
struct ModernNavButton: View {
    enum Direction {
        case left, right
    }

    let direction: Direction
    let isEnabled: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isEnabled ?
                            LinearGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.12),
                                    Color.gray.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 64, height: 64)

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled ?
                            LinearGradient(
                                colors: [color.opacity(0.8), color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: isEnabled ? color.opacity(0.5) : .clear, radius: 12, x: 0, y: 6)

                Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - 现代化操作按钮
struct ModernSaberActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isActive: Bool
    let size: ButtonSize
    let action: () -> Void
    
    @State private var isPressed = false

    enum ButtonSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 26
            case .large: return 34
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 13
            case .medium: return 15
            case .large: return 17
            }
        }

        var buttonHeight: CGFloat {
            switch self {
            case .small: return 52
            case .medium: return 60
            case .large: return 72
            }
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeInOut(duration: 0.24)) {
                    isPressed = false
                }
            }
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
        }) {
            HStack(spacing: size == .large ? 14 : 10) {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundColor(isActive ? .white : Color.white.opacity(0.95))
            .frame(height: size.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isActive ?
                            LinearGradient(
                                colors: [color.opacity(0.85), color.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(
                        color: isActive ? color.opacity(0.5) : Color.black.opacity(0.2),
                        radius: isPressed ? 20 : 12,
                        x: 0,
                        y: isPressed ? 4 : 6
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isActive ?
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isPressed ? 2.5 : 1.5
                    )
            )
            .scaleEffect(isPressed ? 1.08 : (isActive ? 1.02 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isActive)
            .animation(.spring(response: 0.18, dampingFraction: 0.55), value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isActive ? "当前激活" : "点击触发")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - 现代化Slider
struct ModernSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String
    let unit: String
    let color1: Color
    let color2: Color
    let onEditingChanged: () -> Void
    
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.9, blue: 0.98),
                                Color(red: 0.65, green: 0.6, blue: 0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Spacer()
                
                Text("\(Int(value))\(unit)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color1, color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color1.opacity(0.18),
                                        color2.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color1.opacity(0.4),
                                        color2.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 12)

                    let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                    let fillWidth = max(0, min(progress * geometry.size.width, geometry.size.width))

                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [color1, color2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: 12)
                        .shadow(color: color1.opacity(0.4), radius: 6, x: 0, y: 2)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 28, height: 28)
                        .shadow(color: color1.opacity(0.5), radius: 10, x: 0, y: 4)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [color1.opacity(0.7), color2.opacity(0.35)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .offset(x: max(0, min(fillWidth - 14, geometry.size.width - 28)), y: 0)
                        .scaleEffect(isEditing ? 1.25 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isEditing)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isEditing = true
                            let newValue = range.lowerBound + (gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound)
                            value = max(range.lowerBound, min(newValue, range.upperBound))
                        }
                        .onEnded { _ in
                            isEditing = false
                            onEditingChanged()
                        }
                )
            }
            .frame(height: 28)
        }
    }
}

// MARK: - 现代化预设按钮
struct ModernPresetButton: View {
    let preset: SaberPreset
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        isSelected ?
                            preset.color.opacity(0.35) :
                            Color.white.opacity(0.08)
                    )
                    .frame(width: 42, height: 42)

                if isSelected {
                    Circle()
                        .stroke(preset.color, lineWidth: 2.5)
                        .frame(width: 36, height: 36)
                }

                Circle()
                    .fill(preset.color)
                    .frame(width: isSelected ? 28 : 32, height: isSelected ? 28 : 32)
                    .shadow(
                        color: isSelected ? preset.color.opacity(0.65) : preset.color.opacity(0.25),
                        radius: isSelected ? 10 : 6,
                        x: 0,
                        y: isSelected ? 5 : 3
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .opacity(isDisabled ? 0.4 : 1.0)
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
        .accessibilityLabel(preset.name)
        .accessibilityHint(isSelected ? "已选中" : "点击选择")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


