import { Platform } from 'react-native';
import { Passkey } from '../Passkey';
import AuthRequest from './data/AuthRequest.json';
import RegRequest from './data/RegRequest.json';
import AuthiOSResult from './data/AuthiOSResult.json';
import RegiOSResult from './data/RegiOSResult.json';
import ExpoPasskeysModule from '../ExpoPasskeysModule';

jest.mock('../ExpoPasskeysModule', () => ({
  create: jest.fn(),
  get: jest.fn(),
}));

describe('Passkey Module - iOS', () => {
  beforeEach(() => {
    jest.clearAllMocks();
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