//
//  AnonycordApp.swift
//  Anonycord
//
//  Created by Constantin Clerc on 7/8/24.
//
// Forked by Jack Ghafari on 29/06/26
//

import SwiftUI

@main
struct AnonycordApp: App {
    @StateObject private var appSettings = AppSettings()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("micSampleRate") var micSampleRate: Int = 44100
    @AppStorage("channelDef") var channelDef: Int = 1
    @AppStorage("cameraType") var cameraType: String = "Wide"
    @AppStorage("videoQuality") var videoQuality: String = "1080p"
    @AppStorage("crashAtEnd") var crashAtEnd: Bool = false
    @AppStorage("showSettingsAtBttm") var showSettingsAtBttm: Bool = true
    @AppStorage("hideAll") var hideAll: Bool = false
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @AppStorage("volumeButtonTrigger") var volumeButtonTrigger: Bool = false
    @AppStorage("autoStart") var autoStart: Bool = false
    @AppStorage("autoStartDelay") var autoStartDelay: Int = 3
    @AppStorage("blackoutMode") var blackoutMode: Bool = false
    @AppStorage("sortToAlbum") var sortToAlbum: Bool = true
    @AppStorage("recordingDestination") var recordingDestination: String = "library"
}
