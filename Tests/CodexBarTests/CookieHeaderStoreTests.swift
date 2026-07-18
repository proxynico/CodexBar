import Foundation
import Testing
@testable import CodexBar
@testable import CodexBarCore

@Suite(.serialized)
struct CookieHeaderStoreTests {
    @Test
    func `interaction unavailable reads are not negative cached`() throws {
        let store = KeychainCookieHeaderStore(
            account: "interaction-unavailable-\(UUID().uuidString)",
            promptKind: .claudeCookie)
        var promptCount = 0
        let promptHandler: (KeychainPromptContext) -> Void = { _ in promptCount += 1 }

        try KeychainAccessGate.withTaskOverrideForTesting(false) {
            try KeychainAccessPreflight.withCheckGenericPasswordOverrideForTesting { _, _ in
                .interactionRequired
            } operation: {
                try KeychainPromptHandler.withHandlerForTesting(promptHandler) {
                    let first = try store.loadCookieHeader()
                    let second = try store.loadCookieHeader()
                    #expect(first == nil)
                    #expect(second == nil)
                }
            }
        }

        #expect(promptCount == 2)
    }
}
