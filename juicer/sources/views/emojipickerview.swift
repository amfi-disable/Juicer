import SwiftUI
import AppKit

struct emojipickerview: View { let emojis = ["😀","😂","🥳","🚀","❤️","✨","🔥","👍","🎉","🌈","🍎","🐱","☕️","✅","🤖"]; @State private var search = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Emoji Picker", subtitle: "Search and copy frequently used emoji characters.", icon: "face.smiling", refreshing: false, action: {}) ; TextField("Search or filter", text: $search); LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) { ForEach(emojis.filter { search.isEmpty || $0.contains(search) }, id: \.self) { emoji in Button(emoji) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(emoji, forType: .string) }.font(.largeTitle).buttonStyle(.plain) } }; Spacer() }.padding(24) } }
