import AppKit
import SwiftUI
import TranscriptCore
import UniformTypeIdentifiers

@main
struct VerbatimApp: App {
    init() {
        if CommandLine.arguments.contains("--check-cache") {
            do {
                let scan = try PodcastLibrary.scan()
                for episode in scan.episodes {
                    let transcript = try episode.load()
                    print("\(episode.title): \(transcript.paragraphs.count) paragraphs, \(transcript.wordCount) words")
                }
                for warning in scan.warnings { print("Warning: \(warning)") }
                print("Read \(scan.episodes.count) complete TTML files.")
                exit(0)
            } catch { print(error.localizedDescription); exit(1) }
        }
    }
    var body: some Scene {
        WindowGroup { ContentView() }
            .defaultSize(width: 1040, height: 720)
            .commands {
                SidebarCommands()
                TranscriptCommands()
            }
    }
}

private struct ReaderRequest: Hashable {
    let file: URL?
    let revision: Int
}

struct ContentView: View {
    @State private var episodes: [Episode] = []
    @State private var selection: URL?
    @State private var transcript: Transcript?
    @State private var root = PodcastLibrary.defaultRoot
    @State private var query = ""
    @State private var scanning = false
    @State private var loading = false
    @State private var message: String?
    @State private var readError: String?
    @State private var timestamps = false
    @State private var copied = false
    @State private var revision = 0

    private var selected: Episode? { episodes.first { $0.id == selection } }
    private var filtered: [Episode] {
        episodes.filter { query.isEmpty || "\($0.title) \($0.show)".localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(filtered) { episode in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(episode.title).font(.body).lineLimit(2)
                            Text(episode.show).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        }
                        .padding(.vertical, 5)
                        .tag(episode.id)
                    }
                }
                .listStyle(.sidebar)
                .overlay {
                    if !scanning && episodes.isEmpty {
                        Text("No Transcripts")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center).padding()
                    } else if !episodes.isEmpty && filtered.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }
            .navigationTitle("Transcripts")
            .navigationSplitViewColumnWidth(min: 250, ideal: 310, max: 420)
            .frame(minWidth: 250)
        } detail: {
            VStack(spacing: 0) {
                if let message {
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle")
                        Text(message).textSelection(.enabled)
                        Spacer()
                        Button { self.message = nil } label: { Image(systemName: "xmark") }
                            .buttonStyle(.plain).accessibilityLabel("Dismiss message")
                    }
                    .font(.callout).padding().background(.quaternary)
                }
                if let selected {
                    reader(selected)
                } else if scanning && episodes.isEmpty {
                    ProgressView("Finding transcripts…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if episodes.isEmpty {
                    ContentUnavailableView {
                        Label("Add a Transcript", systemImage: "text.quote")
                    } description: {
                        Text("Open an episode in Apple Podcasts and choose View Transcript. Then return here and click Refresh.")
                            .frame(maxWidth: 340)
                    } actions: {
                        Button("Open Apple Podcasts", action: openPodcasts)
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                            .fixedSize()
                    }
                } else {
                    ContentUnavailableView("Select a Transcript", systemImage: "text.quote",
                        description: Text("Choose an episode in the sidebar to read, copy, or export its transcript."))
                }
            }
            .navigationTitle("Transcripts")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: chooseFolder) {
                        Label("Choose Transcript Folder…", systemImage: "folder")
                    }
                    .disabled(scanning)
                    .help("Choose a transcript folder (Command-O)")
                    Button(action: refresh) {
                        Label("Refresh Transcripts", systemImage: "arrow.clockwise")
                    }
                    .disabled(scanning)
                    .help("Refresh transcripts (Command-R)")
                }
                ToolbarSpacer(.fixed)
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: copy) {
                        Label(copied ? "Copied" : "Copy Transcript", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(transcript == nil)
                    .help("Copy the full transcript (Shift-Command-C)")
                    Button(action: export) {
                        Label("Export Transcript…", systemImage: "square.and.arrow.up")
                    }
                    .disabled(transcript == nil)
                    .help("Export the full transcript (Shift-Command-E)")
                }
                .visibilityPriority(.high)
                ToolbarSpacer(.fixed)
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Toggle("Show Timestamps", isOn: $timestamps)
                        Divider()
                        Button("Open Apple Podcasts", action: openPodcasts)
                    } label: {
                        Label("Transcript Options", systemImage: "ellipsis")
                    }
                    .help("Transcript options")
                }
            }
        }
        .searchable(text: $query, placement: .toolbar, prompt: "Search")
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 520)
        .focusedSceneValue(\.transcriptActions, TranscriptActions(
            chooseFolder: chooseFolder, refresh: refresh, copy: copy, export: export,
            openPodcasts: openPodcasts, canRead: transcript != nil, scanning: scanning,
            timestamps: $timestamps
        ))
        .task { refresh() }
        .onChange(of: timestamps) { copied = false }
        .task(id: ReaderRequest(file: selection, revision: revision)) {
            transcript = nil
            readError = nil
            copied = false
            loading = false
            guard let selected else { return }
            loading = true
            do {
                let result = try await Task.detached(priority: .userInitiated) { try selected.load() }.value
                guard !Task.isCancelled else { return }
                transcript = result
            } catch {
                guard !Task.isCancelled else { return }
                readError = error.localizedDescription
            }
            loading = false
        }
    }

    @ViewBuilder private func reader(_ episode: Episode) -> some View {
        if loading {
            ProgressView("Reading transcript…").frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let readError {
            ContentUnavailableView("Unable to Read Transcript", systemImage: "exclamationmark.triangle", description: Text(readError))
        } else if let transcript {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(episode.show).font(.subheadline).foregroundStyle(.secondary)
                        Text(episode.title).font(.title.bold()).accessibilityAddTraits(.isHeader)
                        Text("\(transcript.wordCount.formatted()) words")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text(transcript.text(timestamps: timestamps))
                        .font(.body).lineSpacing(6)
                    Text("Extracted from the transcript cached by Apple Podcasts.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .textSelection(.enabled)
                .frame(maxWidth: 680, alignment: .leading)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .id(episode.id)
        }
    }

    private func refresh() {
        guard !scanning else { return }
        scanning = true
        message = nil
        let folder = root
        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) { try PodcastLibrary.scan(root: folder) }.value
                episodes = result.episodes
                message = result.warnings.isEmpty ? nil : result.warnings.joined(separator: "\n")
                // Reload even if the selected file was updated in place by Podcasts.
                if !episodes.contains(where: { $0.id == selection }) {
                    selection = episodes.first?.id
                }
                revision += 1
            } catch {
                message = "Could not read the transcript folder. \(error.localizedDescription) Use Choose Folder to select the Apple Podcasts container or a folder containing TTML files."
            }
            scanning = false
        }
    }
    private func chooseFolder() {
        guard !scanning else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = root
        panel.message = "Choose the Apple Podcasts container or a folder containing TTML transcripts."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        root = url
        selection = nil
        refresh()
    }
    private func openPodcasts() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.podcasts") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in }
        }
    }
    private func copy() {
        guard let transcript else { return }
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(transcript.text(timestamps: timestamps), forType: .string)
    }
    private func export() {
        guard let transcript, let selected else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = selected.title.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-") + ".txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try transcript.text(timestamps: timestamps).write(to: url, atomically: true, encoding: .utf8) }
        catch { message = "Export failed: \(error.localizedDescription)" }
    }
}
