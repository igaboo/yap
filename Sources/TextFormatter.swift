import Foundation

enum FormattingStyle: String, CaseIterable {
    case casual = "casual"
    case formatted = "formatted"
    case professional = "professional"
    
    var label: String {
        switch self {
        case .casual: return "Casual"
        case .formatted: return "Formatted"
        case .professional: return "Professional"
        }
    }
    
    var description: String {
        switch self {
        case .casual: return "Light cleanup, keeps your voice"
        case .formatted: return "Clean formatting, faithful to what you said"
        case .professional: return "Polished writing, elevated language"
        }
    }
    
    static let exampleInput = "um so like i was thinking we should probably you know move the meeting to friday because uh thursdays not gonna work for me"
    
    var exampleOutput: String {
        switch self {
        case .casual:
            return "so like i was thinking we should probably move the meeting to friday because thursdays not gonna work for me"
        case .formatted:
            return "So I was thinking we should probably move the meeting to Friday, because Thursday's not going to work for me."
        case .professional:
            return "I believe we should reschedule the meeting to Friday, as Thursday will not work for my schedule."
        }
    }
    
    var prompt: String {
        switch self {
        case .casual:
            return """
            You clean up spoken text. You MUST respond with ONLY a JSON object: {"text":"cleaned version here"} \
            Rules: remove ONLY filler sounds (um, uh, er). Keep everything else exactly as spoken — \
            casual phrases, slang, sentence structure, contractions. All lowercase. Minimal punctuation. \
            PRESERVE all existing symbols — parentheses, quotes, brackets, etc. \
            NEVER respond conversationally. ONLY output the JSON object.
            """
        case .formatted:
            return """
            You clean up spoken text. You MUST respond with ONLY a JSON object: {"text":"cleaned version here"} \
            Rules: remove filler words (um, uh, er, like, you know). Fix punctuation and capitalization. \
            Keep the speaker's EXACT words and sentence structure — do not rephrase or rewrite. \
            Keep contractions as spoken. Only fix obvious grammar errors. \
            PRESERVE all existing symbols — parentheses, quotes, brackets, etc. \
            NEVER respond conversationally. ONLY output the JSON object.
            """
        case .professional:
            return """
            You clean up spoken text. You MUST respond with ONLY a JSON object: {"text":"cleaned version here"} \
            Rules: remove all filler words. Elevate the language to sound polished and professional. \
            Fix grammar, improve word choice, use proper punctuation and capitalization. \
            Expand contractions. You MAY rephrase for clarity and professionalism, but keep the original meaning. \
            PRESERVE all existing symbols — parentheses, quotes, brackets, etc. \
            NEVER respond conversationally. ONLY output the JSON object.
            """
        }
    }
    
    /// Prompt for multimodal audio transcription (Gemini/OpenAI — transcribe + format in one step)
    var audioPrompt: String {
        let noiseRule = "IGNORE all background noise, sound effects, music, and non-speech sounds. " +
            "Only transcribe human speech. If there is no speech, respond with {\"text\":\"\"}."
        
        switch self {
        case .casual:
            return """
            Transcribe this audio. Remove filler sounds (um, uh, er) but keep everything else exactly as spoken — \
            casual phrases, slang, sentence structure, contractions. All lowercase. Minimal punctuation. \
            PRESERVE any symbols the speaker mentions — parentheses, quotes, brackets, etc. \
            \(noiseRule) \
            You MUST respond with ONLY a JSON object: {"text":"transcription here"}
            """
        case .formatted:
            return """
            Transcribe this audio. Remove filler words (um, uh, er, like, you know). \
            Fix punctuation and capitalization. Keep the speaker's EXACT words and sentence structure — \
            do not rephrase or rewrite. Keep contractions as spoken. Only fix obvious grammar errors. \
            PRESERVE any symbols the speaker mentions — parentheses, quotes, brackets, etc. \
            \(noiseRule) \
            You MUST respond with ONLY a JSON object: {"text":"transcription here"}
            """
        case .professional:
            return """
            Transcribe this audio. Remove all filler words. Elevate the language to sound polished and professional. \
            Fix grammar, improve word choice, use proper punctuation and capitalization. \
            Expand contractions. You MAY rephrase for clarity and professionalism, but keep the original meaning. \
            PRESERVE any symbols the speaker mentions — parentheses, quotes, brackets, etc. \
            \(noiseRule) \
            You MUST respond with ONLY a JSON object: {"text":"transcription here"}
            """
        }
    }
}

enum APIProvider: String, CaseIterable {
    case none = "none"
    case gemini = "gemini"
    case openai = "openai"
    case deepgram = "deepgram"
    case elevenlabs = "elevenlabs"
    case anthropic = "anthropic"
    
    var label: String {
        switch self {
        case .none: return "None (Apple Dictation)"
        case .gemini: return "Google Gemini"
        case .openai: return "OpenAI"
        case .deepgram: return "Deepgram"
        case .elevenlabs: return "ElevenLabs"
        case .anthropic: return "Anthropic"
        }
    }
    
    var defaultModel: String {
        switch self {
        case .none: return ""
        case .gemini: return "gemini-2.5-flash"
        case .openai: return "gpt-4o-transcribe"
        case .deepgram: return "nova-3"
        case .elevenlabs: return "scribe_v1"
        case .anthropic: return "claude-haiku-4-5-20251001"
        }
    }
    
    var defaultEndpoint: String {
        switch self {
        case .none: return ""
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .openai: return "https://api.openai.com/v1"
        case .deepgram: return "https://api.deepgram.com/v1"
        case .elevenlabs: return "https://api.elevenlabs.io/v1"
        case .anthropic: return "https://api.anthropic.com/v1/messages"
        }
    }
    
    /// Whether this provider handles transcription (skips Apple Speech)
    var handlesTranscription: Bool {
        switch self {
        case .none, .anthropic: return false
        default: return true
        }
    }
    
    /// Whether this provider can also format text (it's an LLM)
    var canFormat: Bool {
        switch self {
        case .gemini, .openai, .anthropic: return true
        default: return false
        }
    }
}

// MARK: - TextFormatter

class TextFormatter {
    let provider: APIProvider
    private let apiKey: String
    private let model: String
    private let endpoint: String
    private let style: FormattingStyle
    
    init(provider: APIProvider, apiKey: String, model: String? = nil, endpoint: String? = nil, style: FormattingStyle) {
        self.provider = provider
        self.apiKey = apiKey
        self.model = model ?? provider.defaultModel
        self.endpoint = endpoint ?? provider.defaultEndpoint
        self.style = style
    }
    
    var handlesTranscription: Bool {
        return provider.handlesTranscription && !apiKey.isEmpty
    }
    
    /// Main entry point: process audio file → formatted text
    /// Handles transcription + formatting based on provider capabilities
    func processAudio(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        log("processAudio() — provider=\(provider.rawValue) style=\(style.rawValue)")
        
        switch provider {
        case .gemini:
            callGeminiAudio(audioURL: audioURL, completion: completion)
        case .openai:
            callOpenAITranscribe(audioURL: audioURL) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let text):
                    // OpenAI transcription done — now format with chat API
                    self.callOpenAIFormat(text: text, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .deepgram:
            callDeepgram(audioURL: audioURL, completion: completion)
        case .elevenlabs:
            callElevenLabs(audioURL: audioURL, completion: completion)
        default:
            completion(.failure(FormatterError.unsupportedProvider))
        }
    }
    
    /// Format already-transcribed text (Anthropic, or Apple Speech → format flow)
    func format(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.success(text))
            return
        }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            completion(.success(text))
            return
        }
        
        switch provider {
        case .openai:
            callOpenAIFormat(text: text, completion: completion)
        case .anthropic:
            callAnthropic(text: text, completion: completion)
        default:
            completion(.success(text))
        }
    }
    
    // MARK: - Gemini (audio → formatted text, one-shot)
    
    private func callGeminiAudio(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(FormatterError.audioReadFailed))
            return
        }
        
        let base64Audio = audioData.base64EncodedString()
        let urlString = "\(endpoint)/models/\(model):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(FormatterError.invalidEndpoint))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inline_data": ["mime_type": "audio/wav", "data": base64Audio]],
                    ["text": style.audioPrompt]
                ]
            ]],
            "generationConfig": ["temperature": 0.0, "maxOutputTokens": 2048]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        log("Gemini: \(model), audio=\(audioData.count) bytes")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("Gemini error: \(error)")
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse { log("Gemini status: \(http.statusCode)") }
            guard let data = data else {
                completion(.failure(FormatterError.noResponse))
                return
            }
            
            let raw = String(data: data, encoding: .utf8) ?? ""
            log("Gemini response: \(raw.prefix(300))")
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let err = json["error"] as? [String: Any],
                   let msg = err["message"] as? String {
                    completion(.failure(FormatterError.apiError(msg)))
                } else {
                    completion(.failure(FormatterError.parseFailed))
                }
                return
            }
            
            completion(.success(Self.extractJSON(from: text)))
        }.resume()
    }
    
    // MARK: - OpenAI Transcribe (audio → text)
    
    private func callOpenAITranscribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(FormatterError.audioReadFailed))
            return
        }
        
        guard let url = URL(string: "\(endpoint)/audio/transcriptions") else {
            completion(.failure(FormatterError.invalidEndpoint))
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // file field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        // model field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("\(model)\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        log("OpenAI transcribe: \(model), audio=\(audioData.count) bytes")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("OpenAI transcribe error: \(error)")
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse { log("OpenAI transcribe status: \(http.statusCode)") }
            guard let data = data else {
                completion(.failure(FormatterError.noResponse))
                return
            }
            
            let raw = String(data: data, encoding: .utf8) ?? ""
            log("OpenAI transcribe response: \(raw.prefix(300))")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                completion(.success(text))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let err = json["error"] as? [String: Any],
                      let msg = err["message"] as? String {
                completion(.failure(FormatterError.apiError(msg)))
            } else {
                completion(.failure(FormatterError.parseFailed))
            }
        }.resume()
    }
    
    // MARK: - OpenAI Format (text → formatted text via chat)
    
    private func callOpenAIFormat(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            completion(.failure(FormatterError.invalidEndpoint))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": style.prompt],
                ["role": "user", "content": "<input>\(text)</input>"]
            ],
            "max_tokens": 2048,
            "temperature": 0.3
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("OpenAI format error: \(error)")
                // Fall back to raw transcription
                completion(.success(text))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(.success(text))
                return
            }
            completion(.success(Self.extractJSON(from: content)))
        }.resume()
    }
    
    // MARK: - Deepgram (audio → text)
    
    private func callDeepgram(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(FormatterError.audioReadFailed))
            return
        }
        
        let params = "model=\(model)&smart_format=true&punctuate=true"
        guard let url = URL(string: "\(endpoint)/listen?\(params)") else {
            completion(.failure(FormatterError.invalidEndpoint))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData
        
        log("Deepgram: \(model), audio=\(audioData.count) bytes")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("Deepgram error: \(error)")
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse { log("Deepgram status: \(http.statusCode)") }
            guard let data = data else {
                completion(.failure(FormatterError.noResponse))
                return
            }
            
            let raw = String(data: data, encoding: .utf8) ?? ""
            log("Deepgram response: \(raw.prefix(300))")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [String: Any],
               let channels = results["channels"] as? [[String: Any]],
               let alternatives = channels.first?["alternatives"] as? [[String: Any]],
               let transcript = alternatives.first?["transcript"] as? String {
                completion(.success(transcript))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let msg = json["err_msg"] as? String {
                completion(.failure(FormatterError.apiError(msg)))
            } else {
                completion(.failure(FormatterError.parseFailed))
            }
        }.resume()
    }
    
    // MARK: - ElevenLabs (audio → text)
    
    private func callElevenLabs(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(FormatterError.audioReadFailed))
            return
        }
        
        guard let url = URL(string: "\(endpoint)/speech-to-text") else {
            completion(.failure(FormatterError.invalidEndpoint))
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // file field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        // model_id field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model_id\"\r\n\r\n")
        body.append("\(model)\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        log("ElevenLabs: \(model), audio=\(audioData.count) bytes")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("ElevenLabs error: \(error)")
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse { log("ElevenLabs status: \(http.statusCode)") }
            guard let data = data else {
                completion(.failure(FormatterError.noResponse))
                return
            }
            
            let raw = String(data: data, encoding: .utf8) ?? ""
            log("ElevenLabs response: \(raw.prefix(300))")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                completion(.success(text))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let detail = json["detail"] as? [String: Any],
                      let msg = detail["message"] as? String {
                completion(.failure(FormatterError.apiError(msg)))
            } else {
                completion(.failure(FormatterError.parseFailed))
            }
        }.resume()
    }
    
    // MARK: - Anthropic (text → formatted text)
    
    private func callAnthropic(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(FormatterError.invalidEndpoint))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "system": style.prompt,
            "messages": [
                ["role": "user", "content": "<input>\(text)</input>"],
                ["role": "assistant", "content": "{"]
            ],
            "max_tokens": 2048,
            "temperature": 0.0,
            "stop_sequences": ["}"]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("Anthropic error: \(error)")
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let textBlock = content.first?["text"] as? String else {
                completion(.success(text))
                return
            }
            let fullJSON = "{\(textBlock)}"
            if let innerData = fullJSON.data(using: .utf8),
               let innerJSON = try? JSONSerialization.jsonObject(with: innerData) as? [String: String],
               let cleaned = innerJSON["text"], !cleaned.isEmpty {
                completion(.success(cleaned))
            } else {
                completion(.success(textBlock.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }.resume()
    }
    
    // MARK: - Helpers
    
    /// Extract text from JSON response, handling code fences and plain text fallback
    static func extractJSON(from responseText: String) -> String {
        var s = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strip markdown code fences
        if s.hasPrefix("```json") { s = String(s.dropFirst(7)) }
        else if s.hasPrefix("```") { s = String(s.dropFirst(3)) }
        if s.hasSuffix("```") { s = String(s.dropLast(3)) }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try JSON parse
        if let data = s.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let text = parsed["text"], !text.isEmpty {
            return text
        }
        
        // Fallback: raw text
        return s
    }
}

// MARK: - Data extension for multipart

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Errors

enum FormatterError: LocalizedError {
    case invalidEndpoint
    case unsupportedProvider
    case audioReadFailed
    case noResponse
    case parseFailed
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "Invalid API endpoint URL"
        case .unsupportedProvider: return "Provider does not support this operation"
        case .audioReadFailed: return "Failed to read audio file"
        case .noResponse: return "No response from API"
        case .parseFailed: return "Failed to parse API response"
        case .apiError(let msg): return "API error: \(msg)"
        }
    }
}
