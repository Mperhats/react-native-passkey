import ExpoModulesCore

public class ExpoPasskeysModule: Module {
  private let passkeyManager = PasskeyManager()

  public func definition() -> ModuleDefinition {
    Name("ExpoPasskeys")

    AsyncFunction("create") { (domain: String, accountName: String, userIdBase64: String, challengeBase64: String, useSecurityKey: Bool, promise: Promise) in
      self.passkeyManager.createKey(domain: domain, accountName: accountName, userIdBase64: userIdBase64, challengeBase64: challengeBase64, useSecurityKey: useSecurityKey, promise: promise)
    }

    AsyncFunction("get") { (domain: String, challengeBase64: String, useSecurityKey: Bool, promise: Promise) in
      self.passkeyManager.getKey(domain: domain, challengeBase64: challengeBase64, useSecurityKey: useSecurityKey, promise: promise)
    }
  }
} 