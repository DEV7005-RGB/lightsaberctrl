import SwiftUI

// MARK: - 通用组件库

// MARK: - SectionHeader
struct SectionHeader: View {
    let icon: String
    let title: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                gradient[0].opacity(0.25),
                                gradient[1].opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        gradient[0].opacity(0.4),
                                        gradient[1].opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [gradient[0], gradient[1]],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.9, blue: 0.85),
                            Color(red: 0.7, green: 0.65, blue: 0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 操作按钮
struct SaberActionButton: View {
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
            case .small: return 18
            case .medium: return 24
            case .large: return 32
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 16
            }
        }

        var buttonHeight: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 60
            }
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = false
                }
            }
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
        }) {
            HStack(spacing: size == .large ? 12 : 8) {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundColor(isActive ? color : .white)
            .frame(height: size.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                    .fill(isActive ? color.opacity(0.2) : Color.white.opacity(0.1))
                    .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: isPressed ? 15 : 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                    .stroke(isActive ? color : Color.white.opacity(0.3), lineWidth: isPressed ? 3 : 2)
            )
            .scaleEffect(isPressed ? 1.05 : (isActive ? 1.02 : 1.0))
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isActive ? "当前激活" : "点击触发")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - 设备卡片
struct DeviceCard: View {
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
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    SignalStrengthIndicator(strength: signalStrength)

                    if isLastConnected && !isConnected {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                            .offset(x: 8, y: -4)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        if isLastConnected && !isConnected {
                            Text("上次")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.2)))
                        }
                    }
                    HStack(spacing: 4) {
                        Text(alias != nil ? "ID: \(deviceId ?? "----")" : name)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        if deviceId != nil {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange.opacity(0.7))
                        }
                    }
                    Text(isConnecting ? "连接中..." : "信号强度: \(abs(rssi)) dBm")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title)
                } else if isConnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                } else {
                    Button(action: {
                        editedAlias = alias ?? ""
                        showAliasEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                Group {
                    if isConnecting {
                        RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.1))
                    } else if isLastConnected && !isConnected {
                        RoundedRectangle(cornerRadius: 16).fill(Color.orange.opacity(0.08))
                    } else {
                        RoundedRectangle(cornerRadius: 16).fill(LinearGradient(
                            colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(isConnecting)
        .alert("设备备注", isPresented: $showAliasEditor) {
            TextField("输入备注名称", text: $editedAlias)
            Button("保存") {
                onAliasChanged(editedAlias)
            }
            Button("取消", role: .cancel) {}
            if !(alias ?? "").isEmpty {
                Button("删除备注", role: .destructive) {
                    onAliasChanged("")
                }
            }
        } message: {
            Text("为 \"\(name)\" 设置备注名称，方便区分多个设备")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName), 信号强度\(signalStrength)格, \(isConnected ? "已连接" : isConnecting ? "连接中" : "未连接")")
        .accessibilityAddTraits(isConnected ? .isSelected : [])
    }
}

// MARK: - 信号强度指示器
struct SignalStrengthIndicator: View {
    let strength: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...4, id: \.self) { i in
                Capsule()
                    .fill(i <= strength ? .green : Color.white.opacity(0.2))
                    .frame(width: 4, height: CGFloat(4 + i * 3))
            }
        }
    }
}

// MARK: - 信息卡片
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let showColorPreview: Bool

    init(icon: String, title: String, value: String, color: Color, showColorPreview: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.showColorPreview = showColorPreview
    }

    var body: some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // 图标区域
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.25),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            color.opacity(0.4),
                                            color.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.9), color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // 标题和值
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.45))
                    
                    HStack(spacing: 8) {
                        if showColorPreview {
                            Circle()
                                .fill(color)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                        
                        Text(value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.92, blue: 0.88),
                                        Color(red: 0.72, green: 0.68, blue: 0.64)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }

                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.11, blue: 0.14),
                            Color(red: 0.08, green: 0.08, blue: 0.11)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    goldColor.opacity(0.2),
                                    goldColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - 连接状态指示器
struct ConnectionStatusBadge: View {
    let isConnected: Bool
    let mode: ConnectionMode

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(mode.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((isConnected ? Color.green : Color.orange).opacity(0.2))
        )
        .foregroundColor(isConnected ? .green : .orange)
    }
}

// MARK: - 状态指示灯
struct StatusIndicator: View {
    let isOn: Bool
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isOn ? 0.3 : 0.1))
                .frame(width: 20, height: 20)
            Circle()
                .fill(isOn ? color : Color.white.opacity(0.3))
                .frame(width: 10, height: 10)
                .shadow(color: isOn ? color.opacity(0.5) : .clear, radius: 5)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}

// MARK: - 科幻风格滑块
struct SciFiSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let label: String
    let unit: String
    let color: Color
    let action: (() -> Void)?

    init(value: Binding<Double>, range: ClosedRange<Double>, label: String, unit: String, color: Color, action: (() -> Void)? = nil) {
        self._value = value
        self.range = range
        self.label = label
        self.unit = unit
        self.color = color
        self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }

            GeometryReader { geometry in
                let width = geometry.size.width
                let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [color.opacity(0.5), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 8)
                        .frame(width: CGFloat(normalizedValue) * width)

                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .shadow(color: color.opacity(0.5), radius: 8)
                        .offset(x: CGFloat(normalizedValue) * width - 12)
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let newValue = (gesture.location.x / width) * (range.upperBound - range.lowerBound) + range.lowerBound
                            value = max(range.lowerBound, min(range.upperBound, newValue))
                        }
                        .onEnded { _ in
                            action?()
                        }
                )
            }
            .frame(height: 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(Text("\(Int(value))\(unit)"))
    }
}

// MARK: - 颜色选择按钮
struct ColorButton: View {
    let colorOption: ColorOption
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(colorOption.color.opacity(isSelected ? 0.3 : 0.15))
                    .frame(width: isSelected ? 60 : 52, height: isSelected ? 60 : 52)

                Circle()
                    .fill(isDisabled ? colorOption.color.opacity(0.3) : colorOption.color)
                    .frame(width: UIConstants.colorButtonSize, height: UIConstants.colorButtonSize)
                    .shadow(color: isDisabled ? .clear : colorOption.color.opacity(0.5), radius: UIConstants.smallShadowRadius + 2, x: 0, y: 3)

                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: UIConstants.colorButtonStrokeWidth)
                        .frame(width: UIConstants.colorButtonSize, height: UIConstants.colorButtonSize)
                    Image(systemName: "checkmark")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }

                if isDisabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
        .accessibilityLabel("\(colorOption.name)颜色\(isDisabled ? "（需开启剑刃）" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isDisabled ? "请先开启剑刃" : "双击选择此颜色")
    }
}

// MARK: - 预设按钮
struct PresetButton: View {
    let preset: SaberPreset
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isDisabled ? preset.color.opacity(0.1) : preset.color.opacity(isSelected ? 0.4 : 0.2))
                        .frame(width: isSelected ? 44 : 38, height: isSelected ? 44 : 38)

                    Circle()
                        .fill(isDisabled ? preset.color.opacity(0.3) : preset.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: isDisabled ? .clear : preset.color.opacity(0.5), radius: isSelected ? 6 : 2, x: 0, y: isSelected ? 4 : 1)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }

                    if isDisabled {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                if preset.hasSound && !isDisabled {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? preset.color.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? preset.color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
        .accessibilityLabel("\(preset.name)预设\(preset.index)\(isDisabled ? "（需开启剑刃）" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isDisabled ? "请先开启剑刃" : "双击选择此预设")
    }
}

// MARK: - 科幻背景
struct SciFiBackground: View {
    let isScanning: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.10, green: 0.10, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GridShape()
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 400, height: 800)
                .rotationEffect(.degrees(15))
                .offset(x: -50, y: -100)
        }
    }
}

struct GridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40

        for x in stride(from: 0, through: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        for y in stride(from: 0, through: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
    }
}

// MARK: - 扫描动画
struct ScanningIndicator: View {
    let isScanning: Bool
    let mode: ConnectionMode

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: isScanning ? 0.7 : 0)
                .stroke(
                    LinearGradient(
                        colors: mode == .bluetooth ? [.blue, .cyan] : [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(isScanning ? .linear(duration: 1.5).repeatForever(autoreverses: false) : .none, value: isScanning)

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(mode == .bluetooth ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 90, height: 90)

                    Image(systemName: mode == .bluetooth ? "dot.radiowaves.left.and.right" : "wifi.circle")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: mode == .bluetooth ? [.blue, .cyan] : [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, isActive: isScanning)
                }

                if isScanning {
                    Text("搜索中")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 成功提示
struct SuccessToast: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.15, green: 0.15, blue: 0.18), Color(red: 0.1, green: 0.1, blue: 0.13)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: isShowing)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - 快速预设选择器 (专业玩家优化)
/// 用于在战斗中快速切换预设的水平滚动选择器
struct QuickPresetCarousel: View {
    let presets: [SaberPreset]
    @Binding var selectedIndex: Int
    let onSelect: (Int) -> Void
    
    @State private var scrollPosition: Int?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("快速切换")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                            QuickPresetItem(
                                preset: preset,
                                isSelected: index == selectedIndex,
                                index: index
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedIndex = index
                                    onSelect(index)
                                }
                                // 触发触感反馈
                                #if os(iOS)
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                #endif
                            }
                            .id(index)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 70)
                .onChange(of: selectedIndex) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("预设快速切换")
        .accessibilityHint("左右滑动选择不同预设")
    }
}

// MARK: - 快速预设项
struct QuickPresetItem: View {
    let preset: SaberPreset
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(preset.color.opacity(isSelected ? 0.5 : 0.2))
                        .frame(width: isSelected ? 50 : 42, height: isSelected ? 50 : 42)
                    
                    Circle()
                        .fill(preset.color)
                        .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                        .shadow(color: preset.color.opacity(0.6), radius: isSelected ? 8 : 4)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }
                
                Text("\(index)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .accessibilityLabel("\(preset.name)预设\(index)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 专业战斗模式提示
struct CombatModeIndicator: View {
    let isConnected: Bool
    let bladeOn: Bool
    let currentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 连接状态
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: isConnected ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 4)
            
            Text(isConnected ? "已连接" : "未连接")
                .font(.caption)
                .foregroundColor(isConnected ? .green : .red)
            
            if isConnected {
                Divider()
                    .frame(height: 12)
                
                // 剑刃状态
                Circle()
                    .fill(bladeOn ? currentColor : Color.gray)
                    .frame(width: 8, height: 8)
                    .shadow(color: bladeOn ? currentColor.opacity(0.5) : Color.clear, radius: 4)
                
                Text(bladeOn ? "剑刃开启" : "剑刃关闭")
                    .font(.caption)
                    .foregroundColor(bladeOn ? currentColor : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - 步骤说明项
struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
    }
}

// MARK: - WiFi密码修改Sheet
struct WiFiPasswordChangeSheet: View {
    @Binding var isPresented: Bool
    @Binding var newPassword: String
    let onResetDefault: () -> Void
    let onChangePassword: () -> Void
    @State private var showPassword = false
    @State private var localPassword = ""

    private var isPasswordValid: Bool {
        localPassword.count >= 8 && localPassword.count <= 32
    }

    private var passwordHint: String {
        if localPassword.isEmpty {
            return "密码长度8-32位"
        } else if localPassword.count < 8 {
            return "密码至少8位"
        } else {
            return "密码格式正确"
        }
    }

    private var passwordHintColor: Color {
        if localPassword.isEmpty {
            return .secondary
        } else if localPassword.count < 8 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "key.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.purple)
                            }

                            Text("修改WiFi密码")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("当前默认密码: lightsaber")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("新密码")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))

                            HStack {
                                if showPassword {
                                    TextField("请输入新密码", text: $localPassword)
                                        .textFieldStyle(.plain)
                                } else {
                                    SecureField("请输入新密码", text: $localPassword)
                                        .textFieldStyle(.plain)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isPasswordValid ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            HStack {
                                Image(systemName: localPassword.isEmpty ? "info.circle" : (localPassword.count >= 8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill"))
                                    .foregroundColor(passwordHintColor)

                                Text(passwordHint)
                                    .font(.caption)
                                    .foregroundColor(passwordHintColor)
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 16) {
                            Button(action: {
                                if isPasswordValid {
                                    newPassword = localPassword
                                    onChangePassword()
                                    isPresented = false
                                    localPassword = ""
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("确认修改")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isPasswordValid ? Color.purple : Color.gray.opacity(0.5))
                                )
                            }
                            .disabled(!isPasswordValid)

                            Button(action: {
                                onResetDefault()
                                isPresented = false
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("重置为默认密码")
                                }
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.purple, lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 8) {
                            Text("提示")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))

                            Text("修改密码后需要使用新密码连接WiFi")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        localPassword = ""
                        newPassword = ""
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .onAppear {
            localPassword = newPassword
        }
    }
}

// MARK: - 音效选项按钮
struct SoundOptionButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
