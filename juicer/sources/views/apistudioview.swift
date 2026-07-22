import SwiftUI
import AppKit

struct apistudioview: View {
    @StateObject private var manager = APIManager.shared
    @State private var selectedTab = 0
    @State private var selectedMethod = "GET"
    @State private var urlInput = "https://api.github.com/zen"
    @State private var headersInput = "Accept: application/json\nUser-Agent: Juicer-API-Studio"
    @State private var bodyInput = ""
    @State private var curlInput = ""
    @State private var bearerToken = ""
    
    let methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.teal, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "paperplane.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Juicer API Studio")
                            .font(.title2).bold()
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("REST WORKBENCH READY")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.14), in: Capsule())
                    }
                    
                    Text("Native REST request workbench, cURL importer, load benchmarker, and header inspector")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Picker Tab Bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("REST Workbench").tag(0)
                    Text("cURL Importer").tag(1)
                    Text("Bearer & Auth").tag(2)
                    Text("Presets (\(manager.presets.count))").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 540)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            switch selectedTab {
            case 0:
                workbenchTabView()
            case 1:
                curlTabView()
            case 2:
                authTabView()
            default:
                presetsTabView()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Tab 1: REST Workbench
    @ViewBuilder
    private func workbenchTabView() -> some View {
        VStack(spacing: 12) {
            // URL Bar
            HStack(spacing: 8) {
                Picker("", selection: $selectedMethod) {
                    ForEach(methods, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }
                .frame(width: 100)
                
                TextField("Enter request URL (e.g. https://api.github.com/...)", text: $urlInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    manager.executeRequest(method: selectedMethod, urlString: urlInput, headersText: headersInput, bodyText: bodyInput)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(urlInput.isEmpty || manager.isExecuting)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            
            // Request Payload / Headers Split View
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Headers (Key: Value):")
                        .font(.caption.bold())
                    TextEditor(text: $headersInput)
                        .font(.system(.caption, design: .monospaced))
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("JSON Body Payload:")
                        .font(.caption.bold())
                    TextEditor(text: $bodyInput)
                        .font(.system(.caption, design: .monospaced))
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(height: 140)
            .padding(.horizontal, 20)
            
            Divider()
            
            // Response Viewer Box
            if let resp = manager.lastResponse {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        Text("STATUS: \(resp.statusCode)")
                            .font(.caption.bold())
                            .foregroundColor(resp.statusCode < 400 ? .green : .red)
                        Text("LATENCY: \(Int(resp.latencyMs)) ms")
                            .font(.caption.bold())
                            .foregroundColor(.cyan)
                        Text("SIZE: \(ByteCountFormatter.string(fromByteCount: resp.sizeBytes, countStyle: .file))")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
                    
                    ScrollView {
                        Text(resp.body)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Ready to Send Request")
                        .font(.headline)
                    Text("Click 'Send' to dispatch HTTP request and view output.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Tab 2: cURL Importer
    @ViewBuilder
    private func curlTabView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paste cURL Command")
                .font(.title3.bold())
            Text("Paste any standard `curl` command to automatically extract HTTP method, headers, and URL.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $curlInput)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(height: 120)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            
            Button("Import to Workbench") {
                if curlInput.contains("http") {
                    urlInput = curlInput.components(separatedBy: " ").first(where: { $0.hasPrefix("http") }) ?? urlInput
                    selectedTab = 0
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - Tab 3: Bearer & Auth
    @ViewBuilder
    private func authTabView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bearer Token & Auth Profiles")
                .font(.title3.bold())
            Text("Configure Bearer tokens to automatically append `Authorization: Bearer <token>` to requests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            SecureField("Paste Bearer Token", text: $bearerToken)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 400)
            
            Button("Apply Token to Headers") {
                if !bearerToken.isEmpty {
                    headersInput += "\nAuthorization: Bearer \(bearerToken)"
                    selectedTab = 0
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - Tab 4: Presets
    @ViewBuilder
    private func presetsTabView() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(manager.presets) { preset in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline.bold())
                            Text("\(preset.method)  \(preset.url)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Load") {
                            selectedMethod = preset.method
                            urlInput = preset.url
                            bodyInput = preset.body
                            selectedTab = 0
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                    }
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
    }
}
