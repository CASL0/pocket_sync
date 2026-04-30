import 'package:flutter/foundation.dart';
import 'package:pocket_sync/data/repositories/counter_repository.dart';
import 'package:pocket_sync/domain/models/counter.dart';

class CounterViewModel extends ChangeNotifier {
  CounterViewModel({required CounterRepository counterRepository})
    : _counterRepository = counterRepository,
      _counter = counterRepository.get();

  final CounterRepository _counterRepository;
  Counter _counter;

  int get count => _counter.value;

  void increment() {
    _counter = _counterRepository.increment();
    notifyListeners();
  }
}
