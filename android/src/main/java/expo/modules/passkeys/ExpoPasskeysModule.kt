package expo.modules.passkeys

import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialInterruptedException
import androidx.credentials.exceptions.CreateCredentialProviderConfigurationException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.CreateCredentialUnsupportedException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialInterruptedException
import androidx.credentials.exceptions.GetCredentialProviderConfigurationException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialUnsupportedException
import androidx.credentials.exceptions.NoCredentialException
import androidx.credentials.exceptions.publickeycredential.CreatePublicKeyCredentialDomException
import androidx.credentials.exceptions.publickeycredential.GetPublicKeyCredentialDomException
import com.google.gson.Gson
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ExpoPasskeysModule : Module() {
    private val REGISTRATION_RESPONSE = "androidx.credentials.BUNDLE_KEY_REGISTRATION_RESPONSE_JSON"
    private val AUTH_RESPONSE = "androidx.credentials.BUNDLE_KEY_AUTHENTICATION_RESPONSE_JSON"

    private val mainScope = CoroutineScope(Dispatchers.Default)

    override fun definition() = ModuleDefinition {
        Name("ExpoPasskeys")

        Function("isSupported") {
            val minApiLevelPasskeys = 28
            val currentApiLevel = android.os.Build.VERSION.SDK_INT
            return@Function currentApiLevel >= minApiLevelPasskeys
        }

        AsyncFunction("create") { requestJson: String, promise: Promise ->
            val credentialManager =
                CredentialManager.create(appContext.reactContext?.applicationContext!!)
            val createPublicKeyCredentialRequest = CreatePublicKeyCredentialRequest(requestJson)

            mainScope.launch {
                try {
                    val result = appContext.currentActivity?.let {
                        credentialManager.createCredential(it, createPublicKeyCredentialRequest)
                    }
                    val response =
                        result?.data?.getString(REGISTRATION_RESPONSE)
                
                    promise.resolve(response)
                } catch (e: CreateCredentialException) {
                    promise.reject("Passkey Create", getRegistrationException(e), e)
                }
            }
        }

        AsyncFunction("get") { requestJson: String, promise: Promise ->
            val credentialManager =
                CredentialManager.create(appContext.reactContext?.applicationContext!!)
            val getCredentialRequest =
                GetCredentialRequest(listOf(GetPublicKeyCredentialOption(requestJson)))

            mainScope.launch {
                try {
                    val result = appContext.currentActivity?.let {
                        credentialManager.getCredential(it, getCredentialRequest)
                    }
                    val response =
                        result?.credential?.data?.getString(AUTH_RESPONSE)
                    promise.resolve(response)
                } catch (e: GetCredentialException) {
                    promise.reject("Passkey Get", getAuthenticationException(e), e)
                }
            }
        }
    }

    private fun getRegistrationException(e: CreateCredentialException) =
        when (e) {
            is CreatePublicKeyCredentialDomException -> {
                e.errorMessage.toString()
                
            }

            is CreateCredentialCancellationException -> {
                "UserCancelled"
            }

            is CreateCredentialInterruptedException -> {
                "Interrupted"
            }

            is CreateCredentialProviderConfigurationException -> {
                "NotConfigured"
            }

            is CreateCredentialUnknownException -> {
                "UnknownError"
            }

            is CreateCredentialUnsupportedException -> {
                "NotSupported"
            }

            else -> e.toString()
        }

    private fun getAuthenticationException(e: GetCredentialException) =
        when (e) {
            is GetPublicKeyCredentialDomException -> {
                e.domError.toString()
            }

            is GetCredentialCancellationException -> {
                "UserCancelled"
            }

            is GetCredentialInterruptedException -> {
                "Interrupted"
            }

            is GetCredentialProviderConfigurationException -> {
                "NotConfigured"
            }

            is GetCredentialUnknownException -> {
                "UnknownError"
            }

            is GetCredentialUnsupportedException -> {
                "NotSupported"
            }

            is NoCredentialException -> {
                "NoCredentials"
            }

            else -> {
                e.toString()
            }
        }

}