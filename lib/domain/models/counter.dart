class Counter {
  const Counter({required this.value});

  final int value;

  Counter copyWith({int? value}) => Counter(value: value ?? this.value);
}
