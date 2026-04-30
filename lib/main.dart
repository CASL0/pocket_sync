import 'package:flutter/material.dart';
import 'package:pocket_sync/data/repositories/counter_repository.dart';
import 'package:pocket_sync/ui/features/counter/view_models/counter_view_model.dart';
import 'package:pocket_sync/ui/features/counter/views/counter_view.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => CounterRepository()),
        ChangeNotifierProxyProvider<CounterRepository, CounterViewModel>(
          create: (context) => CounterViewModel(
            counterRepository: context.read<CounterRepository>(),
          ),
          update: (context, repo, previous) =>
              previous ?? CounterViewModel(counterRepository: repo),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: Builder(
          builder: (context) => CounterView(
            viewModel: context.watch<CounterViewModel>(),
          ),
        ),
      ),
    );
  }
}
