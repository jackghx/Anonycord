//
//  SettingsView.swift
//  Anonycord
//
//  Created by Constantin Clerc on 7/8/24.
//
// Forked by Jack Ghafari on 29/06/26
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.openURL) var openURL
    
    @State private var micSplRateStr: String
    @State private var hapticFeedback: Bool
    @State private var volumeButtonTrigger: Bool
    @State private var autoStart: Bool
    @State private var channelDefStr: String
    @State private var blackoutMode: Bool
    @State private var cameraType: String
    @State private var videoQuality: String
    @State private var exitAtEnd: Bool
    @State private var infoAtBttm: Bool
    @State private var hideAll: Bool
    
    @ObservedObject var mediaRecorder: MediaRecorder

    @State private var cameraTypes = ["Wide", "Selfie"]
    private let videoQualities = ["4K", "1080p"]
    
    init(mediaRecorder: MediaRecorder) {
        self.mediaRecorder = mediaRecorder
        _micSplRateStr = State(initialValue: String(AppSettings().micSampleRate))
        _channelDefStr = State(initialValue: String(AppSettings().channelDef))
        _cameraType = State(initialValue: AppSettings().cameraType)
        _videoQuality = State(initialValue: AppSettings().videoQuality)
        _exitAtEnd = State(initialValue: AppSettings().crashAtEnd)
        _infoAtBttm = State(initialValue: AppSettings().showSettingsAtBttm)
        _hideAll = State(initialValue: AppSettings().hideAll)
        _hapticFeedback = State(initialValue: AppSettings().hapticFeedback)
        _volumeButtonTrigger = State(initialValue: AppSettings().volumeButtonTrigger)
        _autoStart = State(initialValue: AppSettings().autoStart)
        _blackoutMode = State(initialValue: AppSettings().blackoutMode)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Label("Audio Recording", systemImage: "mic"), footer: Text("Settings for audio recording. Those settings also applies to video recording.")) {
                    Picker("Channels", selection: $channelDefStr) {
                        ForEach(channelsMapping.keys.sorted(), id: \.self) { abbreviation in
                            Text(channelsMapping[abbreviation] ?? abbreviation)
                                .tag(abbreviation)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: channelDefStr) { newValue in
                        appSettings.channelDef = Int(channelDefStr) ?? 1
                    }
                    HStack(spacing: 0) {
                        Text("Sample Rate")
                        Spacer()
                        TextField("44100", text: $micSplRateStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: micSplRateStr) { newValue in
                                micSplRateStr = newValue
                            }
                            .focused($isTextFieldFocused)
                        Text("Hz")
                    }
                    Button("Confirm Sample Rate") {
                        isTextFieldFocused = false
                        appSettings.micSampleRate = Int(micSplRateStr) ?? 44100
                        micSplRateStr = String(appSettings.micSampleRate)
                    }
                    Button("Reset Sample Rate") {
                        isTextFieldFocused = false
                        appSettings.micSampleRate = 44100
                        micSplRateStr = String(appSettings.micSampleRate)
                    }
                }
                Section(header: Label("Video Recording", systemImage: "video"), footer: Text("Options for video recording. Camera Type will also apply to photo settings.")) {
                    Picker("Video quality", selection: $videoQuality) {
                        ForEach(videoQualities, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: videoQuality) { newValue in
                        appSettings.videoQuality = videoQuality
                        DispatchQueue.main.async {
                            mediaRecorder.reconfigureCaptureSession()
                        }
                    }
                    Picker("Camera Type", selection: $cameraType) {
                        ForEach(cameraTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: cameraType) { newValue in
                        appSettings.cameraType = cameraType
                        DispatchQueue.main.async {
                            mediaRecorder.reconfigureCaptureSession()
                            
                        }
                    }
                    .onAppear {
                        if mediaRecorder.hasUltraWideCamera() {
                            cameraTypes.append("UltraWide")
                        }
                    }
                }
                Section(header: Label("Old Settings", systemImage: "eyedropper"), footer: Text("Other settings inspired from the original Anonycord (1.x). Those settings aren't recommended. Crash upon saving only applies to photo and video recording.")) {
                    Toggle(isOn: $exitAtEnd) {
                        Text("Crash upon saving")
                    }
                    .onChange(of: exitAtEnd) { newValue in
                        appSettings.crashAtEnd = exitAtEnd
                    }
                    Toggle(isOn: $hideAll) {
                        Text("Hide All Controls While Recording")
                    }
                    .onChange(of: hideAll) { newValue in
                        if newValue {
                            UIApplication.shared.confirmAlert(title:"Instructions", body: "To stop and save videos with this option enabled, you just have to click anywhere on the screen.", onOK: {}, noCancel: true)
                        }
                        appSettings.hideAll = hideAll
                    }
                }
                Section(header: Label("UI", systemImage: "pencil"), footer: Text("Settings for user interface.")) {
                    Toggle(isOn: $infoAtBttm) {
                        Text("Show Recording Info")
                    }
                    .onChange(of: infoAtBttm) { newValue in
                        appSettings.showSettingsAtBttm = infoAtBttm
                    }
                }

                Section(header: Label("Skit Mode", systemImage: "eye.slash"),
                        footer: Text("Haptic confirmation, a physical volume-button trigger, and auto-start for hands-free use.")) {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .onChange(of: hapticFeedback) { newValue in appSettings.hapticFeedback = newValue }
                    Toggle("Volume Button Trigger", isOn: $volumeButtonTrigger)
                        .onChange(of: volumeButtonTrigger) { newValue in appSettings.volumeButtonTrigger = newValue }
                    Toggle("Auto-Start on Launch", isOn: $autoStart)
                        .onChange(of: autoStart) { newValue in appSettings.autoStart = newValue }
                    Toggle("Blackout (tap anywhere to record)", isOn: $blackoutMode)
                        .onChange(of: blackoutMode) { newValue in appSettings.blackoutMode = newValue }
                }
                
                Section(header: Label("Links", systemImage: "link"), footer: Text("A few links to my socials to contact me if you need help (Forked from c22dev).")) {
                    Button("Github") {
                        openURL(URL(string: "https://github.com/jackghx/Anonycord")!)
                    }
                    Button("Discord") {
                        openURL(URL(string: "N/A")!)
                    }
                    Button("Website") {
                        openURL(URL(string: "https://jackghx.com")!)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}


let channelsMapping: [String: String] = [
    "1": "Mono",
    "2": "Stereo",
]
