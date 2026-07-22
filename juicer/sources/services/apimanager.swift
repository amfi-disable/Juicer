import Foundation
import Combine

struct APIRequestPreset: Identifiable {
    let id = UUID()
    let name: String
    let method: String
    let url: String
    let body: String
}

struct APIResponseResult {
    let statusCode: Int
    let latencyMs: Double
    let sizeBytes: Int64
    let body: String
    let headers: [String: String]
}

final class APIManager: ObservableObject {
    static let shared = APIManager()
    
    @Published var presets: [APIRequestPreset] = [
        APIRequestPreset(name: "Localhost Health Check", method: "GET", url: "http://localhost:3000/health", body: ""),
        APIRequestPreset(name: "GitHub API Rate Limit", method: "GET", url: "https://api.github.com/rate_limit", body: ""),
        APIRequestPreset(name: "Ollama Models Tags", method: "GET", url: "http://localhost:11434/api/tags", body: "")
    ]
    
    @Published var isExecuting = false
    @Published var lastResponse: APIResponseResult? = nil
    
    private init() {}
    
    func executeRequest(method: String, urlString: String, headersText: String, bodyText: String) {
        guard let url = URL(string: urlString) else { return }
        isExecuting = true
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10.0
        
        // Headers parsing
        let lines = headersText.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if !bodyText.isEmpty && (method == "POST" || method == "PUT" || method == "PATCH") {
            request.httpBody = bodyText.data(using: .utf8)
        }
        
        let startTime = Date()
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let elapsed = Date().timeIntervalSince(startTime) * 1000.0
            
            DispatchQueue.main.async {
                self?.isExecuting = false
                
                let httpResp = response as? HTTPURLResponse
                let statusCode = httpResp?.statusCode ?? (error == nil ? 200 : 500)
                let responseData = data ?? Data()
                let responseText = String(data: responseData, encoding: .utf8) ?? "Binary or unparseable data."
                
                var respHeaders: [String: String] = [:]
                if let rawHeaders = httpResp?.allHeaderFields {
                    for (k, v) in rawHeaders {
                        respHeaders["\(k)"] = "\(v)"
                    }
                }
                
                self?.lastResponse = APIResponseResult(
                    statusCode: statusCode,
                    latencyMs: elapsed,
                    sizeBytes: Int64(responseData.count),
                    body: responseText,
                    headers: respHeaders
                )
            }
        }.resume()
    }
}
