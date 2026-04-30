import 'package:pocket_sync/domain/models/counter.dart';

class CounterRepository {
  Counter _counter = const Counter(value: 0);

  Counter get() => _counter;

  Counter increment() =>
      _counter = _counter.copyWith(value: _counter.value + 1);
}
