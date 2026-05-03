import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/aws_credentials_repository.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';
import 'package:pocket_sync/ui/features/settings/view_models/aws_credentials_view_model.dart';

class _FakeRepository implements AwsCredentialsRepository {
  _FakeRepository({AwsCredentials initial = AwsCredentials.empty})
    : _stored = initial;

  AwsCredentials _stored;
  Exception? saveError;
  Exception? clearError;
  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<AwsCredentials> load() async => _stored;

  @override
  Future<void> save(AwsCredentials creds) async {
    saveCallCount += 1;
    if (saveError != null) throw saveError!;
    _stored = creds;
  }

  @override
  Future<void> clear() async {
    clearCallCount += 1;
    if (clearError != null) throw clearError!;
    _stored = AwsCredentials.empty;
  }
}

const _filled = AwsCredentials(
  accessKeyId: 'AKIA',
  secretAccessKey: 'shhh',
  region: 'ap-northeast-1',
  bucketName: 'pocket-sync',
);

void main() {
  group('AwsCredentialsViewModel bootstrap', () {
    test('初期は isLoading=true、bootstrap 完了で false に', () async {
      final repo = _FakeRepository(initial: _filled);
      final vm = AwsCredentialsViewModel(repository: repo);

      expect(vm.isLoading, isTrue);
      expect(vm.committed, AwsCredentials.empty);

      await Future<void>.delayed(Duration.zero);

      expect(vm.isLoading, isFalse);
      expect(vm.committed, _filled);
      expect(vm.draft, _filled);
    });
  });

  group('AwsCredentialsViewModel draft 編集', () {
    AwsCredentialsViewModel buildVm({
      AwsCredentials initial = AwsCredentials.empty,
    }) {
      return AwsCredentialsViewModel(
        repository: _FakeRepository(initial: initial),
      );
    }

    test('setDraftAccessKeyId は draft だけ変えて committed は据え置き', () async {
      final vm = buildVm();
      await Future<void>.delayed(Duration.zero);

      vm.setDraftAccessKeyId('AKIA');

      expect(vm.draft.accessKeyId, 'AKIA');
      expect(vm.committed, AwsCredentials.empty);
      expect(vm.isDirty, isTrue);
    });

    test('全項目入力した draft は isCompleteDraft=true', () async {
      final vm = buildVm();
      await Future<void>.delayed(Duration.zero);

      vm
        ..setDraftAccessKeyId('AKIA')
        ..setDraftSecretAccessKey('shhh')
        ..setDraftRegion('ap-northeast-1')
        ..setDraftBucketName('pocket-sync');

      expect(vm.isCompleteDraft, isTrue);
    });
  });

  group('AwsCredentialsViewModel save', () {
    test('成功すると committed と draft が saveCandidate に揃う', () async {
      final repo = _FakeRepository();
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);
      vm
        ..setDraftAccessKeyId('AKIA')
        ..setDraftSecretAccessKey('shhh')
        ..setDraftRegion('ap-northeast-1')
        ..setDraftBucketName('pocket-sync');

      await vm.save();

      expect(vm.committed, _filled);
      expect(vm.draft, _filled);
      expect(vm.isDirty, isFalse);
      expect(repo.saveCallCount, 1);
    });

    test('失敗すると committed がロールバックされ rethrow される', () async {
      final repo = _FakeRepository(initial: _filled)
        ..saveError = Exception('boom');
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);
      vm.setDraftRegion('us-east-1');

      await expectLater(
        vm.save(),
        throwsA(isA<Exception>()),
      );
      expect(vm.committed, _filled);
      expect(vm.isSaving, isFalse);
    });

    test('Secret 空の draft で save しても committed.secret が維持される', () async {
      final repo = _FakeRepository(initial: _filled);
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);
      // Region だけ変える（Secret は触らない）
      vm
        ..setDraftSecretAccessKey('')
        ..setDraftRegion('us-east-1');

      await vm.save();

      expect(vm.committed.secretAccessKey, 'shhh');
      expect(vm.committed.region, 'us-east-1');
    });

    test('Secret 空 draft + committed なしなら secret は null', () async {
      final repo = _FakeRepository();
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);
      vm
        ..setDraftAccessKeyId('AKIA')
        ..setDraftRegion('ap-northeast-1')
        ..setDraftBucketName('pocket-sync');
      // Secret は触らない

      await vm.save();

      expect(vm.committed.secretAccessKey, isNull);
      expect(vm.isCompleteDraft, isFalse);
    });

    test('isSaving 中の二重 save は無視される', () async {
      final repo = _FakeRepository();
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);
      vm
        ..setDraftAccessKeyId('AKIA')
        ..setDraftSecretAccessKey('shhh')
        ..setDraftRegion('ap-northeast-1')
        ..setDraftBucketName('pocket-sync');

      final first = vm.save();
      await vm.save(); // 進行中なら no-op
      await first;

      expect(repo.saveCallCount, 1);
    });
  });

  group('AwsCredentialsViewModel clear', () {
    test('成功で 4 項目すべて empty になる', () async {
      final repo = _FakeRepository(initial: _filled);
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);

      await vm.clear();

      expect(vm.committed, AwsCredentials.empty);
      expect(vm.draft, AwsCredentials.empty);
      expect(repo.clearCallCount, 1);
    });

    test('失敗で committed がロールバックされ rethrow', () async {
      final repo = _FakeRepository(initial: _filled)
        ..clearError = Exception('boom');
      final vm = AwsCredentialsViewModel(repository: repo);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        vm.clear(),
        throwsA(isA<Exception>()),
      );
      expect(vm.committed, _filled);
    });
  });
}
