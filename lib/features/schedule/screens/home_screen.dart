import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../providers/calendar_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/class_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dailyScheduleAsync = ref.watch(scheduleByDateProvider(selectedDay));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twój Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Wyloguj',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDay,
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (newSelectedDay, focusedDay) {
                // Nowy, poprawny sposób na zmianę stanu w Notifierze
                ref.read(selectedDayProvider.notifier).updateDay(newSelectedDay);
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: dailyScheduleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Błąd ładowania: $error')),
data: (items) {
          // --- KROK 1a: PUSTY STAN (Empty State) ---
          if (items.isEmpty) {
            // Używamy RefreshIndicator nawet dla pustego stanu, żeby dało się odświeżyć pusty ekran
            return RefreshIndicator(
              onRefresh: () async {
                // To polecenie zmusza Riverpod do ponownego pobrania danych z bazy Supabase
                ref.invalidate(scheduleProvider); 
              },
              child: SingleChildScrollView(
                // To jest kluczowe: pozwala przewijać (i pociągnąć) pusty ekran!
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.coffee_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Brak zajęć w tym dniu!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pociągnij w dół, aby odświeżyć\nalbo po prostu odpocznij.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // --- KROK 1b: PULL-TO-REFRESH DLA LISTY ZAJĘĆ ---
          // --- KROK 1b & KROK 2: PULL-TO-REFRESH + SWIPE TO DELETE ---
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(scheduleProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                
                // --- DODANY WIDŻET DISMISSIBLE ---
                return Dismissible(
                  key: ValueKey(item.id), // Unikalny klucz dla Fluttera
                  direction: DismissDirection.endToStart, // Przeciąganie od prawej do lewej
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
                  ),
                  confirmDismiss: (direction) async {
                    // Okienko potwierdzenia (żeby nie usunąć przedmiotu przypadkiem)
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Usuwanie zajęć', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text('Czy na pewno chcesz usunąć te zajęcia z przedmiotu ${item.subject?.name ?? "Nieznany"} z planu?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Anuluj'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Usuń na zawsze'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    // Wołamy Twoją gotową funkcję z backendu!
                    ref.read(scheduleProvider.notifier).deleteItem(item.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Zajęcia zostały usunięte z planu.'), 
                        backgroundColor: Colors.black87,
                        behavior: SnackBarBehavior.floating, // Ładniejszy, pływający wygląd powiadomienia
                      ),
                    );
                  },
                  // W środku siedzi nasza karta, bez żadnych zmian
                  child: ClassCard(item: item),
                );
              },
            ),
          );
        },
            ),
          ),
        ],
      ),
      // --- PODMIEŃ FLOATING ACTION BUTTON NA TO ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-class'); // Przejście do formularza
        },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj zajęcia'),
      ),
    );
  }
}