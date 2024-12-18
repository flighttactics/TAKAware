//
//  APIRequestObject.swift
//  TAKAware
//
//  Created by Cory Foy on 12/18/24.
//

import Foundation

class APIRequestObject: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let authenticationMethod = challenge.protectionSpace.authenticationMethod

        if authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            TAKLogger.error("[ChannelManager]: Server requesting identity challenge")
            guard let clientIdentity = SettingsStore.global.retrieveIdentity(label: SettingsStore.global.takServerUrl) else {
                TAKLogger.error("[ChannelManager]: Identity was not stored in the keychain")
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            TAKLogger.error("[ChannelManager]: Using client identity")
            let credential = URLCredential(identity: clientIdentity,
                                               certificates: nil,
                                                persistence: .none)
            challenge.sender?.use(credential, for: challenge)
            completionHandler(.useCredential, credential)

        } else if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            TAKLogger.debug("[ChannelManager]: Server not trusted with default certs, seeing if we have custom ones")
            
            // var optionalTrust: SecTrust?
            var optionalTrust = challenge.protectionSpace.serverTrust
            var customCerts: [SecCertificate] = []

            let trustCerts = SettingsStore.global.serverCertificateTruststore
            TAKLogger.debug("[ChannelManager]: Truststore contains \(trustCerts.count) cert(s)")
            if !trustCerts.isEmpty {
                TAKLogger.debug("[ChannelManager]: Loading Trust Store Certs")
                trustCerts.forEach { cert in
                    if let convertedCert = SecCertificateCreateWithData(nil, cert as CFData) {
                        customCerts.append(convertedCert)
                    }
                }
            }
            
            if !customCerts.isEmpty {
                TAKLogger.debug("[ChannelManager]: We have custom certs, so disable hostname validation")
                let sslWithoutHostnamePolicy = SecPolicyCreateSSL(true, nil)
                guard SecTrustSetPolicies(optionalTrust!, sslWithoutHostnamePolicy) == errSecSuccess else {
                    completionHandler(.performDefaultHandling, nil)
                    return
                }
                
                do {
                    TAKLogger.debug("[ChannelManager]: Pinning certs as anchor certs")
                    try secCall { SecTrustSetAnchorCertificates(optionalTrust!, customCerts as NSArray) }
                } catch {
                    TAKLogger.error("[ChannelManager]: Unable to pin certs to root")
                    completionHandler(.performDefaultHandling, nil)
                    return
                }
            }

            if optionalTrust != nil {
                TAKLogger.debug("[ChannelManager]: Retrying with local truststore")
                let credential = URLCredential(trust: optionalTrust!)
                challenge.sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
            } else {
                TAKLogger.debug("[ChannelManager]: No custom truststore ultimately found")
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    func secCall(_ body: () -> OSStatus) throws {
        let err = body()
        guard err == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
        }
    }
}
