//
//  CheckInSoundPlayer.swift
//  WaiveGO
//
//  Plays the "go"/"stop" audio cue for a check-in result. Tones are generated on the
//  fly (short sine-wave beeps) rather than bundled as audio files, so there's nothing
//  external to ship or swap out later if the sound needs tuning.

import AVFoundation

@MainActor
final class CheckInSoundPlayer {
    static let shared = CheckInSoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // .playback so the kiosk is audible even if the iPad's silent switch is on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    /// Waiver found and valid — a short, upbeat two-note "go" chime.
    func playVerified() {
        play(notes: [(880, 0.12), (1318.5, 0.22)])
    }

    /// Waiver not found / expired / no match — a lower two-note "stop" buzz.
    func playNotVerified() {
        play(notes: [(320, 0.16), (220, 0.28)])
    }

    private func play(notes: [(frequency: Double, duration: Double)]) {
        if !engine.isRunning {
            try? engine.start()
        }

        player.stop()
        for note in notes {
            player.scheduleBuffer(tone(frequency: note.frequency, duration: note.duration))
        }
        player.play()
    }

    /// A sine-wave tone with a short fade in/out to avoid clicks at the buffer edges.
    private func tone(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let samples = buffer.floatChannelData![0]
        let amplitude: Float = 0.35
        let fadeFrames = min(200, Int(frameCount) / 4)

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let wave = Float(sin(2.0 * .pi * frequency * t))

            var envelope: Float = 1.0
            if frame < fadeFrames {
                envelope = Float(frame) / Float(fadeFrames)
            } else if frame > Int(frameCount) - fadeFrames {
                envelope = Float(Int(frameCount) - frame) / Float(fadeFrames)
            }

            samples[frame] = wave * amplitude * envelope
        }

        return buffer
    }
}
