import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocket_sync/data/repositories/aws_credentials_repository.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';

/// Settings 画面の AWS 認証情報セクションを駆動する ViewModel。
///
/// 状態は二段階で持つ:
/// - `committed`: Repository から最後に load / save した永続値
/// - `draft`: フォーム編集中の値。Save するまで永続化されない
///
/// 楽観的更新パターン（[ADR-0003](../../../../../../docs/adr/0003-state-management-with-provider.md)）に
/// 従い、save 失敗時は `committed` をロールバックして再 notify + rethrow する。
class AwsCredentialsViewModel extends ChangeNotifier {
  AwsCredentialsViewModel({
    required AwsCredentialsRepository repository,
  }) : _repository = repository {
    unawaited(_bootstrap());
  }

  final AwsCredentialsRepository _repository;

  AwsCredentials _committed = AwsCredentials.empty;
  AwsCredentials _draft = AwsCredentials.empty;
  bool _isLoading = true;
  bool _isSaving = false;

  AwsCredentials get committed => _committed;
  AwsCredentials get draft => _draft;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  /// `save()` を呼んだ時に永続化される予定値。Secret は draft が空白なら
  /// `committed` の値を維持する（Region だけ変えて保存しても Secret が
  /// 消えないようにするための UX 上の特例）。他のフィールドは draft 通り。
  AwsCredentials get saveCandidate => _saveCandidate();

  /// フォームが永続化値と異なる状態か。Save ボタンの活性判定に使う。
  bool get isDirty => saveCandidate != _committed;

  /// Save によって 4 項目すべてが揃う状態になるか。
  bool get isCompleteDraft => saveCandidate.isComplete;

  void setDraftAccessKeyId(String value) {
    _updateDraft(
      AwsCredentials(
        accessKeyId: value,
        secretAccessKey: _draft.secretAccessKey,
        region: _draft.region,
        bucketName: _draft.bucketName,
      ),
    );
  }

  void setDraftSecretAccessKey(String value) {
    _updateDraft(
      AwsCredentials(
        accessKeyId: _draft.accessKeyId,
        secretAccessKey: value,
        region: _draft.region,
        bucketName: _draft.bucketName,
      ),
    );
  }

  void setDraftRegion(String value) {
    _updateDraft(
      AwsCredentials(
        accessKeyId: _draft.accessKeyId,
        secretAccessKey: _draft.secretAccessKey,
        region: value,
        bucketName: _draft.bucketName,
      ),
    );
  }

  void setDraftBucketName(String value) {
    _updateDraft(
      AwsCredentials(
        accessKeyId: _draft.accessKeyId,
        secretAccessKey: _draft.secretAccessKey,
        region: _draft.region,
        bucketName: value,
      ),
    );
  }

  /// draft を永続化する。失敗時は committed をロールバックして rethrow。
  Future<void> save() async {
    if (_isSaving) return;
    final candidate = _saveCandidate();
    final previous = _committed;
    _committed = candidate;
    _draft = candidate;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.save(candidate);
    } catch (_) {
      _committed = previous;
      _draft = previous;
      _isSaving = false;
      notifyListeners();
      rethrow;
    }
    _isSaving = false;
    notifyListeners();
  }

  /// 4 項目をすべて削除する。失敗時はロールバックして rethrow。
  Future<void> clear() async {
    if (_isSaving) return;
    final previous = _committed;
    _committed = AwsCredentials.empty;
    _draft = AwsCredentials.empty;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.clear();
    } catch (_) {
      _committed = previous;
      _draft = previous;
      _isSaving = false;
      notifyListeners();
      rethrow;
    }
    _isSaving = false;
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    final loaded = await _repository.load();
    _committed = loaded;
    _draft = loaded;
    _isLoading = false;
    notifyListeners();
  }

  void _updateDraft(AwsCredentials next) {
    if (next == _draft) return;
    _draft = next;
    notifyListeners();
  }

  AwsCredentials _saveCandidate() {
    String? norm(String? value) =>
        value == null || value.isEmpty ? null : value;
    return AwsCredentials(
      accessKeyId: norm(_draft.accessKeyId),
      secretAccessKey:
          norm(_draft.secretAccessKey) ?? _committed.secretAccessKey,
      region: norm(_draft.region),
      bucketName: norm(_draft.bucketName),
    );
  }
}
