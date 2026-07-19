import SwiftUI
import Security
import LocalAuthentication

struct securenotesvaultview: View {
    @State private var note = ""
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Secure Notes Vault", subtitle: "Store one encrypted local note in the macOS keychain with biometric unlock.", icon: "note.text.badge.lock", refreshing: false, action: unlock)
            TextEditor(text: $note).font(.body).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary)).frame(minHeight: 260)
            HStack { Button("Unlock") { unlock() }; Button("Save Note") { save() }.buttonStyle(.borderedProminent); Spacer(); Text(message).font(.caption).foregroundStyle(.secondary) }
        }.padding(24)
    }
    private let service = "com.juicer.secure-notes"
    private func unlock() { let context = LAContext(); context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Juicer Secure Notes") { success, error in guard success else { DispatchQueue.main.async { message = error?.localizedDescription ?? "Unlock failed." }; return }; let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecReturnData as String: true]; var item: CFTypeRef?; let status = SecItemCopyMatching(query as CFDictionary, &item); DispatchQueue.main.async { if status == errSecSuccess, let data = item as? Data { note = String(data: data, encoding: .utf8) ?? ""; message = "Vault unlocked." } else { message = "No saved note yet." } } } }
    private func save() { let data = Data(note.utf8); let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]; let update = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary); if update == errSecItemNotFound { let add = SecItemAdd(query.merging([kSecValueData as String: data]) { _, new in new } as CFDictionary, nil); message = add == errSecSuccess ? "Note saved in keychain." : "Unable to save note." } else { message = update == errSecSuccess ? "Note saved in keychain." : "Unable to save note." } }
}
