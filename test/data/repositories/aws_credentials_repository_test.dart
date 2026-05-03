import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/aws_credentials_repository.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Map<String, String> secureBackingStore;
  late SharedPreferences prefs;
  late AwsCredentialsRepository repo;

  setUp(() async {
    secureBackingStore = <String, String>{};
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      secureBackingStore,
    );
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = AwsCredentialsRepository(
      secureStorage: const FlutterSecureStorage(),
      prefs: prefs,
    );
  });

  group('AwsCredentialsRepository', () {
    test('未保存時の load は empty 相当', () async {
      final creds = await repo.load();

      expect(creds, AwsCredentials.empty);
    });

    test('save → load 往復で 4 項目すべて一致', () async {
      const original = AwsCredentials(
        accessKeyId: 'AKIATEST',
        secretAccessKey: 'shhh',
        region: 'ap-northeast-1',
        bucketName: 'pocket-sync',
      );

      await repo.save(original);
      final loaded = await repo.load();

      expect(loaded, original);
    });

    test('Secret は SharedPreferences に書き込まれない', () async {
      await repo.save(
        const AwsCredentials(
          accessKeyId: 'AKIATEST',
          secretAccessKey: 'shhh',
          region: 'ap-northeast-1',
          bucketName: 'pocket-sync',
        ),
      );

      expect(prefs.getString('aws.access_key_id'), isNull);
      expect(prefs.getString('aws.secret_access_key'), isNull);
      expect(prefs.getString('aws.region'), 'ap-northeast-1');
      expect(prefs.getString('aws.bucket_name'), 'pocket-sync');
    });

    test('Access Key と Secret は secure storage に書き込まれる', () async {
      await repo.save(
        const AwsCredentials(
          accessKeyId: 'AKIATEST',
          secretAccessKey: 'shhh',
          region: 'ap-northeast-1',
          bucketName: 'pocket-sync',
        ),
      );

      expect(secureBackingStore['aws.access_key_id'], 'AKIATEST');
      expect(secureBackingStore['aws.secret_access_key'], 'shhh');
    });

    test('null フィールドは対応キーを削除する', () async {
      await repo.save(
        const AwsCredentials(
          accessKeyId: 'AKIATEST',
          secretAccessKey: 'shhh',
          region: 'ap-northeast-1',
          bucketName: 'pocket-sync',
        ),
      );

      await repo.save(
        const AwsCredentials(
          accessKeyId: 'AKIATEST',
          secretAccessKey: 'shhh',
          // region / bucketName を未設定にする
        ),
      );

      expect(prefs.getString('aws.region'), isNull);
      expect(prefs.getString('aws.bucket_name'), isNull);
      expect(secureBackingStore['aws.access_key_id'], 'AKIATEST');
    });

    test('clear で 4 項目すべて消える', () async {
      await repo.save(
        const AwsCredentials(
          accessKeyId: 'AKIATEST',
          secretAccessKey: 'shhh',
          region: 'ap-northeast-1',
          bucketName: 'pocket-sync',
        ),
      );

      await repo.clear();
      final loaded = await repo.load();

      expect(loaded, AwsCredentials.empty);
      expect(secureBackingStore, isEmpty);
      expect(prefs.getString('aws.region'), isNull);
      expect(prefs.getString('aws.bucket_name'), isNull);
    });

    test('未保存状態の clear はエラーを投げない', () async {
      await expectLater(repo.clear(), completes);
    });
  });
}
