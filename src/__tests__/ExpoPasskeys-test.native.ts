import { Platform } from 'react-native';
import { Passkey } from '../Passkey';
import AuthRequest from './data/AuthRequest.json';
import RegRequest from './data/RegRequest.json';
import AuthiOSResult from './data/AuthiOSResult.json';
import RegiOSResult from './data/RegiOSResult.json';
import AuthAndroidResult from './data/AuthAndroidResult.json';
import RegAndroidResult from './data/RegAndroidResult.json';
import ExpoPasskeysModule from '../ExpoPasskeysModule';

const PLATFORM = Platform.OS;
if (PLATFORM === 'web') {
  describe('Web', () => {
    it('should skip web tests', () => {
      expect(true).toBe(true);
    });
  });
  // Exit early for web platform
  throw new Error('Skip web tests');
}

jest.mock('../ExpoPasskeysModule', () => ({
  create: jest.fn(),
  get: jest.fn(),
}));

describe('Passkey Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Platform.OS = 'ios';
    Platform.Version = '15.0';
  });

  describe('iOS', () => {
    beforeEach(() => {
      Platform.OS = 'ios';
      Platform.Version = '15.0';
      ExpoPasskeysModule.create.mockResolvedValue(RegiOSResult);
      ExpoPasskeysModule.get.mockResolvedValue(AuthiOSResult);
    });

    it('should return unsupported for iOS Version below 15.0', () => {
      Platform.Version = '14.2';
      expect(Passkey.isSupported()).toBeFalsy();
    });

    it('should call native register method', async () => {
      const result = await Passkey.create(RegRequest);
      expect(ExpoPasskeysModule.create).toHaveBeenCalledWith(
        JSON.stringify(RegRequest),
        false,
        false
      );
      expect(result).toEqual(RegiOSResult);
    });

    it('should call native auth method', async () => {
      const result = await Passkey.get(AuthRequest);
      expect(ExpoPasskeysModule.get).toHaveBeenCalledWith(
        JSON.stringify(AuthRequest),
        false,
        false
      );
      expect(result).toEqual(AuthiOSResult);
    });

    it('should handle platform key registration', async () => {
      const result = await Passkey.createPlatformKey(RegRequest);
      expect(ExpoPasskeysModule.create).toHaveBeenCalledWith(
        JSON.stringify(RegRequest),
        true,
        false
      );
      expect(result).toEqual(RegiOSResult);
    });

    it('should handle security key registration', async () => {
      const result = await Passkey.createSecurityKey(RegRequest);
      expect(ExpoPasskeysModule.create).toHaveBeenCalledWith(
        JSON.stringify(RegRequest),
        false,
        true
      );
      expect(result).toEqual(RegiOSResult);
    });
  });

  describe('Android', () => {
    beforeEach(() => {
      Platform.OS = 'android';
      Platform.Version = 33;
      ExpoPasskeysModule.create.mockResolvedValue(RegAndroidResult);
      ExpoPasskeysModule.get.mockResolvedValue(AuthAndroidResult);
    });

    it('should return unsupported for Android Versions below 28', () => {
      Platform.Version = 26;
      expect(Passkey.isSupported()).toBeFalsy();
    });

    it('should call native register method', async () => {
      const result = await Passkey.create(RegRequest);
      expect(ExpoPasskeysModule.create).toHaveBeenCalledWith(
        JSON.stringify(RegRequest),
        false,
        false
      );
      expect(result).toEqual(RegAndroidResult);
    });

    it('should call native auth method', async () => {
      const result = await Passkey.get(AuthRequest);
      expect(ExpoPasskeysModule.get).toHaveBeenCalledWith(
        JSON.stringify(AuthRequest),
        false,
        false
      );
      expect(result).toEqual(AuthAndroidResult);
    });
  });
}); 