import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój Plan Zajęć'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Wylogowanie użytkownika
              await ref.read(authRepositoryProvider).signOut();
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Tutaj będzie Twój widok kalendarza 📅', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}