import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';

void main() {
  group('AwsCredentials', () {
    test('empty は全フィールドが null', () {
      const creds = AwsCredentials.empty;

      expect(creds.accessKeyId, isNull);
      expect(creds.secretAccessKey, isNull);
      expect(creds.region, isNull);
      expect(creds.bucketName, isNull);
    });

    test('全フィールド一致なら ==', () {
      const a = AwsCredentials(
        accessKeyId: 'AKIA123',
        secretAccessKey: 'secret',
        region: 'ap-northeast-1',
        bucketName: 'bucket',
      );
      const b = AwsCredentials(
        accessKeyId: 'AKIA123',
        secretAccessKey: 'secret',
        region: 'ap-northeast-1',
        bucketName: 'bucket',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('1 フィールドでも違えば !=', () {
      const a = AwsCredentials(accessKeyId: 'AKIA1');
      const b = AwsCredentials(accessKeyId: 'AKIA2');

      expect(a, isNot(equals(b)));
    });

    test('copyWith は指定フィールドだけ更新する', () {
      const a = AwsCredentials(
        accessKeyId: 'AKIA',
        secretAccessKey: 'secret',
        region: 'ap-northeast-1',
        bucketName: 'bucket',
      );

      final b = a.copyWith(region: 'us-east-1');

      expect(b.region, 'us-east-1');
      expect(b.accessKeyId, a.accessKeyId);
      expect(b.secretAccessKey, a.secretAccessKey);
      expect(b.bucketName, a.bucketName);
    });
  });

  group('AwsCredentials.isComplete', () {
    AwsCredentials full({
      String? accessKeyId = 'AKIA',
      String? secretAccessKey = 'secret',
      String? region = 'ap-northeast-1',
      String? bucketName = 'bucket',
    }) {
      return AwsCredentials(
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        region: region,
        bucketName: bucketName,
      );
    }

    test('4 項目すべて入力されていれば true', () {
      expect(full().isComplete, isTrue);
    });

    test('empty は false', () {
      expect(AwsCredentials.empty.isComplete, isFalse);
    });

    test('1 項目でも null なら false', () {
      expect(full(accessKeyId: null).isComplete, isFalse);
      expect(full(secretAccessKey: null).isComplete, isFalse);
      expect(full(region: null).isComplete, isFalse);
      expect(full(bucketName: null).isComplete, isFalse);
    });

    test('1 項目でも空文字列なら false', () {
      expect(full(accessKeyId: '').isComplete, isFalse);
      expect(full(secretAccessKey: '').isComplete, isFalse);
    });

    test('空白のみの文字列は false', () {
      expect(full(region: '   ').isComplete, isFalse);
    });
  });
}
