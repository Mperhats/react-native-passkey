import ExpoPasskeysModule from './ExpoPasskeysModule'
import { handleNativeError, NotSupportedError } from './PasskeyError';
import { Platform } from 'react-native';
import type {
  PasskeyCreateRequest,
  PasskeyCreateResult,
  PasskeySignRequest,
  PasskeySignResult,
} from './PasskeyTypes';

export class Passkey {
  /**
   * Creates a new Passkey
   *
   * @param request The FIDO2 Attestation Request in JSON format
   * @param options An object containing options for the registration process
   * @returns The FIDO2 Attestation Result in JSON format
   * @throws
   */
  public static async create(
    request: PasskeyCreateRequest
  ): Promise<PasskeyCreateResult> {
    if (!Passkey.isSupported()) {
      throw NotSupportedError;
    }

    try {
      const response: PasskeyCreateResult = await ExpoPasskeysModule.create(
        JSON.stringify(request),
        false, // forcePlatformKey
        false // forceSecurityKey
      ) as PasskeyCreateResult

      return response;
    } catch (error) {
      throw handleNativeError(error);
    }
  }

  /**
   * Creates a new Passkey
   * Forces the usage of a platform authenticator on iOS
   *
   * @param request The FIDO2 Attestation Request in JSON format
   * @param options An object containing options for the registration process
   * @returns The FIDO2 Attestation Result in JSON format
   * @throws
   */
  public static async createPlatformKey(
    request: PasskeyCreateRequest
  ): Promise<PasskeyCreateResult> {
    if (!Passkey.isSupported()) {
      throw NotSupportedError;
    }

    try {
      const response: PasskeyCreateResult = await ExpoPasskeysModule.create(
        JSON.stringify(request),
        true, // forcePlatformKey
        false // forceSecurityKey
      ) as PasskeyCreateResult;

      return response;
    } catch (error) {
      throw handleNativeError(error);
    }
  }

  /**
   * Creates a new Passkey
   * Forces the usage of a security authenticator on iOS
   *
   * @param request The FIDO2 Attestation Request in JSON format
   * @param options An object containing options for the registration process
   * @returns The FIDO2 Attestation Result in JSON format
   * @throws
   */
  public static async createSecurityKey(
    request: PasskeyCreateRequest
  ): Promise<PasskeyCreateResult> {
    if (!Passkey.isSupported()) {
      throw NotSupportedError;
    }

    try {
      const response: PasskeyCreateResult = await ExpoPasskeysModule.create(
        JSON.stringify(request),
        false, // forcePlatformKey
        true // forceSecurityKey
      ) as PasskeyCreateResult;

      return response;
    } catch (error) {
      throw handleNativeError(error);
    }
  }

  /**
   * Authenticates using an existing Passkey
   *
   * @param request The FIDO2 Assertion Request in JSON format
   * @param options An object containing options for the authentication process
   * @returns The FIDO2 Assertion Result in JSON format
   * @throws
   */
  public static async get(
    request: PasskeySignRequest
  ): Promise<PasskeySignResult> {
    if (!Passkey.isSupported()) {
      throw NotSupportedError;
    }

    try {
      const response: PasskeySignResult = await ExpoPasskeysModule.sign(
        JSON.stringify(request),
        false, // forcePlatformKey
        false // forceSecurityKey
      ) as PasskeySignResult;

      return response;
    } catch (error) {
      throw handleNativeError(error);
    }
  }

  /**
   * Authenticates using an existing Passkey
   * Forces the usage of a platform authenticator on iOS
   *
   * @param request The FIDO2 Assertion Request in JSON format
   * @param options An object containing options for the authentication process
   * @returns The FIDO2 Assertion Result in JSON format
   * @throws
   */
  public static async getPlatformKey(
    request: PasskeySignRequest
  ): Promise<PasskeySignResult> {
    if (!Passkey.isSupported()) {
      throw NotSupportedError;
    }

    try {
      const response: PasskeySignResult = await ExpoPasskeysModule.sign(
        JSON.stringify(request),
        true, // forcePlatformKey
        false // forceSecurityKey
      ) as PasskeySignResult;

      return response;
    } catch (error) {
      throw handleNativeError(error);
    }
  }

  /**
   * Authenticates using an existing Passkey
   * Forces the usage of a security authenticator on iOS
   *
   * @param request The FIDO2 Assertion Request in JSON format
   * @param options An object containing options for the authentication process
   * @returns The FIDO2 Assertion Result in JSON format
   * @throws
   */
  public static async getSecurityKey(
    request: PasskeySignRequest
  ): Promise<PasskeySignResult> {
    if (!Passkey.isSupported()) {
      throw NotSupportedError;
    }

    try {
      const response: PasskeySignResult = await ExpoPasskeysModule.sign(
        JSON.stringify(request),
        false, // forcePlatformKey
        true // forceSecurityKey
      ) as PasskeySignResult;

      return response;
    } catch (error) {
      throw handleNativeError(error);
    }
  }

  /**
   * Checks if Passkeys are supported on the current device
   *
   * @returns A boolean indicating whether Passkeys are supported
   */
  public static isSupported(): boolean {
    if (Platform.OS === 'android') {
      return Platform.Version > 28;
    }

    if (Platform.OS === 'ios') {
      return parseInt(Platform.Version, 10) >= 15;
    }

    return false;
  }
}
