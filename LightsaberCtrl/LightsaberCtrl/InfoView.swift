import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CoreBluetooth

// MARK: - 信息视图
struct InfoView: View {

    @ObservedObject var deviceManager: DeviceManager
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var soundManager = SoundManager.shared
    @State private var showProffieConfig = false
    @State private var showStartupMediaPicker = false
    @State private var selectedStartupItem: PhotosPickerItem?
    @AppStorage("customStartupMediaPath") private var customStartupMediaPath: String = ""
    @AppStorage("startupMediaAspectMode") private var startupMediaAspectMode: Int = 0
    @AppStorage("startupVideoDuration") private var startupVideoDuration: Int = 3
    
    @State private var showOtaFilePicker = false
    @State private var selectedFirmwareURL: URL?
    @State private var otaProgress: Double = 0.0
    @State private var otaStatus: OtaManager.OtaState = .idle

    private var systemInfo: SaberSystemInfo? {
        deviceManager.isDemoMode ? DemoModeManager.shared.systemInfo : deviceManager.systemInfo
    }
    
    // 动态获取版本号（自动更新）
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        ZStack {
            buildBackground()
            buildContent()
        }
        .sheet(isPresented: $showProffieConfig) {
            ProffieboardConfigView(deviceManager: deviceManager)
        }
    }

    // MARK: - 背景
    private func buildBackground() -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 装饰性模糊圆形
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.8, blue: 0.2).opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -200)
                .blur(radius: 60)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: 200, y: 100)
                .blur(radius: 50)
        }
    }

    // MARK: - 内容
    private func buildContent() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                buildHeader()
                buildSystemInfoCards()
                buildProffieWorkbenchSection()
                buildSoundSection()
                buildOtaSection()
                buildLanguageSection()
                buildAboutSection()
            }
            .padding(20)
        }
    }

    // MARK: - 头部
    @ViewBuilder
    private func buildHeader() -> some View {
        VStack(spacing: 20) {
            ZStack {
                // 外发光效果
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .center,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                // 主圆形
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.3),
                                Color(red: 0.55, green: 0.45, blue: 0.15).opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.8, blue: 0.2).opacity(0.5),
                                        Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                // 图标
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.8, blue: 0.2),
                                Color(red: 0.75, green: 0.55, blue: 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.2), radius: 20, x: 0, y: 10)

            VStack(spacing: 6) {
                Text(Strings.deviceInfo)
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.9, blue: 0.85),
                                Color(red: 0.75, green: 0.7, blue: 0.65)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(deviceManager.isConnected ? Color.green : (deviceManager.isDemoMode ? Color.orange : Color.gray))
                        .frame(width: 8, height: 8)
                        .shadow(color: deviceManager.isConnected ? Color.green.opacity(0.5) : (deviceManager.isDemoMode ? Color.orange.opacity(0.5) : Color.clear), radius: 4)
                    
                    Text(deviceManager.isDemoMode ? Strings.demoModeStatus : (deviceManager.isConnected ? Strings.connected : Strings.disconnected))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(deviceManager.isConnected ? Color.green : (deviceManager.isDemoMode ? Color.orange : Color(red: 0.5, green: 0.45, blue: 0.4)))
                }
            }
        }
        .padding(.vertical, 24)
    }

    // MARK: - 系统信息卡片
    @ViewBuilder
    private func buildSystemInfoCards() -> some View {
        VStack(spacing: 16) {
            if let info = systemInfo {
                // 第一组：电池和温度
                HStack(spacing: 12) {
                    InfoCard(
                        icon: "battery.100",
                        title: Strings.battery,
                        value: "\(Int(info.battery))%",
                        color: info.battery > 20 ? .green : .red
                    )

                    InfoCard(
                        icon: "thermometer",
                        title: Strings.temperature,
                        value: "\(Int(info.temperature))°C",
                        color: .orange
                    )
                }

                // 第二组：音量和亮度
                HStack(spacing: 12) {
                    InfoCard(
                        icon: "speaker.wave.2.fill",
                        title: Strings.volume,
                        value: "\(info.volume)%",
                        color: .purple
                    )

                    InfoCard(
                        icon: "sun.max.fill",
                        title: Strings.brightness,
                        value: "\(info.brightness)%",
                        color: .yellow
                    )
                }

                // 第三组：颜色和信号
                HStack(spacing: 12) {
                    InfoCard(
                        icon: "paintpalette.fill",
                        title: Strings.color,
                        value: "#\(info.color)",
                        color: Color(hex: info.color) ?? .white,
                        showColorPreview: true
                    )

                    InfoCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: Strings.signal,
                        value: "\(info.rssi) dBm",
                        color: .blue
                    )
                }

                // 第四组：剑刃状态和模式（分开展示）
                InfoCard(
                    icon: "bolt.fill",
                    title: Strings.bladeStatus,
                    value: info.bladeOn ? Strings.on : Strings.off,
                    color: info.bladeOn ? (Color(hex: info.color) ?? .red) : .gray
                )

                InfoCard(
                    icon: "gearshape.fill",
                    title: Strings.currentMode,
                    value: info.mode,
                    color: deviceManager.currentMode == .bluetooth ? .blue : .green
                )
            } else {
                buildNoDataState()
            }
        }
    }

    @ViewBuilder
    private func buildNoDataState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(Strings.noData)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(Strings.connectForData)
                    .font(.caption)
                    .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Proffieboard 内置配置
    @ViewBuilder
    private func buildProffieWorkbenchSection() -> some View {
        let canUseSettings = deviceManager.hasEverConnected || deviceManager.isDemoMode
        
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "wrench.fill", title: Strings.proffieboardConfig, gradient: [.purple, .cyan])

            if !canUseSettings {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text(Strings.pleaseConnectFirstForSettings)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            VStack(spacing: 12) {
                Button(action: {
                    showProffieConfig = true
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.proffieboardConfig)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Text(Strings.proffieboardConfigDesc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityLabel(Strings.proffieboardConfig)
                .accessibilityHint(Strings.proffieboardConfigDesc)

                Text(Strings.proffieboardConfigHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                    )
            )
            .disabled(!canUseSettings)
            .opacity(canUseSettings ? 1.0 : 0.5)
        }
    }

    // MARK: - 语言设置
    @ViewBuilder
    private func buildLanguageSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "globe", title: Strings.languageSettings, gradient: [.blue, .purple])

            VStack(spacing: 12) {
                ForEach(LanguageManager.shared.availableLanguages, id: \.code) { lang in
                    Button(action: {
                        LanguageManager.shared.setLanguage(lang.code)
                    }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LanguageManager.shared.language == lang.code ? 
                                          Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(LanguageManager.shared.language == lang.code ? .blue : .gray)
                            }

                            Text(lang.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)

                            Spacer()

                            if LanguageManager.shared.language == lang.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LanguageManager.shared.language == lang.code ? 
                                      Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - 音效设置
    @ViewBuilder
    private func buildSoundSection() -> some View {
        let canUseSettings = deviceManager.hasEverConnected || deviceManager.isDemoMode
        
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "speaker.wave.2.fill", title: "sound_settings".localized(), gradient: [.orange, .yellow])

            if !canUseSettings {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text(Strings.pleaseConnectFirstForSettings)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            VStack(spacing: 16) {
                buildSoundToggle()
                buildHapticToggle()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                    )
            )
            .disabled(!canUseSettings)
            .opacity(canUseSettings ? 1.0 : 0.5)
        }
    }
    
    @ViewBuilder
    private func buildSoundToggle() -> some View {
        Toggle(isOn: $soundManager.soundEnabled) {
            HStack(spacing: 12) {
                Image(systemName: soundManager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("enable_sound".localized())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text("enable_sound_desc".localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    @ViewBuilder
    private func buildHapticToggle() -> some View {
        Toggle(isOn: $soundManager.hapticEnabled) {
            HStack(spacing: 12) {
                Image(systemName: soundManager.hapticEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                    .font(.title2)
                    .foregroundColor(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("enable_haptic".localized())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text("enable_haptic_desc".localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private func buildConnectSoundSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("connect_sound".localized())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    soundManager.testConnectionSound()
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SoundManager.ConnectionSound.allCases) { sound in
                        SoundOptionButton(
                            title: sound.displayName,
                            isSelected: soundManager.connectionSound == sound,
                            color: .green
                        ) {
                            soundManager.connectionSound = sound
                            soundManager.testConnectionSound()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }

    @ViewBuilder
    private func buildDisconnectSoundSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("disconnect_sound".localized())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    soundManager.testDisconnectSound()
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SoundManager.DisconnectSound.allCases) { sound in
                        SoundOptionButton(
                            title: sound.displayName,
                            isSelected: soundManager.disconnectSound == sound,
                            color: .red
                        ) {
                            soundManager.disconnectSound = sound
                            soundManager.testDisconnectSound()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }
    
    // MARK: - 处理启动媒体选择
    private func handleStartupMediaSelection(item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                if item.supportedContentTypes.first?.conforms(to: .movie) == true || item.supportedContentTypes.first?.conforms(to: .video) == true {
                    guard let movieData = try await item.loadTransferable(type: Data.self) else { return }
                    let fileManager = FileManager.default
                    let docsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let destinationURL = docsDirectory.appendingPathComponent("startup_video.mp4")
                    
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try movieData.write(to: destinationURL)
                    
                    await MainActor.run {
                        customStartupMediaPath = destinationURL.absoluteString
                    }
                } else {
                    guard let imageData = try await item.loadTransferable(type: Data.self) else { return }
                    let fileManager = FileManager.default
                    let docsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let destinationURL = docsDirectory.appendingPathComponent("startup_image.png")
                    
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try imageData.write(to: destinationURL)
                    
                    await MainActor.run {
                        customStartupMediaPath = destinationURL.absoluteString
                    }
                }
            } catch {
                print("Error selecting startup media: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - APP启动设置
    @ViewBuilder
    private func buildStartupSection() -> some View {
        let canUseSettings = deviceManager.hasEverConnected || deviceManager.isDemoMode
        
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "photo.fill", title: Strings.appStartupSettings, gradient: [.purple, .pink])
            
            if !canUseSettings {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text(Strings.pleaseConnectFirstForSettings)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(customStartupMediaPath.isEmpty ? "select_startup_media".localized() : "custom_media_selected".localized())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Text("startup_media_desc".localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if !customStartupMediaPath.isEmpty {
                        Button(action: {
                            customStartupMediaPath = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    PhotosPicker(selection: $selectedStartupItem, matching: .any(of: [.images, .videos])) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                )
                
                if !customStartupMediaPath.isEmpty {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack {
                        Image(systemName: "aspectratio")
                            .font(.title2)
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("media_aspect_mode".localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Text("media_aspect_desc".localized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $startupMediaAspectMode) {
                            Text("fill_mode".localized()).tag(0)
                            Text("fit_mode".localized()).tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "timer")
                                .font(.title2)
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("video_duration".localized())
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                Text("video_duration_desc".localized())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Picker("", selection: $startupVideoDuration) {
                            Text("1s").tag(1)
                            Text("2s").tag(2)
                            Text("3s").tag(3)
                            Text("5s").tag(5)
                            Text("10s").tag(10)
                            Text("15s").tag(15)
                            Text("20s").tag(20)
                            Text("30s").tag(30)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                    )
            )
            .disabled(!canUseSettings)
            .opacity(canUseSettings ? 1.0 : 0.5)
            .onChange(of: selectedStartupItem) { oldValue, newValue in
                handleStartupMediaSelection(item: newValue)
            }
        }
    }

    // MARK: - OTA 固件升级
    @ViewBuilder
    private func buildOtaSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "arrow.down.circle.fill", title: "ota_upgrade".localized(), gradient: [.green, .teal])

            let canUseOta = deviceManager.hasEverConnected || deviceManager.isDemoMode

            if !canUseOta {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text(Strings.pleaseConnectFirstForSettings)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(canUseOta ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "cpu")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(canUseOta ? .green : .gray)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("current_version".localized())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(systemInfo?.firmwareVersion ?? (canUseOta ? "请连接设备查看" : "未连接"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(canUseOta ? .white : .gray)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canUseOta ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                )

                Button(action: {
                    showOtaFilePicker = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(canUseOta ? (selectedFirmwareURL != nil ? Color.green.opacity(0.2) : Color.blue.opacity(0.2)) : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: selectedFirmwareURL != nil ? "checkmark.circle.fill" : "doc.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canUseOta ? .white : .gray)
                        }
                        Text(selectedFirmwareURL != nil ? "firmware_selected".localized() : "select_firmware".localized())
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(canUseOta ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canUseOta ? (selectedFirmwareURL != nil ? Color.green : Color.blue) : Color.gray.opacity(0.3))
                            .shadow(color: canUseOta ? (selectedFirmwareURL != nil ? Color.green : Color.blue).opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
                    )
                }
                .disabled(!canUseOta || otaStatus == .transferring)

                if otaStatus == .transferring || otaStatus == .verifying {
                    VStack(spacing: 8) {
                        ProgressView(value: otaProgress) {
                            HStack {
                                Text("ota_progress".localized())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(otaProgress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                }

                if case .failed(let error) = otaStatus {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                }

                if otaStatus == .success {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("ota_success_message".localized())
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                }

                if selectedFirmwareURL != nil && otaStatus == .idle && canUseOta {
                    Button(action: {
                        startOtaUpgrade()
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Text("start_upgrade".localized())
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green)
                                .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .fileImporter(
            isPresented: $showOtaFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFirmwareSelection(result: result)
        }
    }

    // MARK: - OTA 升级方法
    private func startOtaUpgrade() {
        guard let url = selectedFirmwareURL else { return }
        startBleOta(firmwareFileUrl: url)
    }

    private func startBleOta(firmwareFileUrl: URL) {
        guard deviceManager.isConnected else {
            otaStatus = .failed("device_not_connected".localized())
            return
        }

        otaStatus = .preparing

        Task {
            do {
                _ = firmwareFileUrl.startAccessingSecurityScopedResource()
                defer { firmwareFileUrl.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: firmwareFileUrl)

                await MainActor.run {
                    otaStatus = .connecting
                }

                if let peripheral = deviceManager.bluetooth.connectedPeripheral {
                    OtaManager.shared.startBleOta(
                        firmwareData: data,
                        peripheral: peripheral
                    ) { progress in
                        DispatchQueue.main.async { [self] in
                            self.otaProgress = progress
                        }
                    }
                } else {
                    await MainActor.run {
                        otaStatus = .failed("ble_device_not_found".localized())
                    }
                }
            } catch {
                await MainActor.run {
                    otaStatus = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func handleFirmwareSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFirmwareURL = url
                otaStatus = .idle
                otaProgress = 0.0
            }
        case .failure(let error):
            otaStatus = .failed(error.localizedDescription)
        }
    }

    // MARK: - 关于
    @ViewBuilder
    private func buildAboutSection() -> some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(icon: "star.fill", title: Strings.about, gradient: [.purple, .blue])

            // 应用信息卡片
            VStack(spacing: 20) {
                // Logo和应用名称
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [goldColor.opacity(0.4), goldColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 64, height: 64)
                        Image(systemName: "wand.and.rays")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lightsaber Ctrl")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text(Strings.saberControlApp)
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }

                    Spacer()
                }

                Divider()
                    .background(goldColor.opacity(0.2))

                // 版本信息
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text(Strings.version)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(Strings.versionFormatted(appVersion, buildNumber))
                            .foregroundColor(.white)
                    }

                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        Text(Strings.developer)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Lightsaber Community")
                            .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(goldColor.opacity(0.15), lineWidth: 1)
                    )
            )

            // 链接按钮
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://lightsaber.app")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.cyan)
                        Text(Strings.officialWebsite)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cyan.opacity(0.1))
                    )
                }

                Link(destination: URL(string: "https://lightsaber.app/privacy")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.title3)
                            .foregroundColor(.purple)
                        Text(Strings.privacyPolicy)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                    )
                }

                Link(destination: URL(string: "https://lightsaber.app/support")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                            .foregroundColor(.orange)
                        Text(Strings.helpSupport)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
    }
}
