import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/schedule_item.dart';

class ClassCard extends StatelessWidget {
  final ScheduleItem item;

  const ClassCard({super.key, required this.item});

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = item.subject?.color != null
        ? _getColorFromHex(item.subject!.color)
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (item.subject != null) {
            context.push('/subject/${item.subjectId}', extra: item.subject);
          }
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 12, color: subjectColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.subject?.name ?? 'Nieznany przedmiot',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.classType,
                              style: TextStyle(color: subjectColor, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${item.startTime.substring(0, 5)} - ${item.endTime.substring(0, 5)}',
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (item.location != null && item.location!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(item.location!, style: const TextStyle(color: Colors.grey)),
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