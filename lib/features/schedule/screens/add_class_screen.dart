import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/schedule_item.dart';
import '../models/subject.dart';
import '../providers/schedule_provider.dart';
import '../providers/subjects_provider.dart';

class AddClassScreen extends ConsumerStatefulWidget {
  const AddClassScreen({super.key});

  @override
  ConsumerState<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends ConsumerState<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSubjectId;
  String _selectedClassType = 'Wykład';
  int _selectedDay = 1;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // --- NOWA ZMIENNA DLA POWIADOMIEŃ ---
  int _reminderOffset = 15;

  final _locationController = TextEditingController();
  final _linkController = TextEditingController();

  final List<String> _classTypes = ['Wykład', 'Laboratoria', 'Ćwiczenia', 'Seminarium', 'Inne'];
  final List<String> _daysOfWeek = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];

  // --- OPCJE CZASOWE DO WYBORU ---
  final List<int> _reminderOptions = [0, 5, 10, 15, 30, 60, 120];

  @override
  void dispose() {
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 9, minute: 30)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    String selectedColor = '#070291';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowy przedmiot'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nazwa przedmiotu', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final newSubject = Subject(name: nameController.text.trim(), color: selectedColor);
                await ref.read(subjectsProvider.notifier).addSubject(newSubject);
                if (context.mounted) context.pop();
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate() || _selectedSubjectId == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij wszystkie wymagane pola i godziny!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final newItem = ScheduleItem(
      subjectId: _selectedSubjectId!,
      classType: _selectedClassType,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      meetingLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      dayOfWeek: _selectedDay,
      startTime: _formatTimeOfDay(_startTime!),
      endTime: _formatTimeOfDay(_endTime!),
      reminderOffset: _reminderOffset, // <-- TERAZ PRZEKAZUJEMY WYBRANY CZAS DO BAZY
    );

    try {
      await ref.read(scheduleProvider.notifier).addScheduleItem(newItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zajęcia dodane pomyślnie!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd zapisu: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj nowe zajęcia')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Row(
                children: [
                  Expanded(
                    child: subjectsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Błąd przedmiotów: $e'),
                      data: (subjects) => DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: const InputDecoration(labelText: 'Wybierz przedmiot *', border: OutlineInputBorder()),
                        items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) => setState(() => _selectedSubjectId = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddSubjectDialog,
                    tooltip: 'Stwórz nowy przedmiot',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _selectedClassType,
                decoration: const InputDecoration(labelText: 'Typ zajęć *', border: OutlineInputBorder()),
                items: _classTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedClassType = val!),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(labelText: 'Dzień tygodnia *', border: OutlineInputBorder()),
                items: List.generate(7, (index) => DropdownMenuItem(value: index + 1, child: Text(_daysOfWeek[index]))),
                onChanged: (val) => setState(() => _selectedDay = val!),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: const Icon(Icons.access_time),
                      label: Text(_startTime == null ? 'Od *' : _startTime!.format(context)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.access_time_filled),
                      label: Text(_endTime == null ? 'Do *' : _endTime!.format(context)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- NOWY DROPDOWN OD POWIADOMIEŃ ---
              DropdownButtonFormField<int>(
                value: _reminderOffset,
                decoration: const InputDecoration(
                  labelText: 'Przypomnienie przed zajęciami',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notifications_active_rounded),
                ),
                items: _reminderOptions.map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val == 0 ? 'W momencie rozpoczęcia' : '$val minut przed'),
                )).toList(),
                onChanged: (val) => setState(() => _reminderOffset = val!),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Sala / Budynek', prefixIcon: Icon(Icons.location_on_rounded), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'Link do zajęć (np. MS Teams)', prefixIcon: Icon(Icons.link_rounded), border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                child: const Text('Zapisz w planie zajęć', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}