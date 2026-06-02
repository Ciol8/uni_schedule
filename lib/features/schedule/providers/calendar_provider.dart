import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDayProvider = NotifierProvider(
  SelectedDayNotifier.new,
);

class SelectedDayNotifier extends Notifier {
  @override
  DateTime build() => DateTime.now();

  void updateDay(DateTime newDay) {
    state = newDay;
  }
}