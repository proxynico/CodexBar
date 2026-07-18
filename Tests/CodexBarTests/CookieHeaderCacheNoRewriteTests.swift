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
