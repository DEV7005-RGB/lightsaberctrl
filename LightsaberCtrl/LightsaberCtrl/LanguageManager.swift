import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("appLanguage") var language: String = "system" {
        didSet {
            updateLocale()
        }
    }
    
    @Published var locale: Locale = .current
    
    private init() {
        updateLocale()
    }
    
    var currentLanguageName: String {
        switch language {
        case "zh-Hans":
            return "简体中文"
        case "en":
            return "English"
        default:
            return "System Default"
        }
    }
    
    var availableLanguages: [(code: String, name: String)] {
        [
            ("system", "System Default"),
            ("zh-Hans", "简体中文"),
            ("en", "English")
        ]
    }
    
    func setLanguage(_ code: String) {
        language = code
    }
    
    private func updateLocale() {
        if language == "system" {
            locale = .current
        } else {
            locale = Locale(identifier: language)
        }
        
        // Update Bundle to use the selected language
        if let bundlePath = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            stringsBundle = bundle
        } else {
            stringsBundle = Bundle.main
        }
    }
    
    // Custom bundle for localization
    @Published var stringsBundle: Bundle = Bundle.main
}

// MARK: - Localized String Helper
extension String {
    func localized(from bundle: Bundle = LanguageManager.shared.stringsBundle) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    func localized(with arguments: CVarArg..., from bundle: Bundle = LanguageManager.shared.stringsBundle) -> String {
        return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), arguments: arguments)
    }
}

// MARK: - View Extension for Language Change Observation
extension View {
    func observeLanguageChanges() -> some View {
        self.environment(\.locale, LanguageManager.shared.locale)
    }
}
