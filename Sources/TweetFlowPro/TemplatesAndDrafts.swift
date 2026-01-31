import SwiftUI
import SwiftData

// MARK: - Drafts Manager

class DraftsManager: ObservableObject {
    static let shared = DraftsManager()
    
    @Published var quickDrafts: [QuickDraft] = []
    
    private init() {
        loadQuickDrafts()
    }
    
    func saveQuickDraft(content: String) {
        let draft = QuickDraft(content: content, createdAt: Date())
        quickDrafts.insert(draft, at: 0)
        
        // Keep only last 10 quick drafts
        if quickDrafts.count > 10 {
            quickDrafts = Array(quickDrafts.prefix(10))
        }
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(quickDrafts) {
            UserDefaults.standard.set(data, forKey: "quick_drafts")
        }
    }
    
    func deleteQuickDraft(at index: Int) {
        quickDrafts.remove(at: index)
        if let data = try? JSONEncoder().encode(quickDrafts) {
            UserDefaults.standard.set(data, forKey: "quick_drafts")
        }
    }
    
    private func loadQuickDrafts() {
        guard let data = UserDefaults.standard.data(forKey: "quick_drafts"),
              let drafts = try? JSONDecoder().decode([QuickDraft].self, from: data) else {
            return
        }
        quickDrafts = drafts
    }
}

struct QuickDraft: Codable, Identifiable {
    let id: UUID
    var content: String
    let createdAt: Date
    
    init(content: String, createdAt: Date) {
        self.id = UUID()
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Templates Manager

class TemplatesManager: ObservableObject {
    static let shared = TemplatesManager()
    
    @Published var templates: [TweetTemplate] = []
    @Published var categories: [TemplateCategory] = []
    
    private init() {
        loadDefaultTemplates()
    }
    
    private func loadDefaultTemplates() {
        categories = [
            TemplateCategory(name: "All", icon: "square.grid.2x2"),
            TemplateCategory(name: "Engagement", icon: "bubble.left.and.bubble.right"),
            TemplateCategory(name: "Value", icon: "lightbulb"),
            TemplateCategory(name: "Story", icon: "book"),
            TemplateCategory(name: "Promo", icon: "megaphone"),
        ]
        
        templates = [
            // Engagement Templates
            TweetTemplate(
                title: "Question Hook",
                content: "What's one thing you wish you knew about [TOPIC] 5 years ago?\n\nI'll start:",
                category: "Engagement",
                engagementScore: 85
            ),
            TweetTemplate(
                title: "Hot Take",
                content: "Hot take: [CONTROVERSIAL_OPINION]\n\nHere's why:\n\n1.\n2.\n3.\n\nAgree or disagree?",
                category: "Engagement",
                engagementScore: 90
            ),
            TweetTemplate(
                title: "Poll Alternative",
                content: "Quick poll:\n\nOption A: [CHOICE_A]\nOption B: [CHOICE_B]\n\nWhich one are you? 👇",
                category: "Engagement",
                engagementScore: 80
            ),
            
            // Value Templates
            TweetTemplate(
                title: "Thread Starter",
                content: "I spent [TIME] learning [SKILL].\n\nHere are 5 lessons that will save you months:\n\n🧵",
                category: "Value",
                engagementScore: 95
            ),
            TweetTemplate(
                title: "Resource Share",
                content: "I just found the best [RESOURCE_TYPE] for [TOPIC].\n\nHere it is:\n\n[LINK]\n\nKey takeaways:\n• \n• \n• ",
                category: "Value",
                engagementScore: 75
            ),
            TweetTemplate(
                title: "Quick Tip",
                content: "💡 Quick [TOPIC] tip:\n\n[ADVICE]\n\nMost people get this wrong. Don't be most people.",
                category: "Value",
                engagementScore: 70
            ),
            
            // Story Templates
            TweetTemplate(
                title: "Journey Update",
                content: "Day [NUMBER] of building [PROJECT]:\n\n✅ What went well:\n\n❌ What didn't:\n\n🎯 Next:",
                category: "Story",
                engagementScore: 85
            ),
            TweetTemplate(
                title: "Failure Story",
                content: "I failed at [GOAL].\n\nHere's what happened:\n\n[STORY]\n\nThe lesson? [LESSON]",
                category: "Story",
                engagementScore: 88
            ),
            TweetTemplate(
                title: "Behind the Scenes",
                content: "Behind the scenes of [PROJECT]:\n\nMost people think [MYTH].\n\nThe reality:\n\n[TRUTH]",
                category: "Story",
                engagementScore: 82
            ),
            
            // Promo Templates
            TweetTemplate(
                title: "Soft Launch",
                content: "I've been working on something...\n\n[PROJECT_NAME] is coming soon.\n\nHere's what it does:\n\n[BENEFIT]\n\nWant early access? Reply 👇",
                category: "Promo",
                engagementScore: 78
            ),
            TweetTemplate(
                title: "Results Share",
                content: "[TIMEFRAME] ago, I started [ACTION].\n\nThe results:\n\n📊 [METRIC_1]\n📈 [METRIC_2]\n🎯 [METRIC_3]\n\nWant to know how? [CTA]",
                category: "Promo",
                engagementScore: 85
            ),
            TweetTemplate(
                title: "Limited Offer",
                content: "🚨 48 hours only:\n\n[OFFER_DETAILS]\n\nWhy now?\n• [REASON_1]\n• [REASON_2]\n\nLink in bio 👆",
                category: "Promo",
                engagementScore: 72
            ),
        ]
    }
    
    func addCustomTemplate(_ template: TweetTemplate) {
        templates.append(template)
        saveCustomTemplates()
    }
    
    func deleteTemplate(_ template: TweetTemplate) {
        templates.removeAll { $0.id == template.id }
        saveCustomTemplates()
    }
    
    private func saveCustomTemplates() {
        // Save custom templates to UserDefaults or CoreData
        // For now, just keeping in memory
    }
    
    func templates(for category: String) -> [TweetTemplate] {
        if category == "All" {
            return templates.sorted { $0.engagementScore > $1.engagementScore }
        }
        return templates.filter { $0.category == category }
            .sorted { $0.engagementScore > $1.engagementScore }
    }
    
    func searchTemplates(query: String) -> [TweetTemplate] {
        templates.filter {
            $0.title.lowercased().contains(query.lowercased()) ||
            $0.content.lowercased().contains(query.lowercased())
        }
    }
}

// MARK: - Models

struct TemplateCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

struct TweetTemplate: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let category: String
    let engagementScore: Int
    var isCustom: Bool = false
    
    func filled(with values: [String: String]) -> String {
        var result = content
        for (key, value) in values {
            result = result.replacingOccurrences(of: "[\(key)]", with: value)
        }
        return result
    }
    
    var placeholders: [String] {
        let pattern = #"\[([^\]]+)\]"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
        
        return matches?.compactMap { match in
            if let range = Range(match.range(at: 1), in: content) {
                return String(content[range])
            }
            return nil
        } ?? []
    }
}

// MARK: - Templates View

struct TemplatesView: View {
    @StateObject private var manager = TemplatesManager.shared
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var selectedTemplate: TweetTemplate?
    @State private var showingFillSheet = false
    
    var filteredTemplates: [TweetTemplate] {
        if searchText.isEmpty {
            return manager.templates(for: selectedCategory)
        }
        return manager.searchTemplates(query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Templates")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("\(filteredTemplates.reduce(0) { $0 + $1.engagementScore } / max(filteredTemplates.count, 1)) avg score")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search templates...", text: $searchText)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(manager.categories) { category in
                        Button(action: { selectedCategory = category.name }) {
                            Label(category.name, systemImage: category.icon)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category.name ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundStyle(selectedCategory == category.name ? .blue : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Templates Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(template: template) {
                            selectedTemplate = template
                            showingFillSheet = true
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateFillSheet(template: template)
        }
    }
}

struct TemplateCard: View {
    let template: TweetTemplate
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(template.title)
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("\(template.engagementScore)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Text(template.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
            
            HStack {
                Text(template.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                
                Spacer()
                
                if !template.placeholders.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "text.badge.checkmark")
                        Text("\(template.placeholders.count) fields")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Button("Use Template") {
                    onUse()
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

struct TemplateFillSheet: View {
    let template: TweetTemplate
    @Environment(\.dismiss) private var dismiss
    @State private var fieldValues: [String: String] = [:]
    @State private var previewText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Fill in the blanks") {
                    ForEach(template.placeholders, id: \.self) { placeholder in
                        HStack {
                            Text(placeholder)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 120, alignment: .leading)
                            
                            TextField("Enter \(placeholder.lowercased())", text: binding(for: placeholder))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                
                Section("Preview") {
                    Text(previewText)
                        .font(.body)
                        .padding(.vertical, 8)
                }
                
                Section {
                    HStack {
                        Text("\(previewText.count)/280")
                            .font(.caption)
                            .foregroundStyle(previewText.count > 280 ? .red : .secondary)
                        
                        Spacer()
                        
                        Button("Copy to Composer") {
                            // Copy to clipboard or composer
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(template.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: fieldValues) { _, _ in
                updatePreview()
            }
            .onAppear {
                updatePreview()
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { fieldValues[key] ?? "" },
            set: { fieldValues[key] = $0 }
        )
    }
    
    private func updatePreview() {
        previewText = template.filled(with: fieldValues)
    }
}

// MARK: - Quick Drafts View

struct QuickDraftsView: View {
    @StateObject private var manager = DraftsManager.shared
    @State private var selectedDraft: QuickDraft?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Quick Drafts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(manager.quickDrafts.count) saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            if manager.quickDrafts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No quick drafts yet")
                        .foregroundStyle(.secondary)
                    
                    Text("Start typing in the composer and save drafts for later")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(manager.quickDrafts) { draft in
                        DraftRow(draft: draft)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDraft = draft
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            manager.deleteQuickDraft(at: index)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct DraftRow: View {
    let draft: QuickDraft
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(draft.content)
                .font(.subheadline)
                .lineLimit(2)
            
            Text(draft.createdAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
