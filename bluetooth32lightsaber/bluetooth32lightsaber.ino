/*
 * Lightsaber Controller - ProffieBoard 蓝牙/WiFi 控制器固件
 *
 * 支持通过 Web 配置页面选择连接模式
 * 蓝牙和 WiFi 不能同时启用
 *
 * 日期：2026
 * 版本：2.1.0
 * 
 * 更新说明：
 * - 优化预设切换逻辑，支持直接跳转到指定预设 (1-16)
 * - 修复颜色保存功能，只要光剑点火就能保存
 * - 增加预设注释，与iOS App的16个预设完全对应
 * - 优化命令处理延迟，确保ProffieBoard正确响应
 * - 修复CLR命令问题，不直接发送ccmode，防止自动进入颜色选择模式
 * 
 * 16个预设对应表（与iOS App完全同步，编号1-16）：
 * 1=Shan(萨特尔·珊), 2=Duke(杜库伯爵), 3=VTS(维达), 4=CalJFO(卡尔)
 * 5=Mace(梅斯·温杜), 6=The_Lost_One(欧比旺), 7=Qui_Gon(奎刚), 8=Crimson_Menace(达斯·摩尔)
 * 9=PurgeTrooper(绝地清洗兵), 10=Dolby(杜比), 11=Huyang(胡杨), 12=Loth_Hero(埃兹拉)
 * 13=Son_Of_Corellia(科雷利亚之子), 14=Krossguard_TROS(凯洛·伦), 15=The_ReturnV2(卢克绝地归来), 16=Shock_Baton_Proffie(帝国侦察兵电击棍)
 */

// ==================== 调试配置 ====================
#define ENABLE_DEBUG true         // 启用调试输出
#define DEBUG_BAUD_RATE 115200   // 串口调试波特率

// ==================== 版本信息 ====================
#define FIRMWARE_VERSION "2.5.0"

// ==================== 模式选择 ====================
// 默认使用蓝牙模式，可通过 Web 配置页面修改
#define DEFAULT_MODE_BLE true    // true=蓝牙模式, false=WiFi模式

// 启用 Web 配置功能
#define ENABLE_WEB_CONFIG true

// ==================== 包含头文件 ====================
#include <EEPROM.h>
#include <ArduinoJson.h>
#include <Update.h>
#include <cstring>

#if DEFAULT_MODE_BLE
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#endif

// WiFi 头文件始终包含（AP模式可选）
#include <WiFi.h>
#include <WebServer.h>

// ==================== EEPROM 配置 ====================
#define EEPROM_SIZE 128
#define MODE_OFFSET 0      // 模式设置存储位置
#define WIFI_PASS_OFFSET 16  // WiFi密码存储位置 (最多32字节)
#define WIFI_PASS_MAX_LEN 32  // 最大密码长度
#define DEVICE_ID_OFFSET 48   // 设备ID存储位置 (8字节)
#define DEVICE_ID_MAX_LEN 8  // 设备ID最大长度

// ==================== 配置参数 ====================
#define BLE_SERVICE_UUID "0000FFE0-0000-1000-8000-00805F9B34FB"
#define BLE_CHAR_UUID "0000FFE1-0000-1000-8000-00805F9B34FB"

// BLE OTA Service UUID (乐鑫标准)
#define BLE_OTA_SERVICE_UUID "0000FFF0-0000-1000-8000-00805F9B34FB"
#define BLE_OTA_CHAR_UUID "0000FFF1-0000-1000-8000-00805F9B34FB"

// WiFi 配置 - AP模式热点
char wifiApSsid[20] = "Lightsaber";  // 可修改的SSID (带设备ID后缀)
const char* WIFI_DEFAULT_PASSWORD = "lightsaber";
char WIFI_AP_PASSWORD[33] = "lightsaber";  // 可修改的密码缓冲区
const char* WIFI_STA_SSID = "";      // 填入你的 WiFi SSID
const char* WIFI_STA_PASSWORD = "";  // 填入你的 WiFi 密码

// 引脚定义 (根据实际接线调整)
#define RX_PIN 20   // RX -> Proffie TX (9)
#define TX_PIN 21   // TX -> Proffie RX (8)
#define LED_PIN 8   // 状态指示灯

// ==================== 全局变量 ====================
bool bleConnected = false;
bool wifiConnected = false;
bool useBLE = DEFAULT_MODE_BLE;  // 当前模式
char deviceId[DEVICE_ID_MAX_LEN + 1] = {0};  // 设备唯一ID
char deviceName[16] = {0};  // 设备名称 (LightsaberCtrl-XXXX)

#if DEFAULT_MODE_BLE
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
BLECharacteristic* pOtaCharacteristic = nullptr;
#endif

// OTA 状态变量
bool otaInProgress = false;
String otaStatusMessage = "Ready";
uint32_t otaTotalSize = 0;
uint32_t otaReceivedSize = 0;
uint16_t otaPacketSeq = 0;

// WebServer 始终定义（运行时根据模式决定是否使用）
WebServer server(80);

// 预设颜色映射表 (24个预设，编号1-24) - RGB字节数组格式
// 顺序与Proffieboard V2_2B_config.h完全一致
const uint8_t presetColorsRGB[][3] = {
    {0,0,255},    // 0=Shan - 蓝
    {0,255,0},    // 1=The_ReturnV2 - 绿
    {255,0,0},    // 2=Duke - 红
    {255,255,0},  // 3=VTS - 黄
    {0,102,255},  // 4=CalJFO - 蓝
    {153,0,255},  // 5=Mace - 紫
    {0,204,255},  // 6=The_Lost_One - 浅蓝
    {30,120,200}, // 7=Halflex - 蓝
    {255,0,0},    // 8=Krossguard_TROS - 红
    {255,140,0},  // 9=Final_Steps - 橙
    {0,255,0},    // 10=Qui_Gone - 绿
    {255,0,0},    // 11=Crimson_Menace - 红
    {255,255,255},// 12=SorcererV2 - 白
    {255,165,0},  // 13=Sun_Skoll - 橙
    {255,102,0},  // 14=Huyang - 橙红
    {0,255,0},    // 15=Loth_Hero - 绿
    {136,136,136},// 16=Shock_Baton_Proffie - 灰
    {120,0,255},  // 17=PurgeTrooper - 紫
    {0,102,255},  // 18=Son_Of_Corellia - 蓝
    {0,200,180},  // 19=Proto - 青
    {255,10,80},  // 20=Ascension - 玫红
    {0,168,255},  // 21=CyberBlade - 蓝
    {153,0,255},  // 22=Dolby - 紫
    {255,255,255} // 23=Rainbow - 白
};

// 根据预设编号获取颜色 (编号1-24，转换为数组索引0-23)
String getColorFromPreset(int presetNumber) {
    if (presetNumber >= 1 && presetNumber <= 24) {
        char buf[8];
        const uint8_t* c = presetColorsRGB[presetNumber - 1];  // 数组索引 = 编号 - 1
        snprintf(buf, sizeof(buf), "%02X%02X%02X", c[0], c[1], c[2]);
        return String(buf);
    }
    return "FFFFFF";
}

// 系统状态
struct SystemStatus {
    float batteryVoltage = 0.0;
    float chipTemperature = 0.0;
    int8_t rssi = 0;
    uint8_t brightness = 100;
    uint8_t volume = 75;
    String currentColor = "FFFFFF";
    bool bladeOn = false;
    int currentPresetIndex = 1;  // 当前预设编号 (1-16)
    // 用于状态变化检测
    float lastBatteryVoltage = 0.0;
    uint8_t lastVolume = 75;
    uint8_t lastBrightness = 100;
    bool lastBladeOn = false;
    int lastPresetIndex = 1;
    String lastColor = "FFFFFF";
} status;

// ==================== 函数前向声明 ====================
void processCommand(String command);
void parseSettings(String command);
void sendToProffieBoard(String command);
void sendSystemInfo();
void sendStatus();
void saveModeToEEPROM(bool mode);
bool loadModeFromEEPROM();
void saveWiFiPassword(const char* password);
void loadWiFiPassword();
void loadDeviceId();
void saveDeviceId();
void restartWiFiAP();
void setupWiFi();
bool hasStatusChanged();
void updateLastStatus();

// ==================== 蓝牙 BLE 回调 ====================
#if DEFAULT_MODE_BLE
class MyBLEServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        bleConnected = true;
        Serial.println("BLE 设备已连接");
        
        // 连接后立即推送初始状态（无延迟）
        updateSystemStatus();
        sendSystemInfo();
        updateLastStatus();
    }

    void onDisconnect(BLEServer* pServer) {
        bleConnected = false;
        Serial.println("BLE 设备已断开");
        BLEDevice::startAdvertising();
    }
};

class MyBLECharacteristicCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
        String value = pCharacteristic->getValue();
        if (value.length() > 0) {
            // 移除换行符和回车符
            value.replace("\n", "");
            value.replace("\r", "");
            Serial.print("收到命令：");
            Serial.println(value);
            processCommand(value);
        }
    }
};

// BLE OTA 回调类
class MyBLEOtaCharacteristicCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
        String rxValue = pCharacteristic->getValue();
        if (rxValue.length() > 0) {
            handleOtaData(std::string(rxValue.c_str()));
        }
    }
};
#endif

// ==================== EEPROM 操作 ====================
void saveModeToEEPROM(bool mode) {
    EEPROM.begin(EEPROM_SIZE);
    EEPROM.write(MODE_OFFSET, mode ? 1 : 0);
    EEPROM.commit();
    EEPROM.end();
    Serial.print("模式已保存到 EEPROM: ");
    Serial.println(mode ? "BLE" : "WiFi");
}

bool loadModeFromEEPROM() {
    EEPROM.begin(EEPROM_SIZE);
    byte value = EEPROM.read(MODE_OFFSET);
    EEPROM.end();

    // 检查是否是有效的模式值
    if (value == 0 || value == 1) {
        bool mode = (value == 1);
        Serial.print("从 EEPROM 加载模式: ");
        Serial.println(mode ? "BLE" : "WiFi");
        return mode;
    }

    // 如果没有保存过或者是旧值，初始化并使用默认模式
    if (value != 0 && value != 1) {
        Serial.println("检测到旧EEPROM数据，正在清除...");
        saveModeToEEPROM(DEFAULT_MODE_BLE);
    }

    Serial.println("EEPROM 无配置，使用默认模式");
    return DEFAULT_MODE_BLE;
}

// WiFi密码保存到EEPROM
void saveWiFiPassword(const char* password) {
    if (strlen(password) >= WIFI_PASS_MAX_LEN) return;
    EEPROM.begin(EEPROM_SIZE);
    for (int i = 0; i < WIFI_PASS_MAX_LEN; i++) EEPROM.write(WIFI_PASS_OFFSET + i, 0);
    for (int i = 0; i < strlen(password); i++) EEPROM.write(WIFI_PASS_OFFSET + i, password[i]);
    EEPROM.commit();
    EEPROM.end();
}

// 从EEPROM加载WiFi密码
void loadWiFiPassword() {
    char loadedPassword[WIFI_PASS_MAX_LEN + 1];
    EEPROM.begin(EEPROM_SIZE);
    for (int i = 0; i < WIFI_PASS_MAX_LEN; i++) loadedPassword[i] = EEPROM.read(WIFI_PASS_OFFSET + i);
    loadedPassword[WIFI_PASS_MAX_LEN] = '\0';
    EEPROM.end();
    if (loadedPassword[0] != (char)0xFF && loadedPassword[0] != '\0' && strlen(loadedPassword) > 0) {
        strcpy(WIFI_AP_PASSWORD, loadedPassword);
    } else {
        strcpy(WIFI_AP_PASSWORD, WIFI_DEFAULT_PASSWORD);
    }
}

// 生成设备唯一ID (基于MAC地址后4位)
void generateDeviceId() {
    uint8_t mac[6];
    WiFi.macAddress(mac);
    snprintf(deviceId, DEVICE_ID_MAX_LEN + 1, "%02X%02X", mac[4], mac[5]);
}

// 加载设备ID (从EEPROM或生成新的)
void loadDeviceId() {
    EEPROM.begin(EEPROM_SIZE);
    char storedId[DEVICE_ID_MAX_LEN + 1];
    for (int i = 0; i < DEVICE_ID_MAX_LEN; i++) {
        storedId[i] = EEPROM.read(DEVICE_ID_OFFSET + i);
    }
    storedId[DEVICE_ID_MAX_LEN] = '\0';
    EEPROM.end();

    if (storedId[0] != (char)0xFF && storedId[0] != '\0' && strlen(storedId) > 0) {
        strcpy(deviceId, storedId);
    } else {
        generateDeviceId();
        saveDeviceId();
    }
    snprintf(deviceName, 16, "lightsaber-%s", deviceId);
}

// 保存设备ID到EEPROM
void saveDeviceId() {
    EEPROM.begin(EEPROM_SIZE);
    for (int i = 0; i < DEVICE_ID_MAX_LEN; i++) EEPROM.write(DEVICE_ID_OFFSET + i, 0);
    for (int i = 0; i < strlen(deviceId); i++) EEPROM.write(DEVICE_ID_OFFSET + i, deviceId[i]);
    EEPROM.commit();
    EEPROM.end();
}

// 重启WiFi AP以应用新密码
void restartWiFiAP() {
    WiFi.softAPdisconnect(true);
    delay(100);
    WiFi.softAP(wifiApSsid, WIFI_AP_PASSWORD);
}

// ==================== 命令处理 ====================
void processCommand(String command) {
    command.trim();

    if (command == "ON" || command == "START") {
        status.bladeOn = true;
        sendToProffieBoard("on");
    }
    else if (command == "OFF") {
        status.bladeOn = false;
        sendToProffieBoard("off");
    }
    else if (command == "BLAST") {
        sendToProffieBoard("blast");
    }
    else if (command == "CLASH") {
        sendToProffieBoard("clash");
    }
    else if (command == "LOCKUP") {
        sendToProffieBoard("lockup");
    }
    else if (command == "NEXT") {
        sendToProffieBoard("n");
        delay(50);
        status.currentPresetIndex = (status.currentPresetIndex % 24) + 1;
        status.currentColor = getColorFromPreset(status.currentPresetIndex);
    }
    else if (command == "PREV") {
        sendToProffieBoard("p");
        delay(50);
        status.currentPresetIndex--;
        if (status.currentPresetIndex < 1) status.currentPresetIndex = 24;
        status.currentColor = getColorFromPreset(status.currentPresetIndex);
    }
    else if (command.startsWith("PRESET ")) {
        int targetPreset = command.substring(7).toInt();
        if (targetPreset >= 1 && targetPreset <= 24) {
            int current = status.currentPresetIndex;

            if (current == targetPreset) {
                return;
            }

            int proffiePreset = targetPreset - 1;
            sendToProffieBoard("preset " + String(proffiePreset));

            status.currentPresetIndex = targetPreset;
            status.currentColor = getColorFromPreset(status.currentPresetIndex);
        }
    }
    else if (command == "VOL+") {
        status.volume = min(100, status.volume + 20);
        int proffieVolume = map(status.volume, 0, 100, 0, 2000);
        sendToProffieBoard("set_volume " + String(proffieVolume));
    }
    else if (command == "VOL-") {
        status.volume = max(0, status.volume - 20);
        int proffieVolume = map(status.volume, 0, 100, 0, 2000);
        sendToProffieBoard("set_volume " + String(proffieVolume));
    }
    else if (command.startsWith("VOL ")) {
        int volume = command.substring(4).toInt();
        status.volume = constrain(volume, 0, 100);
        int proffieVolume = map(status.volume, 0, 100, 0, 2000);
        sendToProffieBoard("set_volume " + String(proffieVolume));
    }
    else if (command.startsWith("BRI ")) {
        int brightness = command.substring(4).toInt();
        status.brightness = constrain(brightness, 0, 100);
        int proffieBrightness = map(status.brightness, 0, 100, 0, 32767);
        sendToProffieBoard("set_brightness " + String(proffieBrightness));
        delay(50);
        sendToProffieBoard("effect_dim " + String(100 - status.brightness));
    }
    else if (command.startsWith("CLR ")) {
        String color = command.substring(4);
        color.replace("#", "");
        status.currentColor = color;
        // CLR命令仅保存颜色状态，不直接发送ccmode
    }
    else if (command.startsWith("COLOR:")) {
        String color = command.substring(6);
        status.currentColor = color;
        if (status.bladeOn) {
            sendToProffieBoard("color " + color);
        }
    }
    else if (command == "CCMODE") {
        if (status.bladeOn) {
            sendToProffieBoard("ccmode");
        }
    }
    else if (command == "CCSAVE") {
        if (status.bladeOn) {
            sendToProffieBoard("ccsave");
            delay(100);
        }
    }
    else if (command == "CCEXIT") {
        if (status.bladeOn) {
            // 发送off命令给Proffieboard，会自动保存颜色并熄灭光剑
            sendToProffieBoard("off");
        }
    }
    else if (command == "PLAY") {
        sendToProffieBoard("track_play");
    }
    else if (command == "PAUSE") {
        sendToProffieBoard("track_stop");
    }
    else if (command == "STOP") {
        sendToProffieBoard("track_stop");
    }
    else if (command == "TRACK_NEXT") {
        sendToProffieBoard("track_next");
    }
    else if (command == "TRACK_PREV") {
        sendToProffieBoard("track_prev");
    }
    else if (command == "IGNITION") {
        status.bladeOn = true;
        sendToProffieBoard("on");
    }
    else if (command == "RETRACT") {
        status.bladeOn = false;
        sendToProffieBoard("off");
    }
    else if (command == "VOLUME_UP") {
        status.volume = min(100, status.volume + 5);
        sendToProffieBoard("volume " + String(status.volume));
    }
    else if (command == "VOLUME_DOWN") {
        status.volume = max(0, status.volume - 5);
        sendToProffieBoard("volume " + String(status.volume));
    }
    else if (command == "NEXT_PRESET") {
        sendToProffieBoard("next");
    }
    else if (command == "PREV_PRESET") {
        sendToProffieBoard("prev");
    }
    else if (command.startsWith("SETTINGS:")) {
        parseSettings(command);
    }
    else if (command == "SYSINFO" || command == "GET") {
        sendSystemInfo();
    }
    else if (command == "STATUS") {
        sendStatus();
    }
    else if (command == "REBOOT") {
        ESP.restart();
    }
    else if (command == "SWITCH_WIFI") {
        saveModeToEEPROM(false);
        delay(500);
        ESP.restart();
    }
    else if (command == "SWITCH_BLE") {
        saveModeToEEPROM(true);
        delay(500);
        ESP.restart();
    }
    else if (command == "CLEAR_EEPROM") {
        EEPROM.begin(EEPROM_SIZE);
        for (int i = 0; i < EEPROM_SIZE; i++) {
            EEPROM.write(i, 0xFF);
        }
        EEPROM.commit();
        EEPROM.end();
        delay(500);
        ESP.restart();
    }
    // ========== WiFi密码修改命令 ==========
    else if (command.startsWith("WIFI_PASS ")) {
        String newPassword = command.substring(10);
        newPassword.trim();
        if (newPassword.length() >= 8 && newPassword.length() < WIFI_PASS_MAX_LEN) {
            saveWiFiPassword(newPassword.c_str());
            restartWiFiAP();
        }
    }
    else if (command == "WIFI_RESET") {
        saveWiFiPassword(WIFI_DEFAULT_PASSWORD);
        restartWiFiAP();
    }
    // ========== BLE OTA 固件升级命令 ==========
    else if (command == "OTA_START") {
        Serial.println("[OTA] 收到 OTA_START 命令");
        otaInProgress = true;
        otaReceivedSize = 0;
        otaPacketSeq = 0;
        otaStatusMessage = "Ready";
        
        if (Update.begin()) {
            otaStatusMessage = "Started";
            Serial.println("[OTA] OTA 进程已启动");
        } else {
            otaStatusMessage = "Begin failed";
            Serial.println("[OTA] OTA begin 失败");
        }
    }
    else if (command == "OTA_STATUS") {
        Serial.println("[OTA] Status: " + otaStatusMessage);
        sendBLENotification("OTA_STATUS:" + otaStatusMessage);
    }
    else if (command == "OTA_VERSION") {
        Serial.println("[OTA] Firmware Version: " FIRMWARE_VERSION);
        sendBLENotification("VERSION:" FIRMWARE_VERSION);
    }
    else if (command == "OTA_ABORT") {
        if (otaInProgress) {
            Update.abort();
            otaInProgress = false;
            otaStatusMessage = "Aborted";
            Serial.println("[OTA] 已取消 OTA 进程");
        }
    }
    else if (command.startsWith("OTA_SIZE:")) {
        String sizeStr = command.substring(9);
        otaTotalSize = sizeStr.toInt();
        Serial.printf("[OTA] 固件总大小: %u bytes\n", otaTotalSize);
        if (otaTotalSize > 0) {
            Update.begin(otaTotalSize);
            otaStatusMessage = "Receiving";
        }
    }
    else {
        Serial.print("未知命令：");
        Serial.println(command);
    }
    
    // ==================== 事件驱动：命令执行完后立即推送状态 ====================
    updateSystemStatus();  // 先更新状态
    sendSystemInfo();      // 主动推送给App
    updateLastStatus();    // 更新最后状态记录
}

void parseSettings(String command) {
    int volIndex = command.indexOf("VOL:");
    int brightIndex = command.indexOf("BRIGHT:");

    if (volIndex > 0) {
        int volEnd = command.indexOf(":", volIndex + 4);
        if (volEnd > 0) {
            status.volume = command.substring(volIndex + 4, volEnd).toInt();
        }
    }

    if (brightIndex > 0) {
        int brightEnd = command.indexOf(":", brightIndex + 7);
        if (brightEnd > 0) {
            status.brightness = command.substring(brightIndex + 7, brightEnd).toInt();
        } else {
            status.brightness = command.substring(brightIndex + 7).toInt();
        }
    }

    Serial.print("设置 - 音量：");
    Serial.print(status.volume);
    Serial.print(", 亮度：");
    Serial.println(status.brightness);

    sendToProffieBoard("BRIGHTNESS " + String(status.brightness));
}

// ==================== 与 ProffieBoard 通信 ====================
// 使用 UART1 避免与 USB CDC (UART0) 冲突
// 通过 GPIO Matrix 支持将 UART1 映射到任意 GPIO 引脚
// 使用 ESP-IDF 底层 API 确保正确配置

// ESP-IDF UART 驱动头文件
#include "driver/uart.h"

void sendToProffieBoard(String command) {
    // ProffieOS 标准串口命令格式：命令 + 换行符
    // 尝试添加换行符和回车符确保正确解析
    String data = command + "\r\n";
    uart_write_bytes(UART_NUM_1, data.c_str(), data.length());
    Serial.print("发送到 ProffieBoard: ");
    Serial.println(command);
}

void readFromProffieBoard() {
    const int BUFFER_SIZE = 256;
    uint8_t buffer[BUFFER_SIZE];
    
    // 使用 ESP-IDF API 读取串口数据
    int len = uart_read_bytes(UART_NUM_1, buffer, BUFFER_SIZE - 1, 10 / portTICK_PERIOD_MS);
    
    if (len > 0) {
        buffer[len] = '\0';  // 添加字符串结束符
        String data = String((char*)buffer);
        data.trim();
        
        Serial.print("来自 ProffieBoard: ");
        Serial.println(data);

        if (data.startsWith("VOLTAGE:")) {
            status.batteryVoltage = data.substring(8).toFloat();
        }
        else if (data.startsWith("TEMP:")) {
            status.chipTemperature = data.substring(5).toFloat();
        }
    }
}

// ==================== 系统信息发送 ====================
void sendSystemInfo() {
    StaticJsonDocument<300> doc;
    doc["battery"] = status.batteryVoltage;
    doc["temperature"] = status.chipTemperature;
    doc["rssi"] = status.rssi;
    doc["brightness"] = status.brightness;
    doc["volume"] = status.volume;
    doc["color"] = status.currentColor;
    doc["bladeOn"] = status.bladeOn;
    doc["mode"] = useBLE ? "蓝牙" : "WiFi";
    doc["firmwareVersion"] = FIRMWARE_VERSION;
    doc["currentPreset"] = status.currentPresetIndex;

    String json;
    serializeJson(doc, json);

    #if DEFAULT_MODE_BLE
    if (bleConnected && pCharacteristic) {
        pCharacteristic->setValue(json.c_str());
        pCharacteristic->notify();
    }
    #endif

    Serial.print("发送系统信息：");
    Serial.println(json);
}

void sendStatus() {
    StaticJsonDocument<128> doc;
    doc["connected"] = bleConnected || wifiConnected;
    doc["mode"] = useBLE ? "BLE" : "WiFi";
    doc["battery"] = status.batteryVoltage;

    String json;
    serializeJson(doc, json);

    #if DEFAULT_MODE_BLE
    if (bleConnected && pCharacteristic) {
        pCharacteristic->setValue(json.c_str());
        pCharacteristic->notify();
    }
    #endif
}

// ==================== 状态变化检测 ====================
bool hasStatusChanged() {
    bool changed = false;
    
    // 电池变化 > 0.05V
    if (abs(status.batteryVoltage - status.lastBatteryVoltage) > 0.05) {
        changed = true;
    }
    
    // 音量变化 > 5
    if (abs(status.volume - status.lastVolume) > 5) {
        changed = true;
    }
    
    // 亮度变化 > 10
    if (abs(status.brightness - status.lastBrightness) > 10) {
        changed = true;
    }
    
    // 开关状态变化
    if (status.bladeOn != status.lastBladeOn) {
        changed = true;
    }
    
    // 预设变化
    if (status.currentPresetIndex != status.lastPresetIndex) {
        changed = true;
    }
    
    // 颜色变化
    if (status.currentColor != status.lastColor) {
        changed = true;
    }
    
    return changed;
}

void updateLastStatus() {
    status.lastBatteryVoltage = status.batteryVoltage;
    status.lastVolume = status.volume;
    status.lastBrightness = status.brightness;
    status.lastBladeOn = status.bladeOn;
    status.lastPresetIndex = status.currentPresetIndex;
    status.lastColor = status.currentColor;
}

// 发送自定义状态消息（如电池警告）到App
void sendStatusCommand(String message) {
    StaticJsonDocument<96> doc;
    doc["msg"] = message;
    doc["bat"] = status.batteryVoltage;
    String json;
    serializeJson(doc, json);
    #if DEFAULT_MODE_BLE
    if (bleConnected && pCharacteristic) {
        pCharacteristic->setValue(json.c_str());
        pCharacteristic->notify();
    }
    #endif
}

// ==================== 功率设置查询 ====================
void displayCurrentPowerSettings() {
    Serial.println("\n========== 当前功率设置 ==========");
    
    // 读取Wi-Fi功率
    int8_t wifiPower = 0;
    #if CONFIG_IDF_TARGET_ESP32C3
    wifiPower = 78;  // 默认最高功率值
    Serial.printf("Wi-Fi 功率: %d (默认最大值)\n", wifiPower);
    Serial.printf("Wi-Fi 功率: %.1f dBm (最高功率)\n", wifiPower * 0.25);
    Serial.printf("Wi-Fi 功率等级: 高功率 ✓ (已是最优)\n");
    #else
    esp_wifi_get_max_tx_power(&wifiPower);
    float wifiPowerDbm = wifiPower * 0.25;  // 转换为dBm
    Serial.printf("Wi-Fi 功率: %d (值) = %.1f dBm\n", wifiPower, wifiPowerDbm);
    // 根据功率值判断等级
    String wifiLevel;
    if (wifiPowerDbm >= 18) wifiLevel = "高功率 ✓";
    else if (wifiPowerDbm >= 12) wifiLevel = "中等功率";
    else if (wifiPowerDbm >= 6) wifiLevel = "低功率";
    else wifiLevel = "最低功率";
    Serial.printf("Wi-Fi 功率等级: %s\n", wifiLevel.c_str());
    #endif
    
    #if DEFAULT_MODE_BLE
    // 读取蓝牙功率
    esp_power_level_t bleAdvPower = esp_ble_tx_power_get(ESP_BLE_PWR_TYPE_ADV);
    Serial.printf("蓝牙广播功率: %d dBm\n", (int)bleAdvPower);
    
    esp_power_level_t bleScanPower = esp_ble_tx_power_get(ESP_BLE_PWR_TYPE_SCAN);
    Serial.printf("蓝牙扫描功率: %d dBm\n", (int)bleScanPower);
    
    // 根据功率值判断等级
    String bleLevel;
    if ((int)bleAdvPower >= 6) bleLevel = "高功率 ✓";
    else if ((int)bleAdvPower >= 0) bleLevel = "中等功率";
    else if ((int)bleAdvPower >= -6) bleLevel = "低功率";
    else bleLevel = "最低功率";
    Serial.printf("蓝牙功率等级: %s\n", bleLevel.c_str());
    #endif
    
    Serial.println("====================================\n");
}

// ==================== WiFi 和 Web 服务器 ====================
void setupWiFi() {
    Serial.println("启动 WiFi AP 模式...");
    WiFi.mode(WIFI_AP);
    WiFi.softAPConfig(IPAddress(192, 168, 4, 1), IPAddress(192, 168, 4, 1), IPAddress(255, 255, 255, 0));

    // 更新WiFi SSID为带设备ID的格式
    snprintf(wifiApSsid, 20, "lightsaber-%s", deviceId);

    bool apStarted = WiFi.softAP(wifiApSsid, WIFI_AP_PASSWORD);
    Serial.printf("AP 启动结果: %s\n", apStarted ? "成功" : "失败");
    if (apStarted) {
        wifiConnected = true;
    }
    Serial.print("AP 模式 IP 地址：");
    Serial.println(WiFi.softAPIP());

    if (String(WIFI_STA_SSID).length() > 0) {
        Serial.printf("尝试连接 STA WiFi: %s\n", WIFI_STA_SSID);
        WiFi.begin(WIFI_STA_SSID, WIFI_STA_PASSWORD);
        Serial.print("正在连接 WiFi");

        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 30) {
            delay(500);
            Serial.print(".");
            attempts++;
        }

        if (WiFi.status() == WL_CONNECTED) {
            wifiConnected = true;
            Serial.print("\nWiFi 已连接！IP 地址：");
            Serial.println(WiFi.localIP());
        } else {
            Serial.println("\nWiFi STA 模式连接失败，保持 AP 模式");
        }
    }

    // 注册路由
    server.on("/", handleRoot);
    server.on("/api/status", handleStatus);
    server.on("/api/command", handleCommand);
    server.on("/config", handleConfig);
    server.on("/api/saveMode", handleSaveMode);
    server.begin();
    Serial.println("HTTP 服务器已启动");
}

void handleRoot() {
    String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lightsaber Controller</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
            padding: 20px;
        }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #e94560; text-align: center; }
        .btn {
            display: inline-block;
            padding: 15px 30px;
            margin: 10px;
            background: #e94560;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
        }
        .btn:hover { background: #0f3460; }
        .btn-secondary { background: #0f3460; }
        .btn-secondary:hover { background: #1a1a2e; }
        .status {
            background: rgba(15, 52, 96, 0.5);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .nav { text-align: center; margin-bottom: 20px; }
        .nav a { color: #4facfe; margin: 0 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚔️ Lightsaber Web Controller</h1>
        <div class="nav">
            <a href="/">控制</a> | <a href="/config">配置</a>
        </div>
        <div class="status">
            <p>状态：<span id="status">加载中...</span></p>
            <p>当前模式：WiFi</p>
        </div>
        <div style="text-align: center;">
            <button class="btn" onclick="sendCommand('ON')">🔥 点火</button>
            <button class="btn" onclick="sendCommand('OFF')">💨 收剑</button>
            <button class="btn" onclick="sendCommand('BLAST')">💥 爆能</button>
            <button class="btn" onclick="sendCommand('CLASH')">⚔️ 碰撞</button>
            <button class="btn" onclick="sendCommand('LOCKUP')">🔒 锁定</button>
        </div>
    </div>
    <script>
        async function sendCommand(cmd) {
            const response = await fetch('/api/command?cmd=' + cmd);
            const data = await response.json();
            document.getElementById('status').innerText = data.message;
        }
        async function updateStatus() {
            const response = await fetch('/api/status');
            const data = await response.json();
            document.getElementById('status').innerText = 'WiFi: ' + (data.wifi ? '已连接' : '未连接');
        }
        updateStatus();
        setInterval(updateStatus, 5000);
    </script>
</body>
</html>
)rawliteral";

    server.send(200, "text/html; charset=utf-8", html);
}

void handleStatus() {
    StaticJsonDocument<256> doc;
    doc["battery"] = status.batteryVoltage;
    doc["temperature"] = status.chipTemperature;
    doc["rssi"] = status.rssi;
    doc["brightness"] = status.brightness;
    doc["volume"] = status.volume;
    doc["color"] = status.currentColor;
    doc["bladeOn"] = status.bladeOn;
    doc["mode"] = useBLE ? "蓝牙" : "WiFi";
    doc["firmwareVersion"] = FIRMWARE_VERSION;
    doc["currentPreset"] = status.currentPresetIndex;  // 添加当前预设索引

    String json;
    serializeJson(doc, json);
    server.send(200, "application/json", json);
}

void handleCommand() {
    if (server.hasArg("cmd")) {
        String cmd = server.arg("cmd");
        processCommand(cmd);

        StaticJsonDocument<128> doc;
        doc["success"] = true;
        doc["message"] = "命令已执行：" + cmd;

        String json;
        serializeJson(doc, json);
        server.send(200, "application/json", json);
    } else {
        server.send(400, "application/json", "{\"success\": false, \"message\": \"缺少命令参数\"}");
    }
}

// 配置页面
void handleConfig() {
    String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <title>Lightsaber Controller - Config</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e, #16213e);
            color: white;
            padding: 20px;
        }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #e94560; text-align: center; }
        .card {
            background: rgba(15, 52, 96, 0.5);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .radio-group { margin: 15px 0; }
        .radio-group label {
            display: block;
            padding: 10px;
            border-radius: 8px;
            margin: 5px 0;
            cursor: pointer;
            border: 2px solid transparent;
        }
        .radio-group label:hover { background: rgba(233, 69, 96, 0.2); }
        .radio-group input[type="radio"]:checked + label {
            background: rgba(233, 69, 96, 0.3);
            border-color: #e94560;
        }
        .btn {
            width: 100%;
            padding: 15px;
            background: #e94560;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
        }
        .btn:hover { background: #0f3460; }
        .nav { text-align: center; margin-bottom: 20px; }
        .nav a { color: #4facfe; margin: 0 10px; }
        .info {
            background: rgba(79, 172, 254, 0.2);
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #4facfe;
        }
        .warning {
            background: rgba(255, 165, 2, 0.2);
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #ffa502;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚔️ Lightsaber Configuration</h1>
        <div class="nav">
            <a href="/">控制</a> | <a href="/config">配置</a>
        </div>
        
        <div class="card">
            <h2>连接模式设置</h2>
            <div class="info">
                <p>蓝牙和 WiFi 不能同时启用</p>
            </div>
            <div class="radio-group">
                <input type="radio" id="mode-ble" name="mode" value="ble">
                <label for="mode-ble">
                    <strong>🔵 蓝牙模式</strong>
                    <p>适合 Android 手机或支持 Web Bluetooth 的浏览器</p>
                </label>
                <input type="radio" id="mode-wifi" name="mode" value="wifi" checked>
                <label for="mode-wifi">
                    <strong>📶 WiFi 模式</strong>
                    <p>适合 iPhone Safari 或所有支持 WiFi 的设备</p>
                </label>
            </div>
            <button class="btn" onclick="saveMode()">💾 保存并重启</button>
        </div>
        
        <div class="warning">
            <p><strong>⚠️ 注意：</strong>切换模式后设备将自动重启，需要重新连接</p>
        </div>
    </div>
    <script>
        async function saveMode() {
            const mode = document.querySelector('input[name="mode"]:checked').value;
            const response = await fetch('/api/saveMode?mode=' + mode);
            const data = await response.json();
            if (data.success) {
                alert('设置已保存！设备将在 3 秒后重启...');
                setTimeout(() => {
                    window.location.reload();
                }, 3000);
            }
        }
    </script>
</body>
</html>
)rawliteral";

    server.send(200, "text/html; charset=utf-8", html);
}

void handleSaveMode() {
    if (server.hasArg("mode")) {
        String mode = server.arg("mode");
        bool newMode = (mode == "ble");
        
        saveModeToEEPROM(newMode);
        
        StaticJsonDocument<128> doc;
        doc["success"] = true;
        doc["message"] = "模式已保存：" + String(newMode ? "BLE" : "WiFi");
        
        String json;
        serializeJson(doc, json);
        server.send(200, "application/json", json);
        
        // 延迟重启
        delay(2000);
        ESP.restart();
    } else {
        server.send(400, "application/json", "{\"success\": false, \"message\": \"缺少模式参数\"}");
    }
}

// ==================== BLE OTA 固件升级 ====================
void sendBLENotification(String message) {
    #if DEFAULT_MODE_BLE
    if (pCharacteristic != nullptr && bleConnected) {
        pCharacteristic->setValue(message.c_str());
        pCharacteristic->notify();
    }
    #endif
}

void handleOtaData(std::string rxValue) {
    if (!otaInProgress) {
        Serial.println("[OTA] 收到数据但 OTA 未启动");
        return;
    }
    
    size_t len = rxValue.length();
    if (len < 4) {
        Serial.printf("[OTA] 数据长度太短: %d\n", len);
        return;
    }
    
    // BLE OTA 数据包格式:
    // | 序列号(2 bytes) | 数据长度(2 bytes) | 数据(n bytes) | CRC16(2 bytes) |
    uint16_t seq = (rxValue[0] << 8) | rxValue[1];
    uint16_t dataLen = (rxValue[2] << 8) | rxValue[3];
    
    // 验证序列号
    if (seq != otaPacketSeq) {
        Serial.printf("[OTA] 序列号错误: 期望 %u, 收到 %u\n", otaPacketSeq, seq);
        // 可以选择重新同步或忽略
    }
    
    // 验证数据长度
    if (dataLen > len - 4) {
        Serial.printf("[OTA] 数据长度不匹配: 头=%u, 实际=%u\n", dataLen, len - 4);
        return;
    }
    
    // 提取数据
    std::string otaData = rxValue.substr(4, dataLen);
    
    // 写入 OTA 分区
    size_t written = Update.write((uint8_t*)otaData.c_str(), dataLen);
    if (written != dataLen) {
        Serial.printf("[OTA] 写入失败: 期望 %u, 写入 %u\n", dataLen, written);
        otaStatusMessage = "Write error";
        return;
    }
    
    otaReceivedSize += dataLen;
    otaPacketSeq++;
    
    // 计算进度
    uint8_t progress = 0;
    if (otaTotalSize > 0) {
        progress = (otaReceivedSize * 100) / otaTotalSize;
    }
    
    // 每10%打印一次进度
    static uint8_t lastProgress = 0;
    if (progress / 10 > lastProgress / 10) {
        Serial.printf("[OTA] 进度: %u%% (%u / %u bytes)\n", progress, otaReceivedSize, otaTotalSize);
        lastProgress = progress;
    }
    
    // 发送 ACK
    if (pOtaCharacteristic != nullptr) {
        uint8_t ack[4];
        ack[0] = (otaPacketSeq >> 8) & 0xFF;
        ack[1] = otaPacketSeq & 0xFF;
        ack[2] = 0;  // ACK OK
        ack[3] = 0;
        pOtaCharacteristic->setValue(ack, 4);
        pOtaCharacteristic->notify();
    }
    
    // 检查传输完成
    if (otaReceivedSize >= otaTotalSize) {
        Serial.println("[OTA] 固件接收完成，开始验证...");
        otaStatusMessage = "Verifying";
        
        if (Update.end(true)) {
            Serial.println("[OTA] OTA 验证成功！重启中...");
            otaStatusMessage = "Success! Rebooting...";
            delay(500);
            ESP.restart();
        } else {
            Serial.printf("[OTA] OTA 验证失败: %s\n", Update.errorString());
            otaStatusMessage = "Verify failed";
            otaInProgress = false;
        }
    }
}

// ==================== 系统初始化 ====================
// GPIO0 电池电压检测
#define BATTERY_ADC_PIN 0
#define BATTERY_VOLTAGE_DIVIDER 2.0
#define LOW_VOLTAGE_THRESHOLD 3.0
#define CRITICAL_VOLTAGE_THRESHOLD 2.8

bool lowBatteryWarned = false;
unsigned long lastBatteryWarningTime = 0;
const unsigned long BATTERY_WARNING_INTERVAL = 60000;

void initBatteryADC() {
    analogReadResolution(12);
    analogSetPinAttenuation(BATTERY_ADC_PIN, ADC_11db);
}

void readBatteryVoltage() {
    int total = 0;
    const int samples = 8;
    for (int i = 0; i < samples; i++) {
        total += analogReadMilliVolts(BATTERY_ADC_PIN);
        delayMicroseconds(100);
    }
    int avgAdcValue = total / samples;
    float adcVoltage = avgAdcValue / 1000.0;
    status.batteryVoltage = adcVoltage * BATTERY_VOLTAGE_DIVIDER;
    if (status.batteryVoltage < 0.0) status.batteryVoltage = 0.0;
    if (status.batteryVoltage > 5.0) status.batteryVoltage = 5.0;
}

void checkLowBatteryWarning() {
    unsigned long now = millis();
    if (now - lastBatteryWarningTime < BATTERY_WARNING_INTERVAL) return;

    if (status.batteryVoltage > 0 && status.batteryVoltage < CRITICAL_VOLTAGE_THRESHOLD) {
        sendStatusCommand("BATTERY_LOW:" + String(status.batteryVoltage, 2) + ":CRITICAL");
        lastBatteryWarningTime = now;
        lowBatteryWarned = true;
    } else if (status.batteryVoltage < LOW_VOLTAGE_THRESHOLD) {
        sendStatusCommand("BATTERY_LOW:" + String(status.batteryVoltage, 2) + ":WARNING");
        lastBatteryWarningTime = now;
        lowBatteryWarned = true;
    } else if (status.batteryVoltage > LOW_VOLTAGE_THRESHOLD + 0.3 && lowBatteryWarned) {
        lowBatteryWarned = false;
    }
}

void readChipTemperature() {
    status.chipTemperature = temperatureRead();
}

void updateSystemStatus() {
    readBatteryVoltage();
    readChipTemperature();
    #if !DEFAULT_MODE_BLE
    status.rssi = WiFi.RSSI();
    #else
    status.rssi = -50;
    #endif
}

void setup() {
    Serial.begin(115200);
    delay(100);
    Serial.println("\n\n========== Lightsaber Controller 启动中 ==========");
    Serial.printf("固件版本: %s\n", FIRMWARE_VERSION);
    Serial.printf("编译时间: %s %s\n\n", __DATE__, __TIME__);
    
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);
    initBatteryADC();

    // 初始化 ProffieBoard 串口
    // 使用 ESP-IDF 底层 API 确保 GPIO Matrix 正确映射
    uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    
    // 配置 UART 参数
    uart_param_config(UART_NUM_1, &uart_config);
    
    // 配置引脚映射 - 使用 GPIO27 作为 RX, GPIO28 作为 TX
    uart_set_pin(UART_NUM_1, TX_PIN, RX_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    
    // 安装 UART 驱动
    uart_driver_install(UART_NUM_1, 1024 * 2, 0, 0, NULL, 0);
    
    // 等待串口稳定
    delay(200);
    
    Serial.println("ProffieBoard 串口已初始化");
    Serial.printf("UART1 - TX_PIN: %d, RX_PIN: %d, Baud: 115200\n", TX_PIN, RX_PIN);
    
    // 发送测试命令验证通信
    sendToProffieBoard("echo Hello from Controller");
    Serial.println("已发送测试命令到 ProffieBoard");

    // 从 EEPROM 加载保存的模式
    useBLE = loadModeFromEEPROM();
    Serial.printf("启动模式: %s\n", useBLE ? "BLE" : "WiFi");

    // 从 EEPROM 加载保存的WiFi密码
    loadWiFiPassword();

    // 加载设备唯一ID
    loadDeviceId();
    Serial.printf("设备ID: %s\n", deviceId);
    
    // 读取并显示当前功率设置
    displayCurrentPowerSettings();

    #if DEFAULT_MODE_BLE
    if (useBLE) {
        Serial.println("模式：蓝牙 BLE");

        // 蓝牙初始化
        BLEDevice::init(deviceName);
        pServer = BLEDevice::createServer();
        pServer->setCallbacks(new MyBLEServerCallbacks());

        BLEService* pService = pServer->createService(BLE_SERVICE_UUID);

        pCharacteristic = pService->createCharacteristic(
            BLE_CHAR_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_WRITE |
            BLECharacteristic::PROPERTY_WRITE_NR |
            BLECharacteristic::PROPERTY_NOTIFY
        );

        pCharacteristic->setCallbacks(new MyBLECharacteristicCallbacks());
        pCharacteristic->addDescriptor(new BLE2902());

        pService->start();

        // 创建 BLE OTA 服务
        BLEService* pOtaService = pServer->createService(BLE_OTA_SERVICE_UUID);
        pOtaCharacteristic = pOtaService->createCharacteristic(
            BLE_OTA_CHAR_UUID,
            BLECharacteristic::PROPERTY_WRITE |
            BLECharacteristic::PROPERTY_NOTIFY
        );
        pOtaCharacteristic->setCallbacks(new MyBLEOtaCharacteristicCallbacks());
        pOtaCharacteristic->addDescriptor(new BLE2902());
        pOtaService->start();
        Serial.println("BLE OTA Service 已启动");

        BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
        pAdvertising->addServiceUUID(BLE_SERVICE_UUID);
        pAdvertising->setScanResponse(true);
        pAdvertising->setMinPreferred(0x06);
        pAdvertising->setMaxPreferred(0x12);
        
        // 设置广播名称
        BLEAdvertisementData advertisementData;
        advertisementData.setName(deviceName);
        pAdvertising->setAdvertisementData(advertisementData);
        
        BLEDevice::startAdvertising();

        Serial.println("蓝牙 BLE 已启动，等待连接...");
        Serial.println("如需切换到 WiFi 模式，请发送命令: SWITCH_WIFI");
    } else
    #endif
    {
        Serial.println("模式：WiFi");
        delay(1000);
        setupWiFi();
    }

    // 初始化颜色为预设1的颜色
    status.currentColor = getColorFromPreset(status.currentPresetIndex);
    Serial.print("初始化颜色: #");
    Serial.println(status.currentColor);

    // 闪烁 LED 表示启动完成
    digitalWrite(LED_PIN, HIGH);
    delay(500);
    digitalWrite(LED_PIN, LOW);

    Serial.println("系统初始化完成！");
}

void loop() {
    // LED 状态指示
    if (bleConnected || wifiConnected) {
        digitalWrite(LED_PIN, HIGH);
    } else {
        digitalWrite(LED_PIN, LOW);
    }

    // 读取 ProffieBoard 数据
    readFromProffieBoard();

    // 处理 Web 请求
    if (!useBLE) {
        server.handleClient();
    }

    // 定期更新系统状态
    static unsigned long lastUpdate = 0;
    if (millis() - lastUpdate > 5000) {
        updateSystemStatus();
        lastUpdate = millis();
    }

    // 检查低电压警告
    static unsigned long lastBatteryCheck = 0;
    if (millis() - lastBatteryCheck > 5000) {
        checkLowBatteryWarning();
        lastBatteryCheck = millis();
    }

    // ==================== 事件驱动：定期检查状态变化并推送 ====================
    static unsigned long lastStatusCheck = 0;
    if (millis() - lastStatusCheck > 2000) {  // 每2秒检查一次
        updateSystemStatus();
        if (hasStatusChanged()) {
            sendSystemInfo();
            updateLastStatus();
        }
        lastStatusCheck = millis();
    }

    // 延迟
    delay(10);
}
