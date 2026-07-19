import SwiftUI

struct bettercmdtabwindow: Identifiable {
    let id: CGWindowID
    let app: NSRunningApplication
    let image: NSImage?
}

struct bettercmdtaboverlayview: View {
    let windows: [bettercmdtabwindow]
    let select: (NSRunningApplication) -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("BetterCmdTab").font(.headline)
                    Text("Switch between running applications")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Dismiss", action: dismiss)
                    .keyboardShortcut(.escape, modifiers: [])
            }

            if windows.isEmpty {
                ContentUnavailableView("No Applications", systemImage: "app.dashed", description: Text("No switchable applications are running."))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(windows) { window in
                            Button { select(window.app) } label: {
                                VStack(spacing: 9) {
                                    if let image = window.image {
                                        Image(nsImage: image).resizable().scaledToFit().frame(width: 84, height: 52)
                                    } else if let icon = window.app.icon {
                                        Image(nsImage: icon).resizable().scaledToFit().frame(width: 52, height: 52)
                                    } else {
                                        Image(systemName: "app.fill").font(.system(size: 42)).frame(width: 52, height: 52)
                                    }
                                    Text(window.app.localizedName ?? "Application").font(.caption).lineLimit(1).frame(maxWidth: 96)
                                }
                                .padding(12).frame(width: 120, height: 112)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(20).frame(minWidth: 420, idealWidth: 620, minHeight: 160, idealHeight: 190)
        .background(.ultraThinMaterial)
    }
}
