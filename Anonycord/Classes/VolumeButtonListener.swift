//
// VolumeButtonListener.swift
// Anonycord
//

import AVFoundation
import MediaPlayer
import UIKit

class VolumeButtonListener: NSObject, ObservableObject {
    var onPress: (() -> Void)?

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?
    private var volumeView: MPVolumeView?
    private var ignoreNextChange = false
    private let baseline: Float = 0.5

    func startListening() {
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("volume listener session error: \(error)")
        }

        addHiddenVolumeView()
        setSystemVolume(baseline)

        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            if self.ignoreNextChange {
                self.ignoreNextChange = false
                return
            }
            // reset toward the middle so repeated presses keep registering
            self.ignoreNextChange = true
            self.setSystemVolume(self.baseline)
            DispatchQueue.main.async {
                self.onPress?()
            }
        }

    func stopListening() {
        observation?.invalidate()
        observation = nil
        volumeView?.removeFromSuperview()
        volumeView = nil
    }

    private func addHiddenVolumeView() {
        let view = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
        view.alpha = 0.001
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.addSubview(view)
        }
        volumeView = view
    }

    private func setSystemVolume(_ value: Float) {
        guard let slider = volumeView?.subviews.compactMap({ $0 as? UISlider }).first else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            slider.value = value
        }
    }
}
