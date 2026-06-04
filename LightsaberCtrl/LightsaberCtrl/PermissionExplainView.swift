import SwiftUI

struct PermissionExplainView: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // 内容卡片
            VStack(spacing: 0) {
                // 头部图标区域
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [goldColor.opacity(0.3), goldColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(goldColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 28)
                
                // 标题
                Text("需要权限授权")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.bottom, 12)
                
                // 说明文字
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(goldColor.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(goldColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "bluetooth")
                                .font(.title)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("蓝牙权限")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("用于连接和控制您的光剑设备，发送控制命令并接收设备状态信息")
                                .font(.body)
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                                .lineLimit(nil)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(goldColor.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(goldColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "location.fill")
                                .font(.title)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("位置权限")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("iOS系统要求位置权限才能扫描蓝牙设备，此权限仅用于发现附近的光剑，不收集或共享位置信息")
                                .font(.body)
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // 底部按钮区域
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        onConfirm()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                            Text("确认授权")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .foregroundColor(.black)
                        .shadow(color: goldColor.opacity(0.4), radius: 10, x: 0, y: 6)
                    }
                    
                    Button(action: {
                        isPresented = false
                        onCancel()
                    }) {
                        Text("稍后设置")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                            .padding(16)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(goldColor.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
    }
}

struct PermissionDeniedView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // 内容卡片
            VStack(spacing: 0) {
                // 头部图标区域
                ZStack {
                    Circle()
                        .fill(goldColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(goldColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 28)
                
                // 标题
                Text("权限被拒绝")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.bottom, 12)
                
                // 说明文字
                VStack(spacing: 8) {
                    Text("蓝牙或位置权限未开启，无法扫描设备")
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.7, green: 0.65, blue: 0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text("请在系统设置中开启权限后重试")
                        .font(.body)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // 底部按钮区域
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "gear")
                                .font(.title)
                            Text("前往设置")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.8, blue: 0.2), Color(red: 0.75, green: 0.55, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .foregroundColor(.black)
                        .shadow(color: goldColor.opacity(0.4), radius: 10, x: 0, y: 6)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("取消")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                            .padding(16)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.1, blue: 0.12), Color(red: 0.07, green: 0.07, blue: 0.09)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(goldColor.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
    }
}
