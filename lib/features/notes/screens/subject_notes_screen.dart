import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/models/subject.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class SubjectNotesScreen extends ConsumerWidget {
  final String subjectId;
  final Subject subject;

  const SubjectNotesScreen({
    super.key,
    required this.subjectId,
    required this.subject,
  });

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isTask = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nowy wpis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tytuł (np. Projekt zaliczeniowy)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Treść (opcjonalnie)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Zadanie do zrobienia?'),
                      value: isTask,
                      onChanged: (val) => setState(() => isTask = val),
                      activeColor: _getColorFromHex(subject.color),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _getColorFromHex(subject.color), foregroundColor: Colors.white),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      final newNote = Note(
                        subjectId: subjectId,
                        title: titleController.text.trim(),
                        content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                        isTask: isTask,
                      );

                      // Wołamy nowy kontroler do zapisu
                      ref.read(notesControllerProvider).addNote(subjectId, newNote);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectColor = _getColorFromHex(subject.color);
    final notesAsync = ref.watch(notesProvider(subjectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: subjectColor.withValues(alpha: 0.1),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Błąd: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('Brak notatek. Dodaj coś ważnego!', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 80),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: note.isCompleted ? Colors.green.withValues(alpha: 0.5) : Colors.transparent, width: 2),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: note.isTask
                      ? Checkbox(
                    value: note.isCompleted,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      // Wołamy nowy kontroler do odhaczenia zadania
                      ref.read(notesControllerProvider).toggleTask(subjectId, note.id!, val!);
                    },
                  )
                      : Icon(Icons.sticky_note_2_outlined, color: subjectColor, size: 30),
                  title: Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: note.isCompleted ? TextDecoration.lineThrough : null,
                      color: note.isCompleted ? Colors.grey : null,
                    ),
                  ),
                  subtitle: note.content != null
                      ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(note.content!),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: subjectColor,
        foregroundColor: Colors.white,
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}