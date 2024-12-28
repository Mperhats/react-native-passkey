const Platform = {
  _OS: 'ios',
  _Version: '15.0',
  get OS() { return this._OS; },
  set OS(value: string) { this._OS = value; },
  get Version() { return this._Version; },
  set Version(value: string ) { this._Version = value; },
  select: jest.fn((obj) => obj.ios)
};

export { Platform };
export default {
  Platform
}; 