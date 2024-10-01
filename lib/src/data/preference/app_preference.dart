import 'package:shared_preferences/shared_preferences.dart';

class AppPreference {
  SharedPreferences? _preferences;

  // comment below caused already handle by getit
  // static final AppPreference _instance = AppPreference._();
  // factory AppPreference() {
  //   return _instance;
  // }
  // AppPreference._();

  //must be run in runApp
  Future<AppPreference> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> reload() async {
    await _preferences!.reload();
  }

//generic function publicly can be accessed
  String? getString(String key) {
    return _preferences!.getString(key);
  }

  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  bool? getBool(String key) {
    return _preferences!.getBool(key);
  }

  Future<bool> putString(String key, String value) {
    return _preferences!.setString(key, value);
  }

  Future<bool> putInt(String key, int value) {
    return _preferences!.setInt(key, value);
  }

  Future<bool> putBool(String key, bool value) {
    return _preferences!.setBool(key, value);
  }

  Future<bool> clear() async {
    return await _preferences!.clear();
  }

  //specific constanta
  final String _keyIsLoggedin = "key_is_loggedin";
  final String _keyLoginResponse = "key_loginresponse";
  final String _token = "key_token";

  //specific function for managing key value data

  bool get isLoggedIn => getBool(_keyIsLoggedin) ?? false;
  set isLoggedIn(bool value) {
    putBool(_keyIsLoggedin, value);
  }

  Future<bool> setLoggedIn(bool value) {
    return putBool(_keyIsLoggedin, value);
  }

  String get loginResponse => getString(_keyLoginResponse) ?? "";
  set loginResponse(String value) {
    putString(_keyLoginResponse, value);
  }

  Future<bool> setLoginResponse(String value) {
    return putString(_keyLoginResponse, value);
  }

  String get token => getString(_token) ?? "";
  set token(String value) {
    putString(_token, value);
  }

  Future<bool> setToken(String value) {
    return putString(_token, value);
  }
}
