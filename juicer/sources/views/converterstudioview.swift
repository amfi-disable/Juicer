import SwiftUI
import AppKit

struct converterstudioview: View {
    @State private var inputText = "{\n  \"name\": \"Juicer\",\n  \"version\": \"1.0.3\",\n  \"active\": true\n}"
    @State private var outputText = ""
    @State private var converterMode = "JSON to Swift"
    
    var body: some View {
        VStack(spacing: 0) {
            JuicerFeatureHeader(
                title: "Juicer Converter Studio",
                subtitle: "Offline converter for documents, code schemas, JSON models, text encodings, and colors.",
                icon: "arrow.triangle.2.circlepath.doc.on.clipboard",
                refreshing: false,
                action: { convertInput() }
            )
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            HStack {
                Picker("Conversion Mode:", selection: $converterMode) {
                    Text("JSON → Swift Struct").tag("JSON to Swift")
                    Text("JSON → TypeScript Interface").tag("JSON to TS")
                    Text("Base64 Encode").tag("Base64 Encode")
                    Text("Base64 Decode").tag("Base64 Decode")
                    Text("URL Encode").tag("URL Encode")
                }
                .onChange(of: converterMode) { _ in convertInput() }
                
                Spacer()
                
                Button("Copy Output") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(outputText, forType: .string)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            HSplitView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input Text").font(.headline)
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: inputText) { _ in convertInput() }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Converted Output").font(.headline)
                    TextEditor(text: .constant(outputText))
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
            }
        }
        .onAppear { convertInput() }
        .allowWindowDragAndFit()
    }
    
    private func convertInput() {
        switch converterMode {
        case "JSON to Swift":
            outputText = convertJSONToSwift(json: inputText)
        case "JSON to TS":
            outputText = convertJSONToTS(json: inputText)
        case "Base64 Encode":
            outputText = Data(inputText.utf8).base64EncodedString()
        case "Base64 Decode":
            if let data = Data(base64Encoded: inputText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                outputText = String(data: data, encoding: .utf8) ?? "Invalid Base64 data."
            } else {
                outputText = "Invalid Base64 string."
            }
        case "URL Encode":
            outputText = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputText
        default:
            outputText = inputText
        }
    }
    
    private func convertJSONToSwift(json: String) -> String {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var code = "struct GeneratedModel: Codable {\n"
        for (key, val) in dict {
            let swiftType: String
            if val is String { swiftType = "String" }
            else if val is Int { swiftType = "Int" }
            else if val is Double { swiftType = "Double" }
            else if val is Bool { swiftType = "Bool" }
            else if val is [Any] { swiftType = "[String]" }
            else { swiftType = "AnyCodable" }
            code += "    let \(key): \(swiftType)\n"
        }
        code += "}"
        return code
    }
    
    private func convertJSONToTS(json: String) -> String {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "// Invalid JSON object."
        }
        var code = "export interface GeneratedModel {\n"
        for (key, val) in dict {
            let tsType: String
            if val is String { tsType = "string" }
            else if val is Int || val is Double { tsType = "number" }
            else if val is Bool { tsType = "boolean" }
            else if val is [Any] { tsType = "any[]" }
            else { tsType = "any" }
            code += "  \(key): \(tsType);\n"
        }
        code += "}"
        return code
    }
}
