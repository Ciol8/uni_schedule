import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/schedule_item.dart';
import '../../notes/models/note.dart';
import '../providers/notes_provider.dart';

class ClassDetailsScreen extends ConsumerWidget {
  final ScheduleItem item;
  final Color heroColor;

  const ClassDetailsScreen({super.key, required this.item, required this.heroColor});

  void _showNoteDialog(BuildContext context, WidgetRef ref, Note? existingNote) {
    final titleController = TextEditingController(text: existingNote?.title ?? '');
    final contentController = TextEditingController(text: existingNote?.content ?? '');
    bool isTask = existingNote?.isTask ?? false;
    int selectedPriority = existingNote?.priority ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingNote == null ? 'Nowy wpis' : 'Edytuj wpis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tytuł (np. Sprawozdanie, Kolokwium)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Treść (opcjonalnie)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('To jest zadanie do wykonania', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: isTask,
                      activeColor: heroColor,
                      onChanged: (val) => setState(() => isTask = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isTask) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedPriority,
                        decoration: const InputDecoration(labelText: 'Priorytet zadania', border: OutlineInputBorder()),
                        items: List.generate(8, (index) => DropdownMenuItem(value: index + 1, child: Text('Priorytet ${index + 1}'))),
                        onChanged: (val) => setState(() => selectedPriority = val!),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: heroColor, foregroundColor: Colors.white),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;

                    final newNote = Note(
                      id: existingNote?.id,
                      subjectId: item.subjectId,
                      title: titleController.text.trim(),
                      content: contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                      isTask: isTask,
                      isCompleted: existingNote?.isCompleted ?? false,
                      priority: isTask ? selectedPriority : 1,
                    );

                    if (existingNote == null) {
                      ref.read(notesProvider(item.subjectId).notifier).addNote(newNote);
                    } else {
                      ref.read(notesProvider(item.subjectId).notifier).updateNote(newNote);
                    }
                    Navigator.pop(context);
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
    final notesAsync = ref.watch(notesProvider(item.subjectId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // --- NOWY PRZYCISK EDYCJI ---
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edytuj zajęcia',
                onPressed: () {
                  // Otwieramy formularz przesyłając mu te zajęcia do edycji!
                  context.push('/add-class', extra: item);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              // ... reszta kodu zostaje bez zmian (title, background, Hero) ...
              title: Text(
                item.subject?.name ?? 'Detale zajęć',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
              ),
              background: Hero(
                tag: 'color_stripe_${item.id}',
                child: Container(
                  color: heroColor,
                  child: Center(child: Icon(Icons.menu_book_rounded, size: 80, color: Colors.white.withValues(alpha: 0.3))),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, color: heroColor),
                      const SizedBox(width: 12),
                      Text('${item.startTime.substring(0, 5)} - ${item.endTime.substring(0, 5)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: heroColor),
                      const SizedBox(width: 12),
                      Text(item.location ?? 'Brak wyznaczonej sali', style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.class_rounded, color: heroColor),
                      const SizedBox(width: 12),
                      Text('Typ zajęć: ${item.classType}', style: const TextStyle(fontSize: 18)),
                    ],
                  ),

                  // --- KLIKALNY LINK DO ZAJĘĆ ---
                  if (item.meetingLink != null && item.meetingLink!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse(item.meetingLink!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nie można otworzyć tego linku.')));
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: heroColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: heroColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.video_call_rounded, color: heroColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dołącz do spotkania', style: TextStyle(fontWeight: FontWeight.bold, color: heroColor)),
                                  Text(item.meetingLink!, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new_rounded, color: heroColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const Divider(height: 48),

                  // --- NAGŁÓWEK NOTATEK ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Zadania i Notatki', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showNoteDialog(context, ref, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- LISTA NOTATEK ---
                  notesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Błąd: $e'),
                    data: (notes) {
                      if (notes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Text('Brak notatek do tego przedmiotu.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true, // Ważne: pozwala liście działać wewnątrz CustomScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: note.isCompleted ? Colors.green.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: note.isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade300),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: note.isTask
                                  ? Checkbox(
                                value: note.isCompleted,
                                activeColor: Colors.green,
                                onChanged: (val) {
                                  final updated = Note(
                                    id: note.id, subjectId: note.subjectId, title: note.title,
                                    content: note.content, isTask: note.isTask, isCompleted: val ?? false, priority: note.priority,
                                  );
                                  ref.read(notesProvider(item.subjectId).notifier).updateNote(updated);
                                },
                              )
                                  : Icon(Icons.sticky_note_2_rounded, color: heroColor),
                              title: Text(
                                note.title,
                                style: TextStyle(fontWeight: FontWeight.bold, decoration: note.isCompleted ? TextDecoration.lineThrough : null),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (note.content != null) Text(note.content!),
                                  if (note.isTask && !note.isCompleted)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text('Priorytet: ${note.priority}/8', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey), onPressed: () => _showNoteDialog(context, ref, note)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                    onPressed: () => ref.read(notesProvider(item.subjectId).notifier).deleteNote(note.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}