@available(iOS 15.0, *)
protocol RNPasskeyResultHandler {
    func onSuccess(_ data: PublicKeyCredentialJSON)
    func onError(_ error: Error)
}

@available(iOS 15.0, *)
class ResponseHandler: RNPasskeyResultHandler {
    private let handler: RNPasskeyHandler
    
    init(promise: Promise) {
        self.handler = RNPasskeyHandler(
            { value in promise.resolve(value) },
            { code, message, error in promise.reject(code, message, error) }
        )
    }
    
    func onSuccess(_ data: PublicKeyCredentialJSON) {
        do {
            let data = try JSONEncoder().encode(data)
            handler.resolve(try JSONSerialization.jsonObject(with: data))
        } catch {
            onError(RNPasskeyError(type: .unknown, message: error.localizedDescription))
        }
    }
    
    func onError(_ error: Error) {
        if let passkeyError = error as? RNPasskeyError {
            handler.reject(passkeyError.type.rawValue, passkeyError.message, nil)
        } else {
            let nsError = error as NSError
            handler.reject(RNPasskeyErrorType.unknown.rawValue, nsError.localizedDescription, error)
        }
    }
    
    // Move the response handling methods here as static functions
    static func handlePlatformPublicKeyRegistrationResponse(_ credential: ASAuthorizationPlatformPublicKeyCredentialRegistration) throws -> PublicKeyCredentialJSON {
        if credential.rawAttestationObject == nil {
            throw RNPasskeyError(type: .requestFailed, message: "Invalid attestation object")
        }
        
        let response = AuthenticatorAttestationResponseJSON(
            clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
            attestationObject: credential.rawAttestationObject!.toBase64URLEncodedString()
        )
        
        var clientExtensionResults: AuthenticationExtensionsClientOutputsJSON?
        if #available(iOS 17.0, *), credential.largeBlob != nil {
            let largeBlob = AuthenticationExtensionsLargeBlobOutputsJSON(
                supported: credential.largeBlob?.isSupported
            )
            clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(largeBlob: largeBlob)
        }
        
        let createResponse = RNPasskeyCreateResponseJSON(
            id: credential.credentialID.toBase64URLEncodedString(),
            rawId: credential.credentialID.toBase64URLEncodedString(),
            type: "public-key",
            response: response,
            clientExtensionResults: clientExtensionResults
        )
        
        return .create(createResponse)
    }
    
    static func handleSecurityKeyPublicKeyRegistrationResponse(_ credential: ASAuthorizationSecurityKeyPublicKeyCredentialRegistration) throws -> PublicKeyCredentialJSON {
        if credential.rawAttestationObject == nil {
            throw RNPasskeyError(type: .requestFailed, message: "Invalid attestation object")
        }
        
        var transports: [AuthenticatorTransport] = []
        
        if #available(iOS 17.5, *) {
            if let securityKeyCredential = credential as? ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor {
                transports = securityKeyCredential.transports.compactMap { transport in
                    AuthenticatorTransport(rawValue: transport.rawValue)
                }
            }
        }
        
        let response = AuthenticatorAttestationResponseJSON(
            clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
            transports: transports,
            attestationObject: credential.rawAttestationObject!.toBase64URLEncodedString()
        )
        
        let createResponse = RNPasskeyCreateResponseJSON(
            id: credential.credentialID.toBase64URLEncodedString(),
            rawId: credential.credentialID.toBase64URLEncodedString(),
            response: response
        )
        
        return .create(createResponse)
    }
    
    static func handlePlatformPublicKeyAssertionResponse(_ credential: ASAuthorizationPlatformPublicKeyCredentialAssertion) -> PublicKeyCredentialJSON {
        var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON? = AuthenticationExtensionsLargeBlobOutputsJSON()
        if #available(iOS 17.0, *), let result = credential.largeBlob?.result {
            switch result {
            case .read(data: let blobData):
                if let blob = blobData?.uIntArray {
                    largeBlob?.blob = blob
                }
            case .write(success: let successfullyWritten):
                largeBlob?.written = successfullyWritten
            @unknown default: break
            }
        }
        
        let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(largeBlob: largeBlob)
        let userHandle: String? = credential.userID.flatMap { String(data: $0, encoding: .utf8) }
        
        let response = AuthenticatorAssertionResponseJSON(
            authenticatorData: credential.rawAuthenticatorData.toBase64URLEncodedString(),
            clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
            signature: credential.signature!.toBase64URLEncodedString(),
            userHandle: userHandle
        )
        
        let getResponse = RNPasskeySignResponseJSON(
            id: credential.credentialID.toBase64URLEncodedString(),
            rawId: credential.credentialID.toBase64URLEncodedString(),
            response: response,
            clientExtensionResults: clientExtensionResults
        )
        
        return .get(getResponse)
    }
    
    static func handleSecurityKeyPublicKeyAssertionResponse(_ credential: ASAuthorizationSecurityKeyPublicKeyCredentialAssertion) -> PublicKeyCredentialJSON {
        let userHandle: String? = credential.userID.flatMap { String(data: $0, encoding: .utf8) }
        
        let response = AuthenticatorAssertionResponseJSON(
            authenticatorData: credential.rawAuthenticatorData.toBase64URLEncodedString(),
            clientDataJSON: credential.rawClientDataJSON.toBase64URLEncodedString(),
            signature: credential.signature!.toBase64URLEncodedString(),
            userHandle: userHandle
        )
        
        let getResponse = RNPasskeySignResponseJSON(
            id: credential.credentialID.toBase64URLEncodedString(),
            rawId: credential.credentialID.toBase64URLEncodedString(),
            response: response
        )
        
        return .get(getResponse)
    }
} 