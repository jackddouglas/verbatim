import SwiftUI

// Scene focus routes commands to the correct window, including when several are open.
struct TranscriptActions {
    let chooseFolder: () -> Void
    let refresh: () -> Void
    let copy: () -> Void
    let export: () -> Void
    let openPodcasts: () -> Void
    let canRead: Bool
    let scanning: Bool
    let timestamps: Binding<Bool>
}

private struct TranscriptActionsKey: FocusedValueKey {
    typealias Value = TranscriptActions
}

extension FocusedValues {
    var transcriptActions: TranscriptActions? {
        get { self[TranscriptActionsKey.self] }
        set { self[TranscriptActionsKey.self] = newValue }
    }
}

struct TranscriptCommands: Commands {
    @FocusedValue(\.transcriptActions) private var actions

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Choose Transcript Folder…") { actions?.chooseFolder() }
                .keyboardShortcut("o").disabled(actions == nil || actions?.scanning == true)
            Button("Export Transcript…") { actions?.export() }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(actions?.canRead != true)
        }
        CommandGroup(after: .pasteboard) {
            Button("Copy Transcript") { actions?.copy() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(actions?.canRead != true)
        }
        CommandGroup(after: .sidebar) {
            Toggle("Show Timestamps", isOn: actions?.timestamps ?? .constant(false))
                .disabled(actions == nil)
            Button("Refresh Transcripts") { actions?.refresh() }
                .keyboardShortcut("r").disabled(actions == nil || actions?.scanning == true)
        }
        CommandGroup(after: .appInfo) {
            Button("Open Apple Podcasts") { actions?.openPodcasts() }
                .disabled(actions == nil)
        }
    }
}
