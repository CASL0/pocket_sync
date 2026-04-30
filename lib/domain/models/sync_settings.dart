import 'package:flutter/foundation.dart';

@immutable
class SyncSettings {
  const SyncSettings({
    this.wifiOnly = false,
    this.chargingOnly = false,
    this.backgroundSync = false,
  });

  final bool wifiOnly;
  final bool chargingOnly;
  final bool backgroundSync;

  SyncSettings copyWith({
    bool? wifiOnly,
    bool? chargingOnly,
    bool? backgroundSync,
  }) {
    return SyncSettings(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      chargingOnly: chargingOnly ?? this.chargingOnly,
      backgroundSync: backgroundSync ?? this.backgroundSync,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncSettings &&
        other.wifiOnly == wifiOnly &&
        other.chargingOnly == chargingOnly &&
        other.backgroundSync == backgroundSync;
  }

  @override
  int get hashCode => Object.hash(wifiOnly, chargingOnly, backgroundSync);
}
