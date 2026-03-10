// MARK: - Core.Utilities

import CryptoKit
import Foundation
import Security

final class SSLPinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedHosts: Set<String>
    private let pinnedSPKIHashes: Set<String>

    init(pinnedHosts: [String], pinnedSPKIHashes: [String]) {
        self.pinnedHosts = Set(pinnedHosts)
        self.pinnedSPKIHashes = Set(pinnedSPKIHashes)
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        _ = session

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host
        guard pinnedHosts.contains(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard !pinnedSPKIHashes.isEmpty else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard SecTrustEvaluateWithError(trust, nil),
              let key = SecTrustCopyKey(trust),
              let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverHash = Data(SHA256.hash(data: keyData)).base64EncodedString()
        if pinnedSPKIHashes.contains(serverHash) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
