//
// VaultStore.swift
// Anonycord
//
// Private in-app storage for recordings. Lives in Application Support,
// which is not exposed to the Files app and never touches the photo library.
//

import Foundation

final class VaultStore {
    static let shared = VaultStore()
    private init() {
        try? FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true)
    }

    private var vaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Vault", isDirectory: true)
    }

    @discardableResult
    func importVideo(from sourceURL: URL) -> URL? {
        try? FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true)
        let stamp = Self.formatter.string(from: Date())
        let dest = vaultURL.appendingPathComponent("AC_\(stamp)_\(UUID().uuidString.prefix(4)).mov")
        do {
            try FileManager.default.copyItem(at: sourceURL, to: dest)
            return dest
        } catch {
            print("vault import failed: \(error)")
            return nil
        }
    }

    func allRecordings() -> [URL] {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: vaultURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles])) ?? []
        return items
            .filter { $0.pathExtension.lowercased() == "mov" }
            .sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return da > db
            }
    }

    func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return f
    }()
}
