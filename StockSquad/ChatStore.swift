import Foundation
import Combine
import Supabase

// The live data behind Squad Chat (Phase 3, slice 1).
//
// Responsibilities:
//   • sign the device in (anonymously) so it has an identity
//   • load the existing chat history
//   • subscribe to realtime INSERTs so new messages stream in instantly
//   • send new messages
//
// The view just observes `messages` and `phase` — it doesn't know or care that
// Supabase is underneath. Phase 4 / future work swaps the source, not the UI.

@MainActor
final class ChatStore: ObservableObject {
    enum Phase: Equatable {
        case connecting
        case ready
        case failed(String)
    }

    @Published var messages: [ChatMessage] = []
    @Published var phase: Phase = .connecting

    /// The name + emoji stamped on the messages you send. Saved on-device.
    @Published var displayName: String
    @Published var avatar: String
    /// True if the user has picked a name before (so we only prompt on first run).
    let hasSavedIdentity: Bool

    private let client = SupabaseManager.client
    private var channel: RealtimeChannelV2?
    private var listenTask: Task<Void, Never>?

    private let nameKey = "chatDisplayName"
    private let avatarKey = "chatAvatar"

    init(defaultName: String, defaultAvatar: String) {
        let savedName = UserDefaults.standard.string(forKey: nameKey)
        hasSavedIdentity = savedName != nil
        displayName = savedName ?? defaultName
        avatar = UserDefaults.standard.string(forKey: avatarKey) ?? defaultAvatar
    }

    // MARK: - Identity

    func saveIdentity(name: String, avatar: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { displayName = trimmed }
        self.avatar = avatar
        UserDefaults.standard.set(displayName, forKey: nameKey)
        UserDefaults.standard.set(self.avatar, forKey: avatarKey)
    }

    // MARK: - Lifecycle

    func start() async {
        if phase == .ready { return }
        phase = .connecting
        do {
            try await SupabaseManager.signInIfNeeded()
            try await loadHistory()
            await subscribe()
            phase = .ready
        } catch {
            phase = .failed((error as NSError).localizedDescription)
        }
    }

    func stop() {
        listenTask?.cancel()
        listenTask = nil
        let openChannel = channel
        channel = nil
        phase = .connecting
        Task { await openChannel?.unsubscribe() }
    }

    // MARK: - Send

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let userId = client.auth.currentUser?.id else { return }

        let draft = NewMessage(sender_id: userId,
                               sender_name: displayName,
                               sender_avatar: avatar,
                               content: trimmed)
        do {
            // Insert and read the saved row back so we can show it instantly.
            // The realtime echo of the same row is de-duplicated by id below.
            let saved: MessageRecord = try await client
                .from("messages")
                .insert(draft)
                .select()
                .single()
                .execute()
                .value
            appendIfNew(saved.asChatMessage)
        } catch {
            phase = .failed((error as NSError).localizedDescription)
        }
    }

    // MARK: - Load + subscribe

    private func loadHistory() async throws {
        let rows: [MessageRecord] = try await client
            .from("messages")
            .select()
            .order("created_at", ascending: true)
            .execute()
            .value
        messages = rows.map(\.asChatMessage)
    }

    private func subscribe() async {
        let channel = client.channel("public:messages")
        let inserts = channel.postgresChange(InsertAction.self, schema: "public", table: "messages")
        await channel.subscribe()
        self.channel = channel

        listenTask = Task { [weak self] in
            for await insert in inserts {
                guard let self else { return }
                if let record = try? insert.decodeRecord(as: MessageRecord.self, decoder: Self.decoder) {
                    self.appendIfNew(record.asChatMessage)
                }
            }
        }
    }

    private func appendIfNew(_ message: ChatMessage) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
    }

    private static let decoder = JSONDecoder()
}

// MARK: - Database row shapes (only this file touches Supabase types)

private struct NewMessage: Encodable {
    let sender_id: UUID
    let sender_name: String
    let sender_avatar: String
    let content: String
}

private struct MessageRecord: Decodable {
    let id: UUID
    let sender_id: UUID
    let sender_name: String
    let sender_avatar: String
    let content: String
    let created_at: String

    var asChatMessage: ChatMessage {
        ChatMessage(id: id,
                    senderName: sender_name,
                    senderAvatar: sender_avatar,
                    date: ISODate.parse(created_at),
                    content: .text(content))
    }
}

// Postgres timestamps come back as ISO strings; ISO8601DateFormatter is picky
// about fractional-second length, so normalize to milliseconds first.
private enum ISODate {
    static let withFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    static let plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ raw: String) -> Date {
        var string = raw
        if let range = string.range(of: #"\.\d+"#, options: .regularExpression) {
            let digits = string[range].dropFirst()
            let millis = String((digits + "000").prefix(3))
            string.replaceSubrange(range, with: "." + millis)
        }
        return withFraction.date(from: string) ?? plain.date(from: string) ?? Date()
    }
}
