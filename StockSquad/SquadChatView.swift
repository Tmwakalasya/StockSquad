import SwiftUI

// The squad's group chat — LIVE on Supabase (Phase 3, slice 1).
//
// Messages persist in a `messages` table and stream in over realtime, so the
// whole squad sees them instantly. Identity is anonymous: each device gets a
// hidden user id, and you pick a display name (saved on-device) that rides on
// every message. Reactions are still local-only for now — a nice follow-up
// once we add a reactions table.

// MARK: - UI model

struct ChatMessage: Identifiable {
    let id: UUID
    let senderName: String
    let senderAvatar: String
    let date: Date
    let content: Content
    var reactions: [String]

    init(id: UUID = UUID(),
         senderName: String,
         senderAvatar: String,
         date: Date,
         content: Content,
         reactions: [String] = []) {
        self.id = id
        self.senderName = senderName
        self.senderAvatar = senderAvatar
        self.date = date
        self.content = content
        self.reactions = reactions
    }

    enum Content {
        case text(String)
        /// A message anchored to a real move — wired up in a later slice.
        case trade(verb: String, shares: Int, ticker: String, blurb: String)
    }
}

// MARK: - Screen

struct SquadChatView: View {
    @StateObject private var chat = ChatStore(defaultName: "You", defaultAvatar: "🦅")

    @State private var draft: String = ""
    @State private var showingIdentity = false

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach($chat.messages) { $message in
                                MessageRow(message: $message,
                                           isMe: message.senderName == chat.displayName)
                            }
                            Color.clear.frame(height: 1).id("BOTTOM")
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                    .overlay { statusOverlay }
                    .onChange(of: chat.messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("BOTTOM", anchor: .bottom)
                        }
                    }
                }
                inputBar
            }
        }
        .navigationTitle("Squad Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingIdentity = true } label: {
                    HStack(spacing: 4) {
                        Text(chat.avatar)
                        Image(systemName: "pencil").font(.caption2)
                    }
                }
                .accessibilityLabel("Edit your chat name")
            }
        }
        .sheet(isPresented: $showingIdentity) {
            IdentitySheet(name: chat.displayName, avatar: chat.avatar) { name, avatar in
                chat.saveIdentity(name: name, avatar: avatar)
            }
        }
        .task { await chat.start() }
        .onDisappear { chat.stop() }
        .onAppear {
            if !chat.hasSavedIdentity { showingIdentity = true }
        }
    }

    @ViewBuilder private var statusOverlay: some View {
        switch chat.phase {
        case .connecting where chat.messages.isEmpty:
            ProgressView("Connecting…")
                .tint(Theme.accent)
                .foregroundStyle(Theme.textSecondary)
        case .ready where chat.messages.isEmpty:
            VStack(spacing: 6) {
                Text("👋").font(.largeTitle)
                Text("No messages yet")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Be the first to say something.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        case .failed(let message):
            VStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
                Text("Couldn't connect")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await chat.start() } }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(24)
        default:
            EmptyView()
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message the squad…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.bgRaised, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))

            Button {
                let text = draft
                draft = ""
                Task { await chat.send(text) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(canSend ? Theme.accent : Theme.textSecondary.opacity(0.4),
                                in: Circle())
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && chat.phase == .ready
    }
}

// MARK: - One message (bubble + reactions)

private struct MessageRow: View {
    @Binding var message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe {
                Spacer(minLength: 44)
            } else {
                Text(message.senderAvatar)
                    .font(.system(size: 24))
                    .frame(width: 38, height: 38)
                    .background(Theme.bgRaised, in: Circle())
                    .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    HStack(spacing: 6) {
                        Text(message.senderName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text(message.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    }
                }
                bubble
                    .onTapGesture { toggleReaction("🚀") }
                if !message.reactions.isEmpty { reactionPills }
            }

            if !isMe { Spacer(minLength: 44) }
        }
    }

    @ViewBuilder private var bubble: some View {
        switch message.content {
        case .text(let text):
            Text(text)
                .font(.subheadline)
                .foregroundStyle(isMe ? .white : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isMe ? Theme.accent : Theme.card,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        case .trade(let verb, let shares, let ticker, let blurb):
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.accent)
                    .frame(width: 4, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(verb.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.accent)
                        Text("\(shares) \(ticker)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    if !blurb.isEmpty {
                        Text(blurb)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.accent.opacity(0.30), lineWidth: 1)
            )
        }
    }

    private var reactionPills: some View {
        HStack(spacing: 4) {
            ForEach(uniqueReactions, id: \.self) { emoji in
                let count = message.reactions.filter { $0 == emoji }.count
                HStack(spacing: 2) {
                    Text(emoji).font(.caption2)
                    if count > 1 {
                        Text("\(count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Theme.bgRaised, in: Capsule())
                .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
            }
        }
    }

    private var uniqueReactions: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for reaction in message.reactions where seen.insert(reaction).inserted {
            ordered.append(reaction)
        }
        return ordered
    }

    /// Local-only for now — tapping adds/removes your reaction on this device.
    private func toggleReaction(_ emoji: String) {
        if let index = message.reactions.firstIndex(of: emoji) {
            message.reactions.remove(at: index)
        } else {
            message.reactions.append(emoji)
        }
    }
}

// MARK: - "Who are you?" sheet (pick a display name + emoji)

private struct IdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String
    @State var avatar: String
    let onSave: (String, String) -> Void

    private let choices = ["🦅", "🐺", "🦊", "🐢", "🐱", "🐯",
                           "🦁", "🐸", "🐵", "🐳", "🚀", "💎"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your name")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        TextField("e.g. Wes", text: $name)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your emoji")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(choices, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(avatar == emoji ? Theme.accent.opacity(0.25) : Theme.card,
                                                in: Circle())
                                    .overlay(Circle().stroke(avatar == emoji ? Theme.accent : Theme.stroke,
                                                             lineWidth: avatar == emoji ? 2 : 1))
                                    .onTapGesture { avatar = emoji }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Who are you?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, avatar)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
