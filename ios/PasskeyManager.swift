import AuthenticationServices
import ExpoModulesCore

@available(iOS 15.0, *)
public class PasskeyManager {
    private func configureCreatePlatformRequest(challenge: Data, userId: Data, request: RNPasskeyCredentialCreationOptions) -> ASAuthorizationRequest {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: request.rp.id ?? request.rp.name)
        let registrationRequest = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: request.user.name,
            userID: userId
        )
        
        // Apply authenticator selection if present
        if let authenticatorSelection = request.authenticatorSelection {
            registrationRequest.userVerificationPreference = authenticatorSelection.userVerification?.appleise() ?? .preferred
        }
        
        return registrationRequest
    }
    
    private func configureCreateSecurityKeyRequest(challenge: Data, userId: Data, request: RNPasskeyCredentialCreationOptions) -> ASAuthorizationRequest {
        let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: request.rp.id ?? request.rp.name)
        let registrationRequest = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            displayName: request.user.displayName,
            name: request.user.name,
            userID: userId
        )
        
        // Apply credential parameters
        registrationRequest.credentialParameters = request.pubKeyCredParams.map { $0.appleise() }
        
        // Apply authenticator selection if present
        if let authenticatorSelection = request.authenticatorSelection {
            registrationRequest.userVerificationPreference = authenticatorSelection.userVerification?.appleise() ?? .preferred
            registrationRequest.residentKeyPreference = authenticatorSelection.residentKey?.appleise() ?? .preferred
        }
        
        // Apply attestation if present
        if let attestation = request.attestation {
            registrationRequest.attestationPreference = attestation.appleise()
        }
        
        // Apply extensions if present
        if #available(iOS 17.0, *), let largeBlob = request.extensions?.largeBlob {
            if let support = largeBlob.support {
                registrationRequest.largeBlobRegistrationInput = support.appleise()
            }
        }
        
        return registrationRequest
    }
    
    private func configureGetPlatformRequest(challenge: Data, request: RNPasskeyCredentialRequestOptions) -> ASAuthorizationRequest {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: request.rpId)
        let assertionRequest = provider.createCredentialAssertionRequest(challenge: challenge)
        
        // Apply allowed credentials if present
        if let allowCredentials = request.allowCredentials {
            assertionRequest.allowedCredentials = allowCredentials.map { $0.getPlatformDescriptor() }
        }
        
        // Apply user verification if present
        if let userVerification = request.userVerification {
            assertionRequest.userVerificationPreference = userVerification.appleise()
        }
        
        return assertionRequest
    }
    
    private func configureGetSecurityKeyRequest(challenge: Data, request: RNPasskeyCredentialRequestOptions) -> ASAuthorizationRequest {
        let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: request.rpId)
        let assertionRequest = provider.createCredentialAssertionRequest(challenge: challenge)
        
        // Apply allowed credentials if present
        if let allowCredentials = request.allowCredentials {
            assertionRequest.allowedCredentials = allowCredentials.map { $0.getCrossPlatformDescriptor() }
        }
        
        // Apply user verification if present
        if let userVerification = request.userVerification {
            assertionRequest.userVerificationPreference = userVerification.appleise()
        }
        
        // Apply extensions if present
        if #available(iOS 17.0, *), let largeBlob = request.extensions?.largeBlob {
            if let read = largeBlob.read {
                assertionRequest.largeBlobRead = read
            }
            if let write = largeBlob.write {
                assertionRequest.largeBlobWrite = write
            }
        }
        
        return assertionRequest
    }

    public func createKey(request: String, useSecurityKey: Bool, promise: Promise) {
        do {
            // Decode request object
            let requestData = request.data(using: .utf8)!
            let requestJSON = try JSONDecoder().decode(RNPasskeyCredentialCreationOptions.self, from: requestData)
            
            // Convert challenge to Data
            guard let challenge = Data(base64URLEncoded: requestJSON.challenge) else {
                throw RNPasskeyError(type: .invalidChallenge)
            }
            
            // Convert userId to Data
            guard let userId = requestJSON.user.id.data(using: .utf8) else {
                throw RNPasskeyError(type: .invalidUser)
            }
            
            // Create requests
            let request: ASAuthorizationRequest = useSecurityKey 
                ? configureCreateSecurityKeyRequest(challenge: challenge, userId: userId, request: requestJSON)
                : configureCreatePlatformRequest(challenge: challenge, userId: userId, request: requestJSON)
            
            let controller: ASAuthorizationController = ASAuthorizationController(authorizationRequests: [request])
            let authResponder = AuthResponder(promise: promise)
            authResponder.performAuth(controller: controller)
        } catch {
            promise.reject("ERROR", error.localizedDescription, error)
        }
    }

    public func signWithKey(request: String, useSecurityKey: Bool, promise: Promise) {
        do {
            // Decode request object
            let requestData: Data = request.data(using: .utf8)!
            let requestJSON = try JSONDecoder().decode(RNPasskeyCredentialRequestOptions.self, from: requestData)
            
            // Convert challenge to Data
            guard let challenge = Data(base64URLEncoded: requestJSON.challenge) else {
                throw RNPasskeyError(type: .invalidChallenge)
            }
            
            // Create request
            let request: ASAuthorizationRequest = useSecurityKey
                ? configureGetSecurityKeyRequest(challenge: challenge, request: requestJSON)
                : configureGetPlatformRequest(challenge: challenge, request: requestJSON)
            
            let controller: ASAuthorizationController = ASAuthorizationController(authorizationRequests: [request])
            let authResponder = AuthResponder(promise: promise)
            authResponder.performAuth(controller: controller)
        } catch {
            promise.reject("ERROR", error.localizedDescription, error)
        }
    }
} 