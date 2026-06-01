import Foundation
import Supabase

// One shared Supabase client for the whole app (Phase 3).
//
// The publishable key lives in git-ignored Secrets.swift. Real protection comes
// from the Row Level Security policies on the database (see supabase/schema.sql),
// not from hiding this key — anyone can read it from a shipped app.
enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseKey
    )

    /// Make sure this device has a session before reading/writing.
    ///
    /// Anonymous sign-in hands the device a real user id (so the "you can only
    /// post as yourself" rule works) without ever showing a login screen. The
    /// session is cached on-device, so we only mint one the very first time.
    static func signInIfNeeded() async throws {
        if client.auth.currentSession == nil {
            _ = try await client.auth.signInAnonymously()
        }
    }
}
