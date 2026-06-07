import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/schedule_item.dart';

class ClassCard extends StatelessWidget {
  final ScheduleItem item;
  final DateTime selectedDate;

  const ClassCard({super.key, required this.item, required this.selectedDate});

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final isCancelled = item.cancelledDates.contains(dateStr);

    final subjectColor = item.subject?.color != null
        ? _getColorFromHex(item.subject!.color)
        : Theme.of(context).colorScheme.primary;

    final displayColor = isCancelled ? Colors.grey : subjectColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isCancelled ? 0 : 2,
      color: isCancelled ? Colors.grey.shade100 : null,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCancelled ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // ZMIANA: Przechodzimy do nowego ekranu detali, przekazując całe zajęcia
          context.push('/class-details', extra: {'item': item, 'color': displayColor});
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ZMIANA: Widget Hero, który jest kluczem do animacji!
              Hero(
                tag: 'color_stripe_${item.id}',
                child: Container(width: 12, color: displayColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.subject?.name ?? 'Nieznany przedmiot',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isCancelled ? Colors.grey : null,
                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCancelled)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                              child: const Text('Odwołane', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: displayColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(item.classType, style: TextStyle(color: displayColor, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 16, color: isCancelled ? Colors.grey.shade400 : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${item.startTime.substring(0, 5)} - ${item.endTime.substring(0, 5)}',
                            style: TextStyle(
                              color: isCancelled ? Colors.grey.shade400 : Colors.grey,
                              fontWeight: FontWeight.w500,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (item.location != null && item.location!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 16, color: isCancelled ? Colors.grey.shade400 : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                                item.location!,
                                style: TextStyle(
                                  color: isCancelled ? Colors.grey.shade400 : Colors.grey,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                )
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}