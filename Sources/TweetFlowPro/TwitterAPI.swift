import Foundation

// MARK: - Twitter API Service

class TwitterAPIService {
    static let shared = TwitterAPIService()
    
    private let baseURL = "https://api.twitter.com/2"
    private var bearerToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    func authenticate(withBearerToken token: String) {
        self.bearerToken = token
        // Save to Keychain
        KeychainService.shared.save(token, forKey: "twitter_bearer_token")
    }
    
    func isAuthenticated() -> Bool {
        if bearerToken == nil {
            bearerToken = KeychainService.shared.load(forKey: "twitter_bearer_token")
        }
        return bearerToken != nil
    }
    
    func logout() {
        bearerToken = nil
        KeychainService.shared.delete(forKey: "twitter_bearer_token")
    }
    
    // MARK: - Post Tweet
    
    func postTweet(content: String, mediaIds: [String] = [], completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = bearerToken else {
            completion(.failure(TwitterAPIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "\(baseURL)/tweets")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["text": content]
        if !mediaIds.isEmpty {
            body["media"] = ["media_ids": mediaIds]
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(TwitterAPIError.noData))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let id = data["id"] as? String {
                    DispatchQueue.main.async {
                        completion(.success(id))
                    }
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let errors = json["errors"] as? [[String: Any]],
                          let firstError = errors.first,
                          let message = firstError["message"] as? String {
                    DispatchQueue.main.async {
                        completion(.failure(TwitterAPIError.apiError(message: message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(TwitterAPIError.unknown))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Upload Media
    
    func uploadMedia(data: Data, filename: String, mimeType: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = bearerToken else {
            completion(.failure(TwitterAPIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "https://upload.twitter.com/1.1/media/upload.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"media\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let mediaId = json["media_id_string"] as? String else {
                DispatchQueue.main.async {
                    completion(.failure(TwitterAPIError.mediaUploadFailed))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(mediaId))
            }
        }.resume()
    }
    
    // MARK: - Get User Info
    
    func getUserInfo(completion: @escaping (Result<TwitterUser, Error>) -> Void) {
        guard let token = bearerToken else {
            completion(.failure(TwitterAPIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(TwitterAPIError.noData))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TwitterUserResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.data))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Get Metrics
    
    func getTweetMetrics(tweetId: String, completion: @escaping (Result<TweetMetrics, Error>) -> Void) {
        guard let token = bearerToken else {
            completion(.failure(TwitterAPIError.notAuthenticated))
            return
        }
        
        let url = URL(string: "\(baseURL)/tweets/\(tweetId)?tweet.fields=public_metrics")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(TwitterAPIError.noData))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TweetMetricsResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.data.public_metrics))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// MARK: - Keychain Service

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Models

struct TwitterUser: Codable {
    let id: String
    let name: String
    let username: String
    let profile_image_url: String?
    let public_metrics: UserPublicMetrics?
}

struct UserPublicMetrics: Codable {
    let followers_count: Int
    let following_count: Int
    let tweet_count: Int
    let listed_count: Int
}

struct TwitterUserResponse: Codable {
    let data: TwitterUser
}

struct TweetMetrics: Codable {
    let retweet_count: Int
    let reply_count: Int
    let like_count: Int
    let quote_count: Int
    let impression_count: Int
}

struct TweetMetricsResponse: Codable {
    struct Data: Codable {
        let public_metrics: TweetMetrics
    }
    let data: Data
}

// MARK: - Errors

enum TwitterAPIError: Error, LocalizedError {
    case notAuthenticated
    case noData
    case apiError(message: String)
    case mediaUploadFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Twitter"
        case .noData:
            return "No data received from API"
        case .apiError(let message):
            return "Twitter API Error: \(message)"
        case .mediaUploadFailed:
            return "Failed to upload media"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Auto Poster Service

class AutoPosterService: ObservableObject {
    static let shared = AutoPosterService()
    
    @Published var isRunning = false
    @Published var nextPostTime: Date?
    
    private var timer: Timer?
    private let queue = DispatchQueue(label: "autoposter")
    
    private init() {}
    
    func startAutoPosting(context: ModelContext) {
        isRunning = true
        
        // Check every minute for scheduled tweets
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.checkAndPostScheduledTweets(context: context)
        }
        
        // Immediate check
        checkAndPostScheduledTweets(context: context)
    }
    
    func stopAutoPosting() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        nextPostTime = nil
    }
    
    private func checkAndPostScheduledTweets(context: ModelContext) {
        guard TwitterAPIService.shared.isAuthenticated() else { return }
        
        let descriptor = FetchDescriptor<Tweet>(
            predicate: #Predicate { tweet in
                tweet.scheduledDate != nil &&
                tweet.isPosted == false &&
                tweet.scheduledDate! <= Date()
            }
        )
        
        do {
            let tweetsToPost = try context.fetch(descriptor)
            
            for tweet in tweetsToPost {
                postTweet(tweet, context: context)
            }
            
            // Update next post time
            let nextDescriptor = FetchDescriptor<Tweet>(
                predicate: #Predicate { tweet in
                    tweet.scheduledDate != nil &&
                    tweet.isPosted == false
                },
                sortBy: [SortDescriptor(\.scheduledDate)]
            )
            
            if let nextTweet = try context.fetch(nextDescriptor).first {
                DispatchQueue.main.async {
                    self.nextPostTime = nextTweet.scheduledDate
                }
            }
        } catch {
            Logger.shared.error("Failed to fetch scheduled tweets", error: error)
        }
    }
    
    private func postTweet(_ tweet: Tweet, context: ModelContext) {
        TwitterAPIService.shared.postTweet(content: tweet.content) { result in
            switch result {
            case .success(let tweetId):
                tweet.isPosted = true
                tweet.postedDate = Date()
                tweet.twitterId = tweetId
                
                try? context.save()
                
                Logger.shared.info("Auto-posted tweet: \(tweetId)")
                
                // Post notification
                NotificationManager.shared.sendNotification(
                    title: "Tweet Posted!",
                    body: "Your scheduled tweet has been published."
                )
                
            case .failure(let error):
                Logger.shared.error("Failed to auto-post tweet", error: error)
            }
        }
    }
}
