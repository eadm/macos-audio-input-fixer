import Foundation
import CoreAudio

func deviceName(_ id: AudioDeviceID) -> String {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceNameCFString,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var name: Unmanaged<CFString>? = nil
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &name)
    return name?.takeRetainedValue() as String? ?? "(unknown)"
}

func findBuiltInInputDevice() -> AudioDeviceID? {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &dataSize) == noErr else { return nil }

    let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
    var devices = [AudioDeviceID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &dataSize, &devices) == noErr else { return nil }

    for id in devices {
        // Must be built-in transport
        var tAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var tSize = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &tAddr, 0, nil, &tSize, &transport) == noErr,
              transport == kAudioDeviceTransportTypeBuiltIn else { continue }

        // Must have at least one input channel
        var iAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var iSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &iAddr, 0, nil, &iSize) == noErr, iSize > 0 else { continue }

        let bufList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(iSize))
        defer { bufList.deallocate() }
        guard AudioObjectGetPropertyData(id, &iAddr, 0, nil, &iSize, bufList) == noErr,
              bufList.pointee.mNumberBuffers > 0 else { continue }

        return id
    }
    return nil
}

func getDefaultInput() -> AudioDeviceID {
    var id: AudioDeviceID = kAudioObjectUnknown
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &id)
    return id
}

func setDefaultInput(_ id: AudioDeviceID) {
    var mutableID = id
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &mutableID)
}

guard let builtInID = findBuiltInInputDevice() else {
    fputs("Error: built-in microphone not found\n", stderr)
    exit(1)
}

print("AudioInputFixer started — locked to: \(deviceName(builtInID))")

let current = getDefaultInput()
if current != builtInID {
    print("Switching from '\(deviceName(current))' to built-in mic on startup")
    setDefaultInput(builtInID)
}

var listenerAddr = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &listenerAddr, DispatchQueue.main) { _, _ in
    let cur = getDefaultInput()
    guard cur != builtInID else { return }
    print("[\(Date())] Input changed to '\(deviceName(cur))' — reverting to built-in mic")
    setDefaultInput(builtInID)
}

RunLoop.main.run()
