import Foundation
import Testing
@testable import CodexBarCore

@Suite(.serialized)
struct CookieHeaderCacheNoRewriteTests {
    @Test
    func `unchanged cookie payload does not rewrite stored entry`() {
        self.withIsolatedCookieCache {
            let firstStoredAt = Date(timeIntervalSince1970: 10)
            let secondStoredAt = Date(timeIntervalSince1970: 20)

            CookieHeaderCache.store(
                provider: .commandcode,
                cookieHeader: "auth=abc",
                sourceLabel: "Chrome",
                now: firstStoredAt)
            CookieHeaderCache.store(
                provider: .commandcode,
                cookieHeader: "auth=abc",
                sourceLabel: "Chrome",
                now: secondStoredAt)

            let loaded = CookieHeaderCache.load(provider: .commandcode)
            #expect(loaded?.cookieHeader == "auth=abc")
            #expect(loaded?.sourceLabel == "Chrome")
            #expect(loaded?.storedAt == firstStoredAt)
        }
    }

    @Test
    func `unchanged refresh transaction retains entry without a keychain write`() {
        self.withIsolatedCookieCache {
            CookieHeaderCache.store(
                provider: .commandcode,
                cookieHeader: "auth=abc",
                sourceLabel: "Chrome",
                now: Date(timeIntervalSince1970: 10))
            let recorder = KeychainCacheStore.OperationRecorder()

            let summary = KeychainCacheStore.withOperationRecorderForTesting(recorder) {
                guard let gate = CookieHeaderCache.beginRefreshReadSuppression(provider: .commandcode) else {
                    Issue.record("Expected refresh suppression gate")
                    return CookieRefreshCommitSummary(stagedCount: 0, committedCount: 0, failedCount: 1)
                }
                #expect(CookieHeaderCache.storeResult(
                    provider: .commandcode,
                    cookieHeader: "auth=abc",
                    sourceLabel: "Chrome",
                    now: Date(timeIntervalSince1970: 20)))
                return CookieHeaderCache.commitRefreshReadSuppression(gate)
            }

            #expect(summary == CookieRefreshCommitSummary(stagedCount: 1, committedCount: 1, failedCount: 0))
            #expect(recorder.operations == [.load])
            #expect(CookieHeaderCache.load(provider: .commandcode)?.storedAt == Date(timeIntervalSince1970: 10))
        }
    }

    @Test
    func `changed cookie payload rewrites stored entry`() {
        self.withIsolatedCookieCache {
            let firstStoredAt = Date(timeIntervalSince1970: 10)
            let secondStoredAt = Date(timeIntervalSince1970: 20)

            CookieHeaderCache.store(
                provider: .commandcode,
                cookieHeader: "auth=abc",
                sourceLabel: "Chrome",
                now: firstStoredAt)
            CookieHeaderCache.store(
                provider: .commandcode,
                cookieHeader: "auth=def",
                sourceLabel: "Chrome",
                now: secondStoredAt)

            let loaded = CookieHeaderCache.load(provider: .commandcode)
            #expect(loaded?.cookieHeader == "auth=def")
            #expect(loaded?.sourceLabel == "Chrome")
            #expect(loaded?.storedAt == secondStoredAt)
        }
    }

    @Test
    func `changed authentication policy rewrites stored entry`() {
        self.withIsolatedCookieCache {
            let firstStoredAt = Date(timeIntervalSince1970: 10)
            let secondStoredAt = Date(timeIntervalSince1970: 20)

            CookieHeaderCache.store(
                provider: .commandcode,
                cookieHeader: "auth=abc",
                sourceLabel: "Chrome",
                now: firstStoredAt)
            let stored = CookieHeaderCache.storeResult(
                provider: .commandcode,
                cookieHeader: "auth=abc",
                sourceLabel: "Chrome",
                authenticationFailurePolicy: .stopFallback,
                now: secondStoredAt)

            let loaded = CookieHeaderCache.load(provider: .commandcode)
            #expect(stored)
            #expect(loaded?.storedAt == secondStoredAt)
            #expect(loaded?.authenticationFailurePolicy == .stopFallback)
        }
    }

    private func withIsolatedCookieCache(_ body: () -> Void) {
        KeychainCacheStore.setTestStoreForTesting(true)
        CookieHeaderCache.resetDisplayCacheForTesting()
        defer {
            CookieHeaderCache.clearAllScopes(provider: .commandcode)
            CookieHeaderCache.resetDisplayCacheForTesting()
            KeychainCacheStore.setTestStoreForTesting(false)
        }
        body()
    }
}
