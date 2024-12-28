import { Platform } from 'react-native';
import { Passkey } from '../Passkey';
import AuthRequest from './data/AuthRequest.json';
import RegRequest from './data/RegRequest.json';
import AuthAndroidResult from './data/AuthAndroidResult.json';
import RegAndroidResult from './data/RegAndroidResult.json';
import ExpoPasskeysModule from '../ExpoPasskeysModule';

jest.mock('../ExpoPasskeysModule', () => ({
  create: jest.fn(),
  get: jest.fn(),
}));

describe('Passkey Module - Android', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Platform.OS = 'android';
    Platform.Version = '33';
    ExpoPasskeysModule.create.mockResolvedValue(RegAndroidResult);
    ExpoPasskeysModule.get.mockResolvedValue(AuthAndroidResult);
  });

  it('should return unsupported for Android Versions below 28', () => {
    Platform.Version = '26';
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