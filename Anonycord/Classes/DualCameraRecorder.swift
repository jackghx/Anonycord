//
// DualCameraRecorder.swift
// Anonycord
//
// Records front and back cameras at the same time into two separate files
// using AVCaptureMultiCamSession. Only used when dual capture is enabled.
//

import AVFoundation
import UIKit

class DualCameraRecorder: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {

    static var isSupported: Bool { AVCaptureMultiCamSession.isMultiCamSupported }

    private var session: AVCaptureMultiCamSession?
    private let frontOutput = AVCaptureMovieFileOutput()
    private let backOutput = AVCaptureMovieFileOutput()

    private var pendingStops = 0
    private var finishedURLs: [URL] = []
    private var onAllFinished: (([URL]) -> Void)?

    func setup() {
        guard Self.isSupported else {
            print("Multi-cam is not supported on this device.")
            return
        }
        let session = AVCaptureMultiCamSession()
        session.beginConfiguration()

        // Back camera -> backOutput
        if let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let backInput = try? AVCaptureDeviceInput(device: backDevice),
           session.canAddInput(backInput) {
            session.addInputWithNoConnections(backInput)
            if session.canAddOutput(backOutput) {
                session.addOutputWithNoConnections(backOutput)
            }
            if let port = backInput.ports(for: .video, sourceDeviceType: backDevice.deviceType, sourceDevicePosition: .back).first {
                let conn = AVCaptureConnection(inputPorts: [port], output: backOutput)
                if session.canAddConnection(conn) { session.addConnection(conn) }
            }
        }

        // Front camera -> frontOutput
        if let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let frontInput = try? AVCaptureDeviceInput(device: frontDevice),
           session.canAddInput(frontInput) {
            session.addInputWithNoConnections(frontInput)
            if session.canAddOutput(frontOutput) {
                session.addOutputWithNoConnections(frontOutput)
            }
            if let port = frontInput.ports(for: .video, sourceDeviceType: frontDevice.deviceType, sourceDevicePosition: .front).first {
                let conn = AVCaptureConnection(inputPorts: [port], output: frontOutput)
                if session.canAddConnection(conn) { session.addConnection(conn) }
            }
        }

        // Audio -> both outputs
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInputWithNoConnections(audioInput)
            if let audioPort = audioInput.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .unspecified).first {
                let backAudio = AVCaptureConnection(inputPorts: [audioPort], output: backOutput)
                if session.canAddConnection(backAudio) { session.addConnection(backAudio) }
                let frontAudio = AVCaptureConnection(inputPorts: [audioPort], output: frontOutput)
                if session.canAddConnection(frontAudio) { session.addConnection(frontAudio) }
            }
        }

        session.commitConfiguration()
        self.session = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func startRecording() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backURL = dir.appendingPathComponent("back.mov")
        let frontURL = dir.appendingPathComponent("front.mov")
        try? FileManager.default.removeItem(at: backURL)
        try? FileManager.default.removeItem(at: frontURL)

        finishedURLs = []
        pendingStops = 2
        backOutput.startRecording(to: backURL, recordingDelegate: self)
        frontOutput.startRecording(to: frontURL, recordingDelegate: self)
    }

    func stopRecording(completion: @escaping ([URL]) -> Void) {
        onAllFinished = completion
        backOutput.stopRecording()
        frontOutput.stopRecording()
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if error == nil {
            finishedURLs.append(outputFileURL)
        } else {
            print("Dual recording error: \(error!.localizedDescription)")
        }
        pendingStops -= 1
        if pendingStops <= 0 {
            let urls = finishedURLs
            DispatchQueue.main.async {
                self.onAllFinished?(urls)
            }
        }
    }

    func teardown() {
        session?.stopRunning()
        session = nil
    }
}
