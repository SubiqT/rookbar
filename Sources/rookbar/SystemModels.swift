import AudioToolbox
import CoreAudio
import CoreWLAN
import Foundation
import IOKit.ps
import Network
import Observation
import RookbarCore

/// Battery level and power source, updated by IOKit power-source notifications.
@MainActor
@Observable
final class BatteryModel {
    private(set) var level: Int?
    private(set) var isOnAC = false

    @ObservationIgnored private var runLoopSource: CFRunLoopSource?

    func start() {
        update()
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let model = Unmanaged<BatteryModel>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { model.update() }
        }, context)?.takeRetainedValue() else { return }
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = source
    }

    private func update() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue()
                    as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = description[kIOPSCurrentCapacityKey] as? Int,
                  let maximum = description[kIOPSMaxCapacityKey] as? Int, maximum > 0
            else { continue }
            let newLevel = Int((Double(current) / Double(maximum) * 100).rounded())
            let newIsOnAC = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            if level != newLevel { level = newLevel }
            if isOnAC != newIsOnAC { isOnAC = newIsOnAC }
            return
        }
        level = nil
    }
}

/// Output volume and mute of the default output device, updated by CoreAudio property listeners.
@MainActor
@Observable
final class VolumeModel {
    private(set) var level: Int?
    private(set) var isMuted = false

    @ObservationIgnored private var device = AudioObjectID(kAudioObjectUnknown)
    @ObservationIgnored private var deviceListener: AudioObjectPropertyListenerBlock?

    private static var defaultOutputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    private static let deviceAddresses = [
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        ),
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        ),
    ]

    func start() {
        var address = Self.defaultOutputAddress
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.attachToDefaultDevice() }
        }
        attachToDefaultDevice()
    }

    private func attachToDefaultDevice() {
        if device != kAudioObjectUnknown, let deviceListener {
            for var address in Self.deviceAddresses {
                AudioObjectRemovePropertyListenerBlock(device, &address, .main, deviceListener)
            }
        }

        var newDevice = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = Self.defaultOutputAddress
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &newDevice)
        device = newDevice

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated { self?.update() }
        }
        deviceListener = listener
        for var address in Self.deviceAddresses {
            AudioObjectAddPropertyListenerBlock(device, &address, .main, listener)
        }
        update()
    }

    private func update() {
        var volume = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        var volumeAddress = Self.deviceAddresses[0]
        let volumeStatus = AudioObjectGetPropertyData(device, &volumeAddress, 0, nil, &size, &volume)

        var muted = UInt32(0)
        size = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = Self.deviceAddresses[1]
        let muteStatus = AudioObjectGetPropertyData(device, &muteAddress, 0, nil, &size, &muted)

        let newLevel = volumeStatus == noErr ? Int((volume * 100).rounded()) : nil
        let newIsMuted = muteStatus == noErr && muted != 0
        if level != newLevel { level = newLevel }
        if isMuted != newIsMuted { isMuted = newIsMuted }
    }
}

/// Connection type from NWPathMonitor; the Wi-Fi name needs Location Services permission on macOS 14+.
@MainActor
@Observable
final class NetworkModel {
    private(set) var connection = StatusSymbols.Connection.offline
    private(set) var name = ""

    @ObservationIgnored private let monitor = NWPathMonitor()

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            MainActor.assumeIsolated { self?.update(path) }
        }
        monitor.start(queue: .main)
    }

    private func update(_ path: NWPath) {
        let newConnection: StatusSymbols.Connection
        let newName: String
        // A VPN tunnel becomes the path's only interface, so look at the physical links underneath it.
        let interfaceTypes = Set(path.availableInterfaces.map(\.type))
        if path.status != .satisfied {
            newConnection = .offline
            newName = ""
        } else if interfaceTypes.contains(.wifi) {
            newConnection = .wifi
            newName = CWWiFiClient.shared().interface()?.ssid() ?? "Wi-Fi"
        } else if interfaceTypes.contains(.wiredEthernet) {
            newConnection = .ethernet
            newName = "Ethernet"
        } else {
            newConnection = .other
            newName = "Connected"
        }
        if connection != newConnection { connection = newConnection }
        if name != newName { name = newName }
    }
}
