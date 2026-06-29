//
// VaultView.swift
// Anonycord
//
// Face ID gated viewer for the private vault.
//

import SwiftUI
import LocalAuthentication
import AVKit

private struct VaultItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct VaultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = false
    @State private var authError: String?
    @State private var recordings: [URL] = []
    @State private var selected: VaultItem?

    var body: some View {
        NavigationView {
            Group {
                if unlocked {
                    if recordings.isEmpty {
                        Text("No recordings in the vault.")
                            .foregroundColor(.secondary)
                    } else {
                        List {
                            ForEach(recordings, id: \.self) { url in
                                Button {
                                    selected = VaultItem(url: url)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(url.deletingPathExtension().lastPathComponent)
                                        Text(Self.sizeString(url))
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                for i in offsets { VaultStore.shared.delete(recordings[i]) }
                                recordings = VaultStore.shared.allRecordings()
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(authError ?? "Locked")
                            .foregroundColor(.secondary)
                        Button("Unlock") { authenticate() }
                    }
                }
            }
            .navigationTitle("Vault")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selected) { item in
                VideoPlayer(player: AVPlayer(url: item.url))
                    .ignoresSafeArea()
            }
        }
        .onAppear(perform: authenticate)
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: "Unlock the Anonycord vault") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        unlocked = true
                        recordings = VaultStore.shared.allRecordings()
                    } else {
                        authError = "Authentication failed. Tap Unlock to retry."
                    }
                }
            }
        } else {
            authError = "Face ID or a passcode is not set up on this device."
        }
    }

    private static func sizeString(_ url: URL) -> String {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", mb)
    }
}
