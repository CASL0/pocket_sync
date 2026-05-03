import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AWS 認証情報を OS の Keychain (iOS) / Keystore-backed cipher (Android) と
/// SharedPreferences に振り分けて永続化する Repository。
///
/// 振り分けの理由（ADR-0007 / security.md MASVS-STORAGE）:
/// - `accessKeyId` / `secretAccessKey` は秘匿情報なので
///   `flutter_secure_storage` 経由で OS のセキュアストレージへ。
///   iOS は `KeychainAccessibility.first_unlock_this_device` を
///   呼び出し側から指定してもらい iCloud バックアップから除外する。
/// - `region` / `bucketName` は秘匿不要なので `SharedPreferences` で十分。
///   AndroidManifest 側で `allowBackup="false"` にしているため、
///   平文保存でもバックアップ漏洩経路はない。
class AwsCredentialsRepository {
  AwsCredentialsRepository({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  }) : _secure = secureStorage,
       _prefs = prefs;

  static const _keyAccessKeyId = 'aws.access_key_id';
  static const _keySecretAccessKey = 'aws.secret_access_key';
  static const _keyRegion = 'aws.region';
  static const _keyBucket = 'aws.bucket_name';

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  /// 4 項目をまとめて読み込む。未保存の項目は `null` で返る。
  Future<AwsCredentials> load() async {
    final accessKeyId = await _secure.read(key: _keyAccessKeyId);
    final secret = await _secure.read(key: _keySecretAccessKey);
    final region = _prefs.getString(_keyRegion);
    final bucket = _prefs.getString(_keyBucket);
    return AwsCredentials(
      accessKeyId: accessKeyId,
      secretAccessKey: secret,
      region: region,
      bucketName: bucket,
    );
  }

  /// 4 項目をまとめて保存する。
  ///
  /// `null` のフィールドは対応するキーを削除する。書き込み順は
  /// secure → prefs の逐次 await。並列化しないのは部分書き込み失敗時
  /// の状態を予測可能に保つため（先に secure を埋めた段階で例外が出ても、
  /// 次回 load 時に部分情報が読み出せる UX を維持できる）。
  Future<void> save(AwsCredentials creds) async {
    await _writeOrDeleteSecure(_keyAccessKeyId, creds.accessKeyId);
    await _writeOrDeleteSecure(_keySecretAccessKey, creds.secretAccessKey);
    await _writeOrDeletePrefs(_keyRegion, creds.region);
    await _writeOrDeletePrefs(_keyBucket, creds.bucketName);
  }

  /// 4 項目すべて削除する。secure_storage の delete はキーが存在しない
  /// 場合でも例外を投げない（パッケージ仕様）ので、未保存状態でも安全。
  Future<void> clear() async {
    await _secure.delete(key: _keyAccessKeyId);
    await _secure.delete(key: _keySecretAccessKey);
    await _prefs.remove(_keyRegion);
    await _prefs.remove(_keyBucket);
  }

  Future<void> _writeOrDeleteSecure(String key, String? value) async {
    if (value == null) {
      await _secure.delete(key: key);
    } else {
      await _secure.write(key: key, value: value);
    }
  }

  Future<void> _writeOrDeletePrefs(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }
}
