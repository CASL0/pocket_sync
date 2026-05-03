import 'package:flutter/material.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/ui/features/settings/view_models/aws_credentials_view_model.dart';
import 'package:provider/provider.dart';

/// AWS 認証情報入力フォーム。
///
/// 4 項目（Access Key ID / Secret Access Key / Region / Bucket Name）の
/// `TextFormField` と保存・削除ボタンを持つ。
///
/// セキュリティ上の挙動:
/// - Secret は `obscureText: true` 固定、`enableInteractiveSelection: false`
///   でクリップボード経由の漏洩を抑止する。表示トグルなし
/// - 保存済みの Secret は画面に再表示しない（hint だけ）。空のまま
///   保存すると既存の Secret が維持される（ViewModel 側のロジック）
/// - Access Key / Region / Bucket は秘匿不要なので保存済み値を初期表示する
class AwsCredentialsForm extends StatefulWidget {
  const AwsCredentialsForm({super.key});

  @override
  State<AwsCredentialsForm> createState() => _AwsCredentialsFormState();
}

class _AwsCredentialsFormState extends State<AwsCredentialsForm> {
  final _formKey = GlobalKey<FormState>();
  final _accessKeyIdController = TextEditingController();
  final _secretController = TextEditingController();
  final _regionController = TextEditingController();
  final _bucketController = TextEditingController();

  AwsCredentialsViewModel? _vm;
  bool _hasPopulatedFromCommitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newVm = context.read<AwsCredentialsViewModel>();
    if (!identical(_vm, newVm)) {
      _vm?.removeListener(_onVmChange);
      _vm = newVm;
      _vm!.addListener(_onVmChange);
      _onVmChange();
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChange);
    _accessKeyIdController.dispose();
    _secretController.dispose();
    _regionController.dispose();
    _bucketController.dispose();
    super.dispose();
  }

  void _onVmChange() {
    final vm = _vm;
    if (vm == null || vm.isLoading || _hasPopulatedFromCommitted) return;
    _hasPopulatedFromCommitted = true;
    final c = vm.committed;
    _accessKeyIdController.text = c.accessKeyId ?? '';
    _regionController.text = c.region ?? '';
    _bucketController.text = c.bucketName ?? '';
    // Secret は意図的に空のままにする（hint で「保存済み」だけ示す）
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<AwsCredentialsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  l10n.settingsAwsDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _FormField(
                controller: _accessKeyIdController,
                label: l10n.settingsAwsAccessKeyId,
                onChanged: vm.setDraftAccessKeyId,
                validator: (v) => _validateAccessKeyId(l10n, v),
              ),
              _FormField(
                controller: _secretController,
                label: l10n.settingsAwsSecretAccessKey,
                hint: _hasCommittedSecret(vm)
                    ? l10n.settingsAwsSecretPlaceholder
                    : null,
                obscureText: true,
                onChanged: vm.setDraftSecretAccessKey,
                validator: (v) => _validateSecret(l10n, v, vm),
              ),
              _FormField(
                controller: _regionController,
                label: l10n.settingsAwsRegion,
                onChanged: vm.setDraftRegion,
                validator: (v) => _validateRegion(l10n, v),
              ),
              _FormField(
                controller: _bucketController,
                label: l10n.settingsAwsBucketName,
                onChanged: vm.setDraftBucketName,
                validator: (v) => _validateBucket(l10n, v),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: vm.isSaving || !vm.isDirty
                            ? null
                            : () => _onSave(context, vm),
                        child: Text(l10n.settingsAwsSaveButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: vm.isSaving
                            ? null
                            : () => _onClear(context, vm),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                        child: Text(l10n.settingsAwsClearButton),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasCommittedSecret(AwsCredentialsViewModel vm) {
    final secret = vm.committed.secretAccessKey;
    return secret != null && secret.isNotEmpty;
  }

  String? _validateAccessKeyId(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.settingsAwsValidationRequired;
    }
    if (!RegExp(r'^[A-Za-z0-9]{16,}$').hasMatch(value)) {
      return l10n.settingsAwsValidationAccessKeyIdFormat;
    }
    return null;
  }

  String? _validateSecret(
    AppLocalizations l10n,
    String? value,
    AwsCredentialsViewModel vm,
  ) {
    if ((value == null || value.isEmpty) && !_hasCommittedSecret(vm)) {
      return l10n.settingsAwsValidationRequired;
    }
    return null;
  }

  String? _validateRegion(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.settingsAwsValidationRequired;
    }
    if (!RegExp(r'^[a-z]{2}-[a-z]+-\d$').hasMatch(value)) {
      return l10n.settingsAwsValidationRegionFormat;
    }
    return null;
  }

  String? _validateBucket(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.settingsAwsValidationRequired;
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9.\-]{1,61}[a-z0-9]$').hasMatch(value)) {
      return l10n.settingsAwsValidationBucketFormat;
    }
    return null;
  }

  Future<void> _onSave(
    BuildContext context,
    AwsCredentialsViewModel vm,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.save();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsAwsSaveSuccess)),
      );
    } on Exception {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsAwsSaveFailed)),
      );
    }
  }

  Future<void> _onClear(
    BuildContext context,
    AwsCredentialsViewModel vm,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.settingsAwsClearConfirmTitle),
          content: Text(l10n.settingsAwsClearConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.settingsAwsClearConfirmCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: Text(l10n.settingsAwsClearConfirmDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.clear();
      _accessKeyIdController.clear();
      _secretController.clear();
      _regionController.clear();
      _bucketController.clear();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsAwsClearSuccess)),
      );
    } on Exception {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsAwsClearFailed)),
      );
    }
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.validator,
    this.hint,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        obscureText: obscureText,
        enableInteractiveSelection: !obscureText,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
