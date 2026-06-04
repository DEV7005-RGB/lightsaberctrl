import Foundation
import Combine
import CoreBluetooth

// MARK: - OTA 管理器
class OtaManager: NSObject, ObservableObject {

    // MARK: - 单例
    static let shared = OtaManager()

    // MARK: - 发布属性
    @Published var otaState: OtaState = .idle
    @Published var otaProgress: Double = 0.0
    @Published var currentFirmwareVersion: String = "Unknown"

    // MARK: - BLE 属性
    private var centralManager: CBCentralManager?
    private var blePeripheral: CBPeripheral?
    private var otaCharacteristic: CBCharacteristic?
    private var commandCharacteristic: CBCharacteristic?

    // MARK: - OTA 数据
    private var firmwareData: Data?
    private var bytesSent: Int = 0
    private var totalBytes: Int = 0
    private var currentPacketSeq: UInt16 = 0
    private let chunkSize = 512

    // MARK: - BLE UUID
    let bleOtaServiceUUID = CBUUID(string: "0000FFF0-0000-1000-8000-00805F9B34FB")
    let bleOtaCharUUID = CBUUID(string: "0000FFF1-0000-1000-8000-00805F9B34FB")
    let bleCommandServiceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    let bleCommandCharUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")

    // MARK: - 回调
    private var progressCallback: ((Double) -> Void)?

    // MARK: - OTA 状态
    enum OtaState: Equatable {
        case idle
        case scanning
        case connecting
        case discovering
        case preparing
        case transferring
        case verifying
        case success
        case failed(String)

        static func == (lhs: OtaState, rhs: OtaState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.scanning, .scanning), (.connecting, .connecting),
                 (.discovering, .discovering), (.preparing, .preparing),
                 (.transferring, .transferring), (.verifying, .verifying), (.success, .success):
                return true
            case (.failed(let a), .failed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    // MARK: - 生命周期
    private override init() {
        super.init()
    }

    // MARK: - 初始化 BLE
    func initializeBle() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    // MARK: - BLE OTA 传输
    func startBleOta(firmwareData: Data, peripheral: CBPeripheral, onProgress: @escaping (Double) -> Void) {
        self.firmwareData = firmwareData
        self.blePeripheral = peripheral
        self.totalBytes = firmwareData.count
        self.bytesSent = 0
        self.currentPacketSeq = 0
        self.progressCallback = onProgress

        otaState = .connecting
        otaProgress = 0.0

        peripheral.delegate = self
        peripheral.discoverServices([bleOtaServiceUUID, bleCommandServiceUUID])
    }

    // MARK: - 发送 OTA 命令
    private func sendOtaCommand(_ command: String) {
        guard let peripheral = blePeripheral,
              let characteristic = commandCharacteristic else {
            return
        }

        if let data = command.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    // MARK: - 开始 OTA 进程
    private func beginOtaProcess() {
        guard let data = firmwareData else {
            otaState = .failed("Firmware data is empty")
            return
        }

        otaState = .preparing

        sendOtaCommand("OTA_SIZE:\(data.count)")
        sendOtaCommand("OTA_START")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.transferNextChunk()
        }
    }

    // MARK: - 分包传输固件
    private func transferNextChunk() {
        guard let peripheral = blePeripheral,
              let characteristic = otaCharacteristic,
              let data = firmwareData,
              bytesSent < totalBytes else {
            transferComplete()
            return
        }

        otaState = .transferring

        let remainingBytes = totalBytes - bytesSent
        let bytesToSend = min(chunkSize, remainingBytes)
        let chunk = data.subdata(in: bytesSent..<(bytesSent + bytesToSend))

        let packet = createOtaDataPacket(sequence: currentPacketSeq, data: chunk)
        peripheral.writeValue(packet, for: characteristic, type: .withResponse)

        bytesSent += bytesToSend
        currentPacketSeq += 1
        otaProgress = Double(bytesSent) / Double(totalBytes)
        progressCallback?(otaProgress)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.transferNextChunk()
        }
    }

    // MARK: - 创建 OTA 数据包
    private func createOtaDataPacket(sequence: UInt16, data: Data) -> Data {
        var packet = Data()

        packet.append(contentsOf: withUnsafeBytes(of: sequence.bigEndian) { Array($0) })

        let dataLen = UInt16(data.count)
        packet.append(contentsOf: withUnsafeBytes(of: dataLen.bigEndian) { Array($0) })

        packet.append(data)

        let crc = calculateCRC16(data)
        packet.append(contentsOf: withUnsafeBytes(of: crc.bigEndian) { Array($0) })

        return packet
    }

    // MARK: - CRC16 计算
    private func calculateCRC16(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in data {
            crc ^= UInt16(byte)
            for _ in 0..<8 {
                if (crc & 1) != 0 {
                    crc = (crc >> 1) ^ 0xA001
                } else {
                    crc >>= 1
                }
            }
        }
        return crc
    }

    // MARK: - 传输完成
    private func transferComplete() {
        otaState = .verifying

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.otaState = .success
            self?.progressCallback?(1.0)
        }
    }

    // MARK: - WiFi OTA（通过命令发送固件 URL）
    func startWifiOta(firmwareUrl: String, onProgress: @escaping (Double) -> Void) {
        otaState = .preparing
        otaProgress = 0.0
        progressCallback = onProgress

        sendOtaCommand("OTA_START:\(firmwareUrl)")

        simulateProgress(onProgress: onProgress)
    }

    // MARK: - 模拟进度
    private func simulateProgress(onProgress: @escaping (Double) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.otaProgress < 1.0 {
                self.otaProgress += 0.02
                self.otaState = .transferring
                onProgress(self.otaProgress)
            } else {
                timer.invalidate()
                self.otaState = .verifying
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.otaState = .success
                }
            }
        }
    }

    // MARK: - 获取固件版本
    func getFirmwareVersion() {
        sendOtaCommand("OTA_VERSION")
    }

    // MARK: - 取消 OTA
    func cancelOta() {
        sendOtaCommand("OTA_ABORT")
        resetState()
    }

    // MARK: - 重置状态
    func resetState() {
        firmwareData = nil
        bytesSent = 0
        totalBytes = 0
        currentPacketSeq = 0
        otaProgress = 0.0
        otaState = .idle
        progressCallback = nil
    }
}

// MARK: - CBCentralManagerDelegate
extension OtaManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("[OTA] BLE powered on")
        case .poweredOff:
            otaState = .failed("BLE is powered off")
        case .unsupported:
            otaState = .failed("BLE is not supported")
        default:
            break
        }
    }
}

// MARK: - CBPeripheralDelegate
extension OtaManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            otaState = .failed("Service discovery failed: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            otaState = .failed("No services found")
            return
        }

        for service in services {
            if service.uuid == bleOtaServiceUUID {
                peripheral.discoverCharacteristics([bleOtaCharUUID], for: service)
            } else if service.uuid == bleCommandServiceUUID {
                peripheral.discoverCharacteristics([bleCommandCharUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            otaState = .failed("Characteristic discovery failed: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == bleOtaCharUUID {
                otaCharacteristic = characteristic
                print("[OTA] Found OTA characteristic")
            } else if characteristic.uuid == bleCommandCharUUID {
                commandCharacteristic = characteristic
                print("[OTA] Found command characteristic")
            }
        }

        if otaCharacteristic != nil && commandCharacteristic != nil {
            otaState = .discovering
            beginOtaProcess()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[OTA] Write error: \(error.localizedDescription)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("[OTA] Notification state error: \(error.localizedDescription)")
        }
    }
}
