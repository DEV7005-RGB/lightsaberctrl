import Foundation
import AudioToolbox
import Combine
import AVFoundation
import UIKit

final class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // 语音合成器（使用lazy避免启动时的音频错误）
    private var _speechSynthesizer: AVSpeechSynthesizer?
    private var speechSynthesizer: AVSpeechSynthesizer {
        if let synth = _speechSynthesizer {
            return synth
        }
        let synth = AVSpeechSynthesizer()
        _speechSynthesizer = synth
        return synth
    }
    
    // MARK: - 可用音效选项
    enum ConnectionSound: String, CaseIterable, Identifiable {
        case voiceConnectedFemale = "voice_connected_female"
        case voiceConnectedMale = "voice_connected_male"
        case ascent = "ascent"
        case notification = "notification"

        var id: String { rawValue }

        var soundID: SystemSoundID? {
            switch self {
            case .voiceConnectedFemale: return nil
            case .voiceConnectedMale: return nil
            case .ascent: return 1304
            case .notification: return 1007
            }
        }

        var isVoice: Bool {
            switch self {
            case .voiceConnectedFemale, .voiceConnectedMale: return true
            default: return false
            }
        }

        var isMaleVoice: Bool {
            switch self {
            case .voiceConnectedMale: return true
            default: return false
            }
        }

        var displayName: String {
            switch self {
            case .voiceConnectedFemale:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "女声：已连接" : "Female: Connected"
            case .voiceConnectedMale:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "男声：已连接" : "Male: Connected"
            case .ascent:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "上升音" : "Ascent"
            case .notification:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "通知音" : "Notification"
            }
        }
    }

    enum DisconnectSound: String, CaseIterable, Identifiable {
        case voiceDisconnectedFemale = "voice_disconnected_female"
        case voiceDisconnectedMale = "voice_disconnected_male"
        case soft = "soft"
        case alert = "alert"

        var id: String { rawValue }

        var soundID: SystemSoundID? {
            switch self {
            case .voiceDisconnectedFemale: return nil
            case .voiceDisconnectedMale: return nil
            case .soft: return 1150
            case .alert: return 1005
            }
        }

        var isVoice: Bool {
            switch self {
            case .voiceDisconnectedFemale, .voiceDisconnectedMale: return true
            default: return false
            }
        }

        var isMaleVoice: Bool {
            switch self {
            case .voiceDisconnectedMale: return true
            default: return false
            }
        }

        var displayName: String {
            switch self {
            case .voiceDisconnectedFemale:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "女声：已断开" : "Female: Disconnected"
            case .voiceDisconnectedMale:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "男声：已断开" : "Male: Disconnected"
            case .soft:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "轻柔音" : "Soft"
            case .alert:
                let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                               LanguageManager.shared.locale.identifier.contains("zh")
                return isChinese ? "提示音" : "Alert"
            }
        }
    }

    // MARK: - 用户选择
    @Published var connectionSound: ConnectionSound {
        didSet {
            UserDefaults.standard.set(connectionSound.rawValue, forKey: "connectionSound")
        }
    }

    @Published var disconnectSound: DisconnectSound {
        didSet {
            UserDefaults.standard.set(disconnectSound.rawValue, forKey: "disconnectSound")
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    @Published var hapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled")
        }
    }

    // MARK: - 初始化
    private init() {
        print("🚀 [SoundManager] Initializing SoundManager...")
        
        // 初始化所有存储属性
        self.connectionSound = .voiceConnectedFemale
        self.disconnectSound = .voiceDisconnectedFemale
        self.soundEnabled = true
        self.hapticEnabled = true
        
        // 加载保存的设置
        if let savedConnection = UserDefaults.standard.string(forKey: "connectionSound"),
           let sound = ConnectionSound(rawValue: savedConnection) {
            self.connectionSound = sound
            print("🔍 [SoundManager] Loaded connectionSound: \(sound)")
        } else {
            print("🔍 [SoundManager] Using default connectionSound: voiceConnectedFemale")
        }

        if let savedDisconnect = UserDefaults.standard.string(forKey: "disconnectSound"),
           let sound = DisconnectSound(rawValue: savedDisconnect) {
            self.disconnectSound = sound
            print("🔍 [SoundManager] Loaded disconnectSound: \(sound)")
        } else {
            print("🔍 [SoundManager] Using default disconnectSound: voiceDisconnectedFemale")
        }

        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.hapticEnabled = UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true

        print("✅ [SoundManager] Initialization complete")
    }

    // MARK: - 播放音效
    func playConnectionSound() {
        if soundEnabled {
            if connectionSound.isVoice {
                speak(text: "已连接", isMale: connectionSound.isMaleVoice)
            } else if let soundID = connectionSound.soundID {
                playSoundWithVolume(soundID: soundID)
            }
        }
        playConnectionHaptic()
    }

    func playDisconnectSound() {
        if soundEnabled {
            if disconnectSound.isVoice {
                speak(text: "已断开", isMale: disconnectSound.isMaleVoice)
            } else if let soundID = disconnectSound.soundID {
                playSoundWithVolume(soundID: soundID)
            }
        }
        playDisconnectHaptic()
    }

    // MARK: - 震动反馈
    func playConnectionHaptic() {
        guard hapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func playDisconnectHaptic() {
        guard hapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    // MARK: - 测试音效
    func testConnectionSound() {
        if connectionSound.isVoice {
            speak(text: "已连接", isMale: connectionSound.isMaleVoice)
        } else if let soundID = connectionSound.soundID {
            playSoundWithVolume(soundID: soundID)
        }
    }

    func testDisconnectSound() {
        if disconnectSound.isVoice {
            speak(text: "已断开", isMale: disconnectSound.isMaleVoice)
        } else if let soundID = disconnectSound.soundID {
            playSoundWithVolume(soundID: soundID)
        }
    }

    // MARK: - 音效播放
    private func playSoundWithVolume(soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - 语音合成
    private func speak(text: String, isMale: Bool = false) {
        // 延迟到第一次使用时才真正初始化语音合成器
        let synth = speechSynthesizer
        
        // 停止当前正在播放的语音
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        
        // 检测当前语言
        let isChinese = LanguageManager.shared.language == "zh-Hans" || 
                       LanguageManager.shared.locale.identifier.contains("zh")
        
        // 根据语言选择对应的文本
        let actualText: String
        if text == "已连接" {
            actualText = isChinese ? "已连接" : "Connected"
        } else if text == "已断开" {
            actualText = isChinese ? "已断开" : "Disconnected"
        } else {
            actualText = text
        }
        
        let utterance = AVSpeechUtterance(string: actualText)
        
        // 根据语言和性别选择对应的语音
        if isChinese {
            // 尝试找到合适的中文语音
            let voices = AVSpeechSynthesisVoice.speechVoices()
            let chineseVoices = voices.filter { $0.language.contains("zh") }
            
            if let voice = chineseVoices.first {
                // 如果找到中文语音，根据性别调整音调
                utterance.voice = voice
                utterance.pitchMultiplier = isMale ? 0.5 : 1.2
            } else if let voice = AVSpeechSynthesisVoice(language: "zh-CN") {
                utterance.voice = voice
                utterance.pitchMultiplier = isMale ? 0.5 : 1.2
            } else if let voice = AVSpeechSynthesisVoice(language: "zh-Hans") {
                utterance.voice = voice
                utterance.pitchMultiplier = isMale ? 0.5 : 1.2
            } else {
                // 降级到英文
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.pitchMultiplier = isMale ? 0.5 : 1.2
            }
        } else {
            // 英文语音
            let voices = AVSpeechSynthesisVoice.speechVoices()
            let englishVoices = voices.filter { $0.language.contains("en") }
            
            if let voice = englishVoices.first {
                utterance.voice = voice
                utterance.pitchMultiplier = isMale ? 0.5 : 1.2
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.pitchMultiplier = isMale ? 0.5 : 1.2
            }
        }
        
        utterance.rate = 0.45
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.1
        
        // 在主线程上播放语音
        DispatchQueue.main.async {
            synth.speak(utterance)
        }
    }
}
