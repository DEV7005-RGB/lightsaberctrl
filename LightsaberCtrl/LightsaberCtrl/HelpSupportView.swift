import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Section(header: Text("使用指南").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("欢迎使用光剑控制应用！以下是使用说明：")
                    }
                    
                    Section(header: Text("1. 连接设备").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("步骤：")
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. 确保光剑设备已开机并进入蓝牙模式")
                                Text("2. 打开应用，点击底部导航栏的「连接」图标")
                                Text("3. 在设备列表中找到您的刀剑设备（名称以 blade- 或 glow- 开头）")
                                Text("4. 点击设备名称进行连接")
                                Text("5. 连接成功后，设备名称会显示为绿色")
                            }
                        }
                    }
                    
                    Section(header: Text("2. 控制光剑").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("连接成功后，您可以：")
                            VStack(alignment: .leading, spacing: 8) {
                                Text("- 点击「点火」按钮开启光剑")
                                Text("- 点击「熄火」按钮关闭光剑")
                                Text("- 滑动预设切换器选择不同的颜色预设")
                                Text("- 调整音量和亮度滑块")
                                Text("- 点击特效按钮触发特殊效果（如爆炸、撞击等）")
                            }
                        }
                    }
                    
                    Section(header: Text("3. 预设管理").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("- 应用提供24个预设颜色供选择")
                            Text("- 点击预设网格中的颜色可以快速切换")
                            Text("- 使用左右箭头按钮可以逐个切换预设")
                            Text("- 当前预设会在应用顶部显示")
                        }
                    }
                    
                    Section(header: Text("4. 常见问题").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        
                        Text("Q: 无法找到设备？")
                        Text("A: 请确保光剑设备已开机并进入蓝牙模式，同时确保手机蓝牙已开启。")
                        
                        Text("Q: 连接后无法控制？")
                        Text("A: 请尝试断开连接后重新连接，或重启光剑设备。")
                        
                        Text("Q: 音效不播放？")
                        Text("A: 请确保光剑设备已正确安装音效文件，并在应用中调整音量设置。")
                        
                        Text("Q: 如何更新固件？")
                        Text("A: 在「信息」页面中，点击「固件更新」选项进行OTA升级。")
                    }
                    
                    Section(header: Text("5. 支持的功能").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("- 预设切换")
                            Text("- 颜色设置")
                            Text("- 音量控制")
                            Text("- 亮度控制")
                            Text("- 撞击灵敏度调整")
                            Text("- 静音开关")
                            Text("- 蓝牙/WiFi模式切换")
                            Text("- OTA固件升级")
                        }
                    }
                    
                    Section(header: Text("6. 联系我们").font(.title2).fontWeight(.bold).foregroundColor(.white)) {
                        Text("如果您遇到问题或有任何建议，请联系我们：")
                        Text("dev7005@163.com")
                    }
                    
                    Text("版本：2.1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(24)
            }
            .background(Color.black)
            .navigationTitle(Strings.helpSupport)
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