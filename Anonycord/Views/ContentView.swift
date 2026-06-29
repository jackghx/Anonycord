//
//  ContentView.swift
//  Anonycord
//
//  Created by Constantin Clerc on 7/8/24.
//
// Forked by Jack Ghafari on 29/06/26
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingSettings = false
    @State private var isRecordingVideo = false
    @State private var isRecordingAudio = false
    @State private var videoRecordingURL: URL?
    @State private var showingFilePicker = false
    @State private var boxSize: CGFloat = UIScreen.main.bounds.width - 60
    @StateObject private var mediaRecorder = MediaRecorder()
    @StateObject private var volumeListener = VolumeButtonListener()
    @Environment(\.scenePhase) private var scenePhase
    @State private var savedBrightness: CGFloat = UIScreen.main.brightness
    @State private var isDimmed = false
    @State private var inBeta = true
    
    var body: some View {
        ZStack {
            if isRecordingAudio || isRecordingVideo {
                Rectangle()
                    .fill(Color.black)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if isRecordingVideo {
                            toggleVideoRecording()
                        }
                        if isRecordingAudio {
                            toggleAudioRecording()
                        }
                    }
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }

            VStack {
                Spacer() // spacer sandwich 🥪
                if !isRecordingAudio && !isRecordingVideo {
                    Image(uiImage: Bundle.main.icon!)
                        .cornerRadius(10)
                        .transition(.scale)
                    Text("Anonycord")
                        .font(.system(size: UIFont.preferredFont(forTextStyle: .title2).pointSize, weight: .bold))
                        .transition(.scale)
                    if inBeta {
                        Text("v\(Bundle.main.releaseVersionNumber ?? "0.0") Beta \(Bundle.main.buildVersionNumber ?? "0") - by c22dev, forked by Jack Ghafari")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Text("v\(Bundle.main.releaseVersionNumber ?? "0.0") - by c22dev, forked by Jack Ghafari")
                            .font(.footnote)F
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if !appSettings.hideAll || (!isRecordingAudio && !isRecordingVideo) {
                    HStack {
                        if !isRecordingAudio {
                            RecordButton(isRecording: $isRecordingVideo, action: toggleVideoRecording, icon: "video.circle.fill")
                                .transition(.scale)
//                                .contextMenu {
//                                Button(action: {
//                                    print("shhh...")
//                                }, label:
//                                        {
//                                    Text("Standard")
//                                })
//                            }
                            if !isRecordingVideo {
                                Spacer()
                            }
                        }
                        
                        if !isRecordingVideo {
                            RecordButton(isRecording: $isRecordingAudio, action: toggleAudioRecording, icon: "mic.circle.fill")
                                .transition(.scale)
                            if !isRecordingAudio {
                                Spacer()
                            }
                        }
                        
                        if !isRecordingVideo && !isRecordingAudio {
                            ControlButton(action: takePhoto, icon: "camera.circle.fill")
                                .transition(.scale)
                            Spacer()
                            ControlButton(action: { showingSettings.toggle() }, icon: "gear.circle.fill")
                                .sheet(isPresented: $showingSettings) {
                                    SettingsView(mediaRecorder: mediaRecorder)
                                }
                                .transition(.scale)
                        }
                    }
                    .padding()
                    .frame(width: boxSize)
                    .background(VisualEffectBlur(blurStyle: .systemThinMaterialDark))
                    .cornerRadius(30)
                    .padding()
                    .onChange(of: isRecordingVideo) { _ in
                        withAnimation {
                            boxSize = isRecordingVideo ? 100 : (UIScreen.main.bounds.width - 60)
                        }
                    }
                    .onChange(of: isRecordingAudio) { _ in
                        withAnimation {
                            boxSize = isRecordingAudio ? 100 : (UIScreen.main.bounds.width - 60)
                        }
                    }
                }
                if !isRecordingAudio && !isRecordingVideo && appSettings.showSettingsAtBttm {
                    Text("Current Parameters : \(appSettings.videoQuality), \(appSettings.cameraType)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            if appSettings.blackoutMode {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())
                    .gesture(
                        ExclusiveGesture(
                            LongPressGesture(minimumDuration: 1.2)
                                .onEnded { _ in
                                    if !isRecordingVideo && !isRecordingAudio {
                                        showingSettings = true
                                    }
                                },
                            TapGesture()
                                .onEnded {
                                    toggleVideoRecording()
                                }
                        )
                    )
            }
            
        }
        .onAppear(perform: setup)
        .statusBarHidden(appSettings.blackoutMode)
        .hideSystemOverlays(appSettings.blackoutMode)
        .onChange(of: appSettings.blackoutMode) { newValue in
            if newValue { dimForBlackout() } else { restoreBrightness() }
        }
        .onChange(of: showingSettings) { isOpen in
            if isOpen { restoreBrightness() } else { dimForBlackout() }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: dimForBlackout()
            case .background: restoreBrightness()
            default: break
            }
        }
    }
        
    private func setup() {
            mediaRecorder.requestPermissions()
            mediaRecorder.setupCaptureSession()
    
            if appSettings.volumeButtonTrigger {
                volumeListener.onPress = {
                    if !isRecordingAudio { toggleVideoRecording() }
                }
                volumeListener.startListening()
            }
    
            if appSettings.autoStart {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(appSettings.autoStartDelay)) {
                    if !isRecordingVideo && !isRecordingAudio {
                        toggleVideoRecording()
                    }
                }
            }

            if appSettings.blackoutMode {
                dimForBlackout()
            }
        }

        private func dimForBlackout() {
            guard appSettings.blackoutMode, !showingSettings else { return }
            if !isDimmed {
                savedBrightness = UIScreen.main.brightness
                isDimmed = true
            }
            UIScreen.main.brightness = 0.0
        }

        private func restoreBrightness() {
            guard isDimmed else { return }
            UIScreen.main.brightness = savedBrightness
            isDimmed = false
        }
    
        private func toggleVideoRecording() {
            if isRecordingVideo {
                mediaRecorder.stopVideoRecording()
                UIApplication.shared.isIdleTimerDisabled = false
                if appSettings.hapticFeedback { Haptic.recordingStopped() }
            } else {
                UIApplication.shared.isIdleTimerDisabled = true
                if appSettings.hapticFeedback { Haptic.recordingStarted() }
                mediaRecorder.startVideoRecording { url in
                    if let url = url {
                        mediaRecorder.saveVideoToLibrary(videoURL: url)
                    }
                    isRecordingVideo = false
                }
            }
            isRecordingVideo.toggle()
        }

        private func toggleAudioRecording() {
                if isRecordingAudio {
                    UIApplication.shared.isIdleTimerDisabled = false
                    mediaRecorder.stopAudioRecording()
                    if appSettings.hapticFeedback { Haptic.recordingStopped() }
                } else {
                    UIApplication.shared.isIdleTimerDisabled = true
                    if appSettings.hapticFeedback { Haptic.recordingStarted() }
                    mediaRecorder.startAudioRecording()
                }
                isRecordingAudio.toggle()
            }
        
            private func takePhoto() {
                mediaRecorder.takePhoto()
            }
        }
        
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View {
                ContentView()
                    .environmentObject(AppSettings())
            }
        }
