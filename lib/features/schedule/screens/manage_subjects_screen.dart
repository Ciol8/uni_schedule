import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subject.dart';
import '../providers/subjects_provider.dart';

class ManageSubjectsScreen extends ConsumerWidget {
  const ManageSubjectsScreen({super.key});

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  void _showEditSubjectDialog(BuildContext context, WidgetRef ref, Subject? subject) {
    final nameController = TextEditingController(text: subject?.name ?? '');
    String selectedColor = subject?.color ?? '#070291';

    // Fajna paleta kolorów do wyboru dla przedmiotów
    final List<String> availableColors = [
      '#070291', '#D32F2F', '#388E3C', '#FBC02D',
      '#8E24AA', '#E64A19', '#0288D1', '#00796B',
      '#C2185B', '#455A64', '#5D4037', '#689F38'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(subject == null ? 'Nowy przedmiot' : 'Edytuj przedmiot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nazwa przedmiotu', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Kolor przedmiotu:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColors.map((hex) {
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = hex),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorFromHex(hex),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black87, width: 3) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final newSubject = Subject(
                        id: subject?.id,
                        name: nameController.text.trim(),
                        color: selectedColor,
                      );

                      if (subject == null) {
                        await ref.read(subjectsProvider.notifier).addSubject(newSubject);
                      } else {
                        await ref.read(subjectsProvider.notifier).updateSubject(newSubject);
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzaj przedmiotami'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showEditSubjectDialog(context, ref, null),
          ),
        ],
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(child: Text('Brak przedmiotów w bazie.'));
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorFromHex(subject.color),
                  child: const Icon(Icons.book, color: Colors.white, size: 20),
                ),
                title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.grey),
                      onPressed: () => _showEditSubjectDialog(context, ref, subject),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Usunąć przedmiot?'),
                            content: const Text('UWAGA! Usunięcie przedmiotu automatycznie usunie WSZYSTKIE przypisane do niego zajęcia z Twojego planu. Tej operacji nie można cofnąć.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Usuń bezpowrotnie'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && subject.id != null) {
                          ref.read(subjectsProvider.notifier).deleteSubject(subject.id!);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}