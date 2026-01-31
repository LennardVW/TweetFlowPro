import SwiftUI
import SwiftData

// MARK: - Main App

@main
struct TweetFlowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Tweet.self, TweetThread.self, MediaItem.self, AnalyticsData.self])
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            switch selectedTab {
            case 0:
                ComposerView()
            case 1:
                ThreadPlannerView()
            case 2:
                SchedulerView()
            case 3:
                MediaLibraryView()
            case 4:
                AnalyticsView()
            case 5:
                IdeasView()
            default:
                ComposerView()
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        List(selection: $selectedTab) {
            Section("Create") {
                Label("Compose", systemImage: "square.and.pencil")
                    .tag(0)
                Label("Thread Planner", systemImage: "text.alignleft")
                    .tag(1)
                Label("Ideas", systemImage: "lightbulb.fill")
                    .tag(5)
            }
            
            Section("Manage") {
                Label("Scheduler", systemImage: "calendar.badge.clock")
                    .tag(2)
                Label("Media Library", systemImage: "photo.on.rectangle")
                    .tag(3)
            }
            
            Section("Analyze") {
                Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                    .tag(4)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("TweetFlow Pro")
    }
}

// MARK: - Composer View

struct ComposerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tweetText = ""
    @State private var selectedMedia: [MediaItem] = []
    @State private var showingMediaPicker = false
    @State private var showingScheduleSheet = false
    @State private var scheduledDate: Date?
    @State private var aiSuggestions: [String] = []
    @State private var isGeneratingSuggestions = false
    
    private let maxCharacters = 280
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Tweet Composer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // AI Assist Button
                Button(action: generateAISuggestions) {
                    Label("AI Assist", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .disabled(isGeneratingSuggestions)
                
                // Media Button
                Button(action: { showingMediaPicker = true }) {
                    Label("Media", systemImage: "photo")
                }
                .buttonStyle(.bordered)
                
                // Schedule Button
                Button(action: { showingScheduleSheet = true }) {
                    Label("Schedule", systemImage: "calendar")
                }
                .buttonStyle(.bordered)
                
                // Post Now Button
                Button(action: postTweet) {
                    Label("Post Now", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(tweetText.isEmpty || tweetText.count > maxCharacters)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // AI Suggestions
                    if !aiSuggestions.isEmpty {
                        AISuggestionsView(suggestions: aiSuggestions) { suggestion in
                            tweetText = suggestion
                            aiSuggestions.removeAll()
                        }
                    }
                    
                    // Text Editor
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $tweetText)
                            .font(.body)
                            .frame(minHeight: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        HStack {
                            // Character Count
                            Text("\(tweetText.count)/\(maxCharacters)")
                                .font(.caption)
                                .foregroundStyle(characterCountColor)
                            
                            Spacer()
                            
                            // Engagement Prediction
                            EngagementPredictionView(text: tweetText)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Media Preview
                    if !selectedMedia.isEmpty {
                        MediaPreviewGrid(media: selectedMedia) { item in
                            selectedMedia.removeAll { $0.id == item.id }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Hashtag Suggestions
                    HashtagSuggestionsView(text: tweetText) { hashtag in
                        if !tweetText.contains(hashtag) {
                            tweetText += " \(hashtag)"
                        }
                    }
                    .padding(.horizontal)
                    
                    // Best Time Suggestion
                    if scheduledDate == nil {
                        BestTimeSuggestionView { time in
                            scheduledDate = time
                            showingScheduleSheet = true
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showingScheduleSheet) {
            ScheduleSheet(date: $scheduledDate) { date in
                scheduleTweet(for: date)
            }
        }
    }
    
    private var characterCountColor: Color {
        if tweetText.count > maxCharacters {
            return .red
        } else if tweetText.count > maxCharacters - 20 {
            return .orange
        }
        return .secondary
    }
    
    private func generateAISuggestions() {
        isGeneratingSuggestions = true
        
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            aiSuggestions = [
                "Just shipped a new feature! 🚀 What do you think? #buildinpublic",
                "The best time to start was yesterday. The second best time is now. 💪",
                "Hot take: AI won't replace developers. Developers using AI will replace those who don't. 🤖"
            ]
            isGeneratingSuggestions = false
        }
    }
    
    private func postTweet() {
        let tweet = Tweet(
            content: tweetText,
            scheduledDate: nil,
            isPosted: true,
            postedDate: Date()
        )
        modelContext.insert(tweet)
        tweetText = ""
        selectedMedia.removeAll()
    }
    
    private func scheduleTweet(for date: Date) {
        let tweet = Tweet(
            content: tweetText,
            scheduledDate: date,
            isPosted: false
        )
        modelContext.insert(tweet)
        tweetText = ""
        selectedMedia.removeAll()
        scheduledDate = nil
    }
}

// MARK: - Thread Planner View

struct ThreadPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var threadTitle = ""
    @State private var tweets: [String] = [""]
    @State private var selectedHook: String = ""
    
    let hookTemplates = [
        "🧵 THREAD: The ultimate guide to...",
        "I spent 1000 hours learning [topic]. Here's what I discovered:",
        "Most people get [topic] wrong. Here's the truth:",
        "Story time: How I [achieved result] in [timeframe]",
        "The biggest myth about [topic] debunked 🧵"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Thread Planner")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: addTweet) {
                    Label("Add Tweet", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                
                Button(action: saveThread) {
                    Label("Save Thread", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                
                Button(action: scheduleThread) {
                    Label("Schedule Thread", systemImage: "calendar.badge.clock")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Thread Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thread Title")
                            .font(.headline)
                        TextField("Enter thread title", text: $threadTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    // Hook Templates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hook Templates")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(hookTemplates, id: \.self) { hook in
                                Button(action: { 
                                    selectedHook = hook
                                    if tweets.isEmpty {
                                        tweets.append(hook)
                                    } else {
                                        tweets[0] = hook
                                    }
                                }) {
                                    Text(hook)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedHook == hook ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .foregroundStyle(selectedHook == hook ? .blue : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tweets
                    VStack(spacing: 12) {
                        ForEach(tweets.indices, id: \.self) { index in
                            TweetCard(
                                index: index + 1,
                                text: $tweets[index],
                                onDelete: { deleteTweet(at: index) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Thread Preview
                    ThreadPreviewView(tweets: tweets)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
    
    private func addTweet() {
        tweets.append("")
    }
    
    private func deleteTweet(at index: Int) {
        guard tweets.count > 1 else { return }
        tweets.remove(at: index)
    }
    
    private func saveThread() {
        let thread = TweetThread(
            title: threadTitle,
            tweets: tweets
        )
        modelContext.insert(thread)
    }
    
    private func scheduleThread() {
        // Schedule each tweet with 30min intervals
        var currentDate = Date().addingTimeInterval(3600) // Start in 1 hour
        for tweetText in tweets {
            let tweet = Tweet(
                content: tweetText,
                scheduledDate: currentDate,
                isPosted: false,
                threadTitle: threadTitle
            )
            modelContext.insert(tweet)
            currentDate = currentDate.addingTimeInterval(1800) // 30 min intervals
        }
    }
}

// MARK: - Scheduler View

struct SchedulerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tweet.scheduledDate) private var scheduledTweets: [Tweet]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Content Scheduler")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { /* Auto-schedule best times */ }) {
                    Label("Auto-Schedule", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(scheduledTweets.filter { !$0.isPosted }) { tweet in
                        ScheduledTweetCard(tweet: tweet)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Ideas View

struct IdeasView: View {
    @State private var ideas: [TweetIdea] = [
        TweetIdea(title: "Personal Story", description: "Share a recent win or lesson learned", category: "Story"),
        TweetIdea(title: "Industry News", description: "Comment on latest trends in your field", category: "News"),
        TweetIdea(title: "Behind the Scenes", description: "Show your work process", category: "BTS"),
        TweetIdea(title: "Poll Question", description: "Ask your audience for opinions", category: "Engagement"),
        TweetIdea(title: "Resource Share", description: "Share useful tools or articles", category: "Value"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tweet Ideas")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: generateNewIdeas) {
                    Label("Generate Ideas", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                    ForEach(ideas) { idea in
                        IdeaCard(idea: idea)
                    }
                }
                .padding()
            }
        }
    }
    
    private func generateNewIdeas() {
        // Simulate AI idea generation
        let newIdeas = [
            TweetIdea(title: "Hot Take", description: "Share a controversial opinion in your industry", category: "Opinion"),
            TweetIdea(title: "Milestone Celebration", description: "Celebrate a recent achievement", category: "Celebration"),
            TweetIdea(title: "Quick Tip", description: "Share a bite-sized actionable advice", category: "Tips"),
        ]
        ideas.append(contentsOf: newIdeas)
    }
}

// MARK: - Media Library View

struct MediaLibraryView: View {
    @Query(sort: \MediaItem.createdAt, order: .reverse) private var media: [MediaItem]
    @State private var selectedMedia: MediaItem?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Media Library")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { /* Import media */ }) {
                    Label("Import", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(media) { item in
                        MediaThumbnail(item: item)
                            .onTapGesture {
                                selectedMedia = item
                            }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Analytics Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Time Range", selection: .constant(0)) {
                    Text("7 Days").tag(0)
                    Text("30 Days").tag(1)
                    Text("90 Days").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Key Metrics
                    HStack(spacing: 16) {
                        MetricCard(title: "Impressions", value: "12.4K", change: "+23%", color: .blue)
                        MetricCard(title: "Engagements", value: "1,234", change: "+15%", color: .green)
                        MetricCard(title: "Profile Visits", value: "456", change: "+8%", color: .purple)
                        MetricCard(title: "New Followers", value: "89", change: "+42%", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Best Performing Tweets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Performing Tweets")
                            .font(.headline)
                        
                        ForEach(0..<3, id: \.self) { _ in
                            TopTweetCard()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Best Times to Post
                    BestTimesChart()
                        .frame(height: 200)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
}

// MARK: - Models

@Model
class Tweet {
    @Attribute(.unique) var id: UUID
    var content: String
    var scheduledDate: Date?
    var isPosted: Bool
    var postedDate: Date?
    var threadTitle: String?
    var engagementCount: Int
    var impressionCount: Int
    
    init(content: String, scheduledDate: Date? = nil, isPosted: Bool = false, postedDate: Date? = nil, threadTitle: String? = nil) {
        self.id = UUID()
        self.content = content
        self.scheduledDate = scheduledDate
        self.isPosted = isPosted
        self.postedDate = postedDate
        self.threadTitle = threadTitle
        self.engagementCount = 0
        self.impressionCount = 0
    }
}

@Model
class TweetThread {
    @Attribute(.unique) var id: UUID
    var title: String
    var tweets: [String]
    var createdAt: Date
    
    init(title: String, tweets: [String]) {
        self.id = UUID()
        self.title = title
        self.tweets = tweets
        self.createdAt = Date()
    }
}

@Model
class MediaItem {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var fileType: String
    var createdAt: Date
    var tags: [String]
    
    init(fileName: String, fileType: String, tags: [String] = []) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.createdAt = Date()
        self.tags = tags
    }
}

@Model
class AnalyticsData {
    @Attribute(.unique) var id: UUID
    var date: Date
    var impressions: Int
    var engagements: Int
    var profileVisits: Int
    var newFollowers: Int
    
    init(date: Date, impressions: Int, engagements: Int, profileVisits: Int, newFollowers: Int) {
        self.id = UUID()
        self.date = date
        self.impressions = impressions
        self.engagements = engagements
        self.profileVisits = profileVisits
        self.newFollowers = newFollowers
    }
}

struct TweetIdea: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
}

// MARK: - Supporting Views

struct AISuggestionsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Suggestions", systemImage: "sparkles")
                .font(.headline)
            
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: { onSelect(suggestion) }) {
                    Text(suggestion)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EngagementPredictionView: View {
    let text: String
    
    var score: Double {
        // Simple algorithm based on factors
        var score: Double = 50 // Base score
        
        if text.count > 50 && text.count < 200 { score += 10 }
        if text.contains("?") { score += 5 }
        if text.contains("!") { score += 3 }
        if text.contains("#") { score += 5 }
        if text.lowercased().contains("thread") || text.contains("🧵") { score += 10 }
        
        return min(score, 100)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.bar")
            Text("Engagement Score: \(Int(score))%")
                .font(.caption)
        }
        .foregroundStyle(score > 70 ? .green : (score > 50 ? .orange : .red))
    }
}

struct HashtagSuggestionsView: View {
    let text: String
    let onSelect: (String) -> Void
    
    var suggestions: [String] {
        // AI-generated based on text content
        let baseTags = ["#buildinpublic", "#indiedev", "#startup", "#productivity", "#tech"]
        return baseTags.filter { !text.contains($0) }.prefix(3).map { $0 }
    }
    
    var body: some View {
        if !suggestions.isEmpty {
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { tag in
                    Button(action: { onSelect(tag) }) {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct BestTimeSuggestionView: View {
    let onSelect: (Date) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "clock.badge.checkmark")
                .foregroundStyle(.green)
            
            VStack(alignment: .leading) {
                Text("Best time to post: 9:00 AM")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Based on your audience activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Use This Time") {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                components.hour = 9
                components.minute = 0
                if let date = calendar.date(from: components) {
                    onSelect(date)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TweetCard: View {
    let index: Int
    @Binding var text: String
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tweet \(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(text.count)/280")
                    .font(.caption)
                    .foregroundStyle(text.count > 280 ? .red : .secondary)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ThreadPreviewView: View {
    let tweets: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview (\(tweets.count) tweets)")
                .font(.headline)
            
            ForEach(tweets.indices, id: \.self) { index in
                if !tweets[index].isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tweets[index])
                            .font(.subheadline)
                            .lineLimit(3)
                        
                        if index < tweets.count - 1 {
                            Text("⬇️ \(index + 1)/\(tweets.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScheduledTweetCard: View {
    let tweet: Tweet
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tweet.content)
                    .font(.subheadline)
                    .lineLimit(2)
                
                if let date = tweet.scheduledDate {
                    Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Menu {
                Button("Edit") { }
                Button("Post Now") { }
                Button("Delete", role: .destructive) { }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct IdeaCard: View {
    let idea: TweetIdea
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(idea.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            Text(idea.title)
                .font(.headline)
            
            Text(idea.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Spacer()
                
                Button("Create Tweet") {
                    // Create tweet from idea
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MediaThumbnail: View {
    let item: MediaItem
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: iconForType(item.fileType))
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                )
            
            Text(item.fileName)
                .font(.caption)
                .lineLimit(1)
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "image", "png", "jpg", "jpeg": return "photo"
        case "video", "mp4", "mov": return "video"
        case "gif": return "gif"
        default: return "doc"
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(change)
                .font(.caption)
                .foregroundStyle(change.contains("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TopTweetCard: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Just shipped a new feature! 🚀 What do you think?")
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack(spacing: 16) {
                    Label("1.2K", systemImage: "eye")
                    Label("89", systemImage: "heart")
                    Label("23", systemImage: "arrow.2.squarepath")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text("12.4%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                Text("engagement")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BestTimesChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Times to Post")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(["6AM", "9AM", "12PM", "3PM", "6PM", "9PM"], id: \.self) { time in
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(time == "9AM" ? Color.green : Color.blue.opacity(0.3))
                            .frame(width: 40, height: CGFloat.random(in: 30...100))
                        
                        Text(time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScheduleSheet: View {
    @Binding var date: Date?
    let onConfirm: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date().addingTimeInterval(3600)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Schedule Tweet")
                .font(.title2)
                .fontWeight(.bold)
            
            DatePicker("Date & Time", selection: $selectedDate)
                .datePickerStyle(.graphical)
            
            HStack {
                Button("Cancel") { dismiss() }
                
                Spacer()
                
                Button("Schedule") {
                    onConfirm(selectedDate)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
