import SwiftUI

// MARK: - 内置Proffieboard配置视图
struct ProffieboardConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var deviceManager: DeviceManager

    var body: some View {
        NavigationView {
            ZStack {
                buildBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        buildStatusHeader()
                        buildHelpSection()
                    }
                    .padding(20)
                }
            }
            .navigationTitle(Strings.configTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.done) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }

    // MARK: - 背景
    private func buildBackground() -> some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.02, green: 0.02, blue: 0.05),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - 状态头部（包含自动重连模块）
    @ViewBuilder
    private func buildStatusHeader() -> some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [goldColor.opacity(0.3), goldColor.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(goldColor.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: goldColor.opacity(0.3), radius: 12, x: 0, y: 6)

            VStack(spacing: 4) {
                Text(Strings.configTitle)
                    .font(.title3.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                HStack(spacing: 6) {
                    Circle()
                        .fill(deviceManager.isConnected ? Color(red: 0.2, green: 0.8, blue: 0.2) : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(deviceManager.isConnected ? Strings.connectedStatus : Strings.disconnectedStatus)
                        .font(.caption)
                        .foregroundColor(deviceManager.isConnected ? Color(red: 0.3, green: 0.8, blue: 0.3) : .secondary)
                }
            }
            
            // 自动重连开关
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(Strings.autoReconnect)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { deviceManager.autoReconnectEnabled },
                    set: { deviceManager.autoReconnectEnabled = $0 }
                ))
                .labelsHidden()
                .tint(goldColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(goldColor.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .padding(.vertical, 8)
    }

    // MARK: - 使用说明
    @ViewBuilder
    private func buildHelpSection() -> some View {
        ConfigSection(title: Strings.helpTitle, icon: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 8) {
                helpRow(number: "1", text: "此功能通过蓝牙串口命令直接配置 Proffieboard")
                helpRow(number: "2", text: "音量、亮度、预设等修改会立即生效")
                helpRow(number: "3", text: "点击预设颜色快速切换光剑颜色")
                helpRow(number: "4", text: "需要光剑先点火才能切换颜色")
                helpRow(number: "5", text: "需要 ProffieOS 7.x 或以上版本支持")
                helpRow(number: "6", text: "此功能不依赖 Web Bluetooth，可在 iOS 中正常使用")
            }
        }
    }

    private func helpRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.caption.bold())
                .foregroundColor(.cyan)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.cyan.opacity(0.2)))
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 配置分组组件
struct ConfigSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            content
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
                                .stroke(goldColor.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
    }
}
