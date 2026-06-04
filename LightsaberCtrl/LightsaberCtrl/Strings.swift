import Foundation

struct Strings {
    // Helper function to get localized string based on current language
    private static func localized(_ key: String) -> String {
        let bundle = LanguageManager.shared.stringsBundle
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
    
    // Helper function for formatted strings
    private static func localized(_ key: String, with arguments: CVarArg...) -> String {
        let bundle = LanguageManager.shared.stringsBundle
        let format = NSLocalizedString(key, bundle: bundle, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    static var control: String { localized("control") }
    static var connect: String { localized("connect") }
    static var info: String { localized("info") }
    
    static var smartSaberController: String { localized("smart_saber_controller") }
    
    static var connected: String { localized("connected") }
    static var disconnected: String { localized("disconnected") }
    static var saberReady: String { localized("saber_ready") }
    static var pleasePairFirst: String { localized("please_pair_first") }
    static var pleaseConnectFirst: String { localized("please_connect_first") }
    
    static var quickActions: String { localized("quick_actions") }
    static var ignition: String { localized("ignition") }
    static var retract: String { localized("retract") }
    static var blaster: String { localized("blaster") }
    static var clash: String { localized("clash") }
    static var lockup: String { localized("lockup") }
    
    static var colorSelection: String { localized("color_selection") }
    static var tipRotateSaber: String { localized("tip_rotate_saber") }
    static var startColorSelection: String { localized("start_color_selection") }
    static var selectingColor: String { localized("selecting_color") }
    static var save: String { localized("save") }
    static var cancel: String { localized("cancel") }
    static var canceled: String { localized("canceled") }
    static var colorSet: String { localized("color_set") }
    static var colorSaved: String { localized("color_saved") }
    static var enteredColorMode: String { localized("entered_color_mode") }
    
    static var settings: String { localized("settings") }
    static var volume: String { localized("volume") }
    static var brightness: String { localized("brightness") }
    
    static var presets: String { localized("presets") }
    static var previousPreset: String { localized("previous_preset") }
    static var nextPreset: String { localized("next_preset") }
    static var currentPreset: String { String(format: localized("current_preset"), "%@") }
    static var presetChanged: String { String(format: localized("preset_changed"), "%@") }
    static var previous: String { String(format: localized("previous"), "%@") }
    static var next: String { String(format: localized("next"), "%@") }
    
    static var deviceConnection: String { localized("device_connection") }
    static var startScanning: String { localized("start_scanning") }
    static var stopScanning: String { localized("stop_scanning") }
    static var disconnect: String { localized("disconnect") }
    static var connectDevice: String { localized("connect_device") }
    static var foundDevices: String { localized("found_devices") }
    static var unknownDevice: String { localized("unknown_device") }
    static var noDevicesFound: String { localized("no_devices_found") }
    static var ensureInRange: String { localized("ensure_in_range") }
    
    static var additionalFeatures: String { localized("additional_features") }
    static var demoMode: String { localized("demo_mode") }
    static var demoModeDesc: String { localized("demo_mode_desc") }
    
    static var deviceInfo: String { localized("device_info") }
    static var demoModeStatus: String { localized("demo_mode_status") }
    static var battery: String { localized("battery") }
    static var temperature: String { localized("temperature") }
    static var signal: String { localized("signal") }
    static var bladeStatus: String { localized("blade_status") }
    static var on: String { localized("on") }
    static var off: String { localized("off") }
    static var currentMode: String { localized("current_mode") }
    static var noData: String { localized("no_data") }
    static var connectForData: String { localized("connect_for_data") }
    static var color: String { localized("color") }
    
    static var appInfo: String { localized("app_info") }
    static var version: String { localized("version") }
    static var minimumRequired: String { localized("minimum_required") }
    static var developer: String { localized("developer") }
    
    static var onlineConfigurator: String { localized("online_configurator") }
    static var configuratorDesc: String { localized("configurator_desc") }
    static var openInSafari: String { localized("open_in_safari") }
    static var workbenchDesc: String { localized("workbench_desc") }
    
    static var about: String { localized("about") }
    static var officialWebsite: String { localized("official_website") }
    static var privacyPolicy: String { localized("privacy_policy") }
    static var viewPrivacyPolicy: String { localized("view_privacy_policy") }
    static var helpSupport: String { localized("help_support") }
    static var getHelp: String { localized("get_help") }
    static var allRightsReserved: String { localized("all_rights_reserved") }
    
    static var bluetooth: String { localized("bluetooth") }
    static var wifi: String { localized("wifi") }
    static var ensureWifiConnected: String { localized("ensure_wifi_connected") }
    
    static var red: String { localized("red") }
    static var green: String { localized("green") }
    static var blue: String { localized("blue") }
    static var yellow: String { localized("yellow") }
    static var cyan: String { localized("cyan") }
    static var purple: String { localized("purple") }
    static var white: String { localized("white") }
    static var orange: String { localized("orange") }
    
    // Language settings
    static var language: String { localized("language") }
    static var languageSettings: String { localized("language_settings") }
    static var systemDefault: String { localized("system_default") }
    static var currentLanguage: String { localized("current_language") }
    
    // Proffieboard config
    static var proffieboardConfig: String { localized("proffieboard_config") }
    static var proffieboardConfigDesc: String { localized("proffieboard_config_desc") }
    static var proffieboardConfigHint: String { localized("proffieboard_config_hint") }
    
    // App startup
    static var appStartupSettings: String { localized("app_startup_settings") }
    static var pleaseConnectFirstForSettings: String { localized("please_connect_first_for_settings") }
    
    // About section
    static var saberControlApp: String { localized("saber_control_app") }
    static func versionFormatted(_ version: String, _ build: String) -> String { localized("version_formatted", with: version, build) }
    static var contactUs: String { localized("contact_us") }
    static var followUs: String { localized("follow_us") }
    static var madeWithLove: String { localized("made_with_love") }
    
    // Proffieboard config view
    static var done: String { localized("done") }
    static var success: String { localized("success") }
    static var ok: String { localized("ok") }
    static var error: String { localized("error") }
    static var configTitle: String { localized("config_title") }
    static var connectedStatus: String { localized("connected_status") }
    static var disconnectedStatus: String { localized("disconnected_status") }
    static var autoReconnect: String { localized("auto_reconnect") }
    static var presetSelection: String { localized("preset_selection") }
    static var currentUsing: String { localized("current_using") }
    static var totalPresets: String { localized("total_presets") }
    static var colorSettings: String { localized("color_settings") }
    static var currentColor: String { localized("current_color") }
    static var custom: String { localized("custom") }
    static var presetColors: String { localized("preset_colors") }
    static var customColor: String { localized("custom_color") }
    static var applyColor: String { localized("apply_color") }
    static var redColor: String { localized("red_color") }
    static var greenColor: String { localized("green_color") }
    static var blueColor: String { localized("blue_color") }
    static var volumeAdjustment: String { localized("volume_adjustment") }
    static var muted: String { localized("muted") }
    static var unmuted: String { localized("unmuted") }
    static var brightnessAdjustment: String { localized("brightness_adjustment") }
    static var proffieOsRange: String { localized("proffie_os_range") }
    static var advancedSettings: String { localized("advanced_settings") }
    static var clashSensitivity: String { localized("clash_sensitivity") }
    static var clashHint: String { localized("clash_hint") }
    static var refreshStatus: String { localized("refresh_status") }
    static var rebootSaber: String { localized("reboot_saber") }
    static var helpTitle: String { localized("help_title") }
    static var help1: String { localized("help_1") }
    static var help2: String { localized("help_2") }
    static var help3: String { localized("help_3") }
    static var help4: String { localized("help_4") }
    static var help5: String { localized("help_5") }
    static var help6: String { localized("help_6") }
    static var presetChangedTo: String { localized("preset_changed_to") }
    static var colorSetTo: String { localized("color_set_to") }
    static var volumeSetTo: String { localized("volume_set_to") }
    static var brightnessSetTo: String { localized("brightness_set_to") }
    static var clashSetTo: String { localized("clash_set_to") }
    static var refreshing: String { localized("refreshing") }
    static var rebooting: String { localized("rebooting") }
    
    // Battery warning
    static var batteryLow: String { localized("battery_low") }
    static var batteryCritical: String { localized("battery_critical") }
    static var batteryVoltage: String { localized("battery_voltage") }
    static var pleaseCharge: String { localized("please_charge") }
    static var gotIt: String { localized("got_it") }
}
