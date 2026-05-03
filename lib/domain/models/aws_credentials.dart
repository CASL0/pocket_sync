import 'package:flutter/foundation.dart';

/// S3 にアクセスするための AWS 認証情報。
///
/// 4 つのフィールドはいずれも `null` の状態（未入力）を許容する。
/// 「未入力」と「空文字列」は明確に区別したいため、未設定時に
/// `null` を採用し、`empty` ファクトリで全 `null` の初期状態を表す。
///
/// セキュリティ上の理由で `toString` をオーバーライドしない。
/// デフォルトの `Instance of 'AwsCredentials'` のまま、Secret が
/// `print` 経由で漏れる経路を作らない（ADR-0007 / security.md）。
@immutable
class AwsCredentials {
  const AwsCredentials({
    this.accessKeyId,
    this.secretAccessKey,
    this.region,
    this.bucketName,
  });

  /// 全フィールドが未設定の状態を表す定数。
  static const empty = AwsCredentials();

  final String? accessKeyId;
  final String? secretAccessKey;
  final String? region;
  final String? bucketName;

  /// 4 項目すべてが non-null かつトリム後に非空のとき `true`。
  /// S3 への接続に必要な情報が揃っているかを判定する。
  bool get isComplete {
    return _isFilled(accessKeyId) &&
        _isFilled(secretAccessKey) &&
        _isFilled(region) &&
        _isFilled(bucketName);
  }

  AwsCredentials copyWith({
    String? accessKeyId,
    String? secretAccessKey,
    String? region,
    String? bucketName,
  }) {
    return AwsCredentials(
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      region: region ?? this.region,
      bucketName: bucketName ?? this.bucketName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AwsCredentials &&
        other.accessKeyId == accessKeyId &&
        other.secretAccessKey == secretAccessKey &&
        other.region == region &&
        other.bucketName == bucketName;
  }

  @override
  int get hashCode =>
      Object.hash(accessKeyId, secretAccessKey, region, bucketName);

  static bool _isFilled(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
