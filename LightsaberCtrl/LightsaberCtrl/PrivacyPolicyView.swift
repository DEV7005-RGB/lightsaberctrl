import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Section(header: Text("1. 信息收集").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("本应用重视您的隐私。我们不会收集、存储或传输您的个人身份信息。")
                        Text("当您使用本应用时：")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("- 蓝牙连接信息仅用于与光剑设备通信，不会被记录或上传")
                            Text("- 应用设置（如颜色偏好、音量设置）仅存储在您的设备上")
                            Text("- 我们不会收集您的位置、通讯录或其他个人数据")
                        }
                    }
                    
                    Section(header: Text("2. 数据存储").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("所有应用数据均存储在您的设备本地：")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("- 应用配置和用户偏好存储在 iOS 的 UserDefaults 中")
                            Text("- 蓝牙设备信息仅在连接期间临时使用")
                            Text("- 没有任何数据会被发送到外部服务器")
                        }
                    }
                    
                    Section(header: Text("3. 蓝牙通信").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("本应用通过蓝牙与光剑设备进行通信：")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("- 通信内容包括颜色设置、音量控制、预设切换等")
                            Text("- 所有通信均为本地点对点连接")
                            Text("- 不会通过互联网传输任何数据")
                        }
                    }
                    
                    Section(header: Text("4. 第三方服务").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("本应用不使用任何第三方分析服务、广告服务或数据追踪工具。")
                    }
                    
                    Section(header: Text("5. 儿童隐私").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("本应用适合所有年龄段用户使用，不会有意收集儿童信息。")
                    }
                    
                    Section(header: Text("6. 隐私政策变更").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("我们可能会不时更新本隐私政策。更新后我们会在应用内通知用户。")
                    }
                    
                    Section(header: Text("联系我们").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("如果您对隐私政策有任何疑问，请通过以下方式联系我们：")
                        Text("dev7005@163.com")
                    }
                    
                    Text("最后更新：2026年6月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(24)
            }
            .background(Color.black)
            .navigationTitle(Strings.privacyPolicy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.back) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}