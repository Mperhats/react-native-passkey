import AuthenticationServices
import ExpoModulesCore

// A set used to retain pending requests until their callback is called
var pendingRequests: Set<AuthResponder> = Set<AuthResponder>()

@available(iOS 15.0, *)
class AuthResponder: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    private let handler: ResponseHandler
    
    init(promise: Promise) {
        self.handler = ResponseHandler(promise: promise)
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.keyWindow else {
            fatalError("Unable to present modal because UIApplication.shared.keyWindow is not available")
        }
        return window
    }

    func performAuth(controller: ASAuthorizationController) {
        controller.delegate = self
        controller.presentationContextProvider = self
        pendingRequests.insert(self)
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        do {
            let result: PublicKeyCredentialJSON
            
            switch authorization.credential {
            case let credential as ASAuthorizationPlatformPublicKeyCredentialRegistration:
                result = try ResponseHandler.handlePlatformPublicKeyRegistrationResponse(credential)
            case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialRegistration:
                result = try ResponseHandler.handleSecurityKeyPublicKeyRegistrationResponse(credential)
            case let credential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
                result = try ResponseHandler.handlePlatformPublicKeyAssertionResponse(credential)
            case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialAssertion:
                result = try ResponseHandler.handleSecurityKeyPublicKeyAssertionResponse(credential)
            default:
                throw RNPasskeyError(type: .requestFailed, message: "Unexpected credential type")
            }
            
            handler.onSuccess(result)
        } catch {
            handler.onError(error)
        }
        
        pendingRequests.remove(self)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handler.onError(RNPasskeyError(type: .requestFailed, message: error.localizedDescription))
        pendingRequests.remove(self)
    }
} 