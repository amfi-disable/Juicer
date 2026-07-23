import SwiftUI
import AppKit

struct apistudioview: View {
    @State private var httpMethod = "GET"
    @State private var urlString = "https://api.github.com/zen"
    @State private var requestHeaders = "User-Agent: Juicer-API-Studio/1.0"
    @State private var responseBody = ""
    @State private var statusCode = ""
    @State private var isExecuting = false
    @State private var benchmarkCount = "10"
    @State private var benchmarkResults = ""
    @State private var selectedTab = "Workbench"
    
    var body: some View {
        VStack(spacing: 0) {
            JuicerFeatureHeader(
                title: "Juicer API & HTTP Studio",
                subtitle: "Native REST request workbench, cURL importer, endpoint load benchmarker, and header inspector.",
                icon: "paperplane.fill",
                refreshing: isExecuting,
                action: { sendRequest() }
            )
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("REST Workbench").tag("Workbench")
                    Text("Load Benchmarker").tag("Benchmark")
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            if selectedTab == "Workbench" {
                workbenchView()
            } else {
                benchmarkView()
            }
        }
        .allowWindowDragAndFit()
    }
    
    @ViewBuilder
    private func workbenchView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("", selection: $httpMethod) {
                    Text("GET").tag("GET")
                    Text("POST").tag("POST")
                    Text("PUT").tag("PUT")
                    Text("DELETE").tag("DELETE")
                }
                .frame(width: 90)
                
                TextField("https://api.example.com/v1/resource", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send Request") { sendRequest() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExecuting || urlString.isEmpty)
            }
            
            if !statusCode.isEmpty {
                HStack {
                    Text("Status: \(statusCode)").bold()
                        .foregroundStyle(statusCode.contains("200") || statusCode.contains("201") ? Color.green : Color.orange)
                    Spacer()
                }
            }
            
            TextEditor(text: .constant(responseBody.isEmpty ? "Response body will appear here after sending request..." : responseBody))
                .font(.system(.body, design: .monospaced))
                .cornerRadius(8)
        }
        .padding()
    }
    
    @ViewBuilder
    private func benchmarkView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rapid Request Benchmarker").font(.headline)
                Spacer()
                TextField("Requests count", text: $benchmarkCount)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Button("Run Benchmark") { runBenchmark() }
                    .buttonStyle(.borderedProminent)
            }
            
            TextEditor(text: .constant(benchmarkResults.isEmpty ? "Benchmark latency and RPS statistics will appear here..." : benchmarkResults))
                .font(.system(.body, design: .monospaced))
                .cornerRadius(8)
        }
        .padding()
    }
    
    private func sendRequest() {
        guard let url = URL(string: urlString) else { return }
        isExecuting = true
        responseBody = "Sending request..."
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("Juicer-API-Studio/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isExecuting = false
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = "\(httpResponse.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                }
                if let data = data, let text = String(data: data, encoding: .utf8) {
                    responseBody = text
                } else if let error = error {
                    responseBody = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func runBenchmark() {
        guard let count = Int(benchmarkCount), count > 0 else { return }
        isExecuting = true
        benchmarkResults = "Running \(count) concurrent requests to \(urlString)..."
        
        let start = Date()
        let group = DispatchGroup()
        
        for _ in 0..<count {
            group.enter()
            if let url = URL(string: urlString) {
                var req = URLRequest(url: url)
                req.httpMethod = httpMethod
                URLSession.shared.dataTask(with: req) { _, _, _ in
                    group.leave()
                }.resume()
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let elapsed = Date().timeIntervalSince(start)
            let rps = Double(count) / elapsed
            isExecuting = false
            benchmarkResults = """
            Benchmark Completed!
            ---------------------------------------
            Target URL: \(urlString)
            Total Requests: \(count)
            Total Time: \(String(format: "%.3f", elapsed)) s
            Requests Per Second (RPS): \(String(format: "%.1f", rps)) req/s
            Avg Latency per Request: \(String(format: "%.1f", (elapsed / Double(count)) * 1000)) ms
            """
        }
    }
}
