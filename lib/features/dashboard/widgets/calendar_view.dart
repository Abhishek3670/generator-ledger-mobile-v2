import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/calendar_event.dart';

/// Monthly calendar view displaying confirmed bookings and counts per day.
class CalendarView extends StatefulWidget {
  /// The currently selected day.
  final DateTime selectedDay;

  /// The currently focused day.
  final DateTime focusedDay;

  /// Callback triggered when a new day is selected.
  final ValueChanged<DateTime> onDaySelected;

  /// The list of events to display on the calendar.
  final List<CalendarEvent> events;

  /// Creates a [CalendarView].
  const CalendarView({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.events,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
  }

  int _getBookingCountForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final event = widget.events.firstWhere(
      (e) => e.date == dateStr,
      orElse: () => CalendarEvent(date: '', count: 0, title: ''),
    );
    return event.count;
  }

  int _daysInMonth(DateTime date) {
    var firstDayOfNextMonth = (date.month < 12)
        ? DateTime(date.year, date.month + 1, 1)
        : DateTime(date.year + 1, 1, 1);
    return firstDayOfNextMonth.difference(DateTime(date.year, date.month, 1)).inDays;
  }

  int _firstWeekdayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return firstDay.weekday % 7; // Sunday = 0, Monday = 1, etc.
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_focusedDay);
    final firstWeekday = _firstWeekdayOfMonth(_focusedDay);
    final totalCells = daysInMonth + firstWeekday;
    final numWeeks = (totalCells / 7).ceil();

    final prevMonth = _focusedDay.month == 1
        ? DateTime(_focusedDay.year - 1, 12, 1)
        : DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final daysInPrevMonth = _daysInMonth(prevMonth);

    final weekdayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: AppColors.shadowSoft,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [


          // 2. Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_left, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_right, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () {
                        final now = DateTime.now();
                        setState(() {
                          _focusedDay = now;
                        });
                        widget.onDaySelected(now);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'today',
                        style: AppTypography.labelCaps.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 3. Bordered Grid
          Container(
            color: AppColors.border,
            child: Column(
              children: [
                // Day Headers Row
                Row(
                  children: weekdayHeaders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final header = entry.value;
                    return Expanded(
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: const BorderSide(color: AppColors.border, width: 1),
                            right: index < 6
                                ? const BorderSide(color: AppColors.border, width: 1)
                                : BorderSide.none,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          header,
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Days Grid Rows
                ...List.generate(numWeeks, (weekIndex) {
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: List.generate(7, (dayIndex) {
                        final cellIndex = weekIndex * 7 + dayIndex;
                        final isCurrentMonth = cellIndex >= firstWeekday &&
                            cellIndex < firstWeekday + daysInMonth;

                        if (!isCurrentMonth) {
                          // Day from previous or next month
                          final isPrevMonth = cellIndex < firstWeekday;
                          final displayDay = isPrevMonth
                              ? daysInPrevMonth - (firstWeekday - cellIndex) + 1
                              : cellIndex - (firstWeekday + daysInMonth) + 1;

                          return Expanded(
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.surface, // bg-surface-light / container-low
                                border: Border(
                                  right: dayIndex < 6
                                      ? const BorderSide(color: AppColors.border, width: 1)
                                      : BorderSide.none,
                                ),
                              ),
                              padding: const EdgeInsets.all(4.0),
                              alignment: Alignment.topRight,
                              child: Text(
                                '$displayDay',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          );
                        }

                        // Day from current month
                        final dayNumber = cellIndex - firstWeekday + 1;
                        final cellDate = DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
                        final isSelected = cellDate.year == widget.selectedDay.year &&
                            cellDate.month == widget.selectedDay.month &&
                            cellDate.day == widget.selectedDay.day;

                        final bookingCount = _getBookingCountForDay(cellDate);

                        return Expanded(
                          child: InkWell(
                            onTap: () => widget.onDaySelected(cellDate),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.tertiaryFixed.withValues(alpha: 0.15)
                                    : Colors.white,
                                border: Border(
                                  right: dayIndex < 6
                                      ? const BorderSide(color: AppColors.border, width: 1)
                                      : BorderSide.none,
                                ),
                              ),
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.onTertiaryFixed
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (bookingCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$bookingCount bk',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.labelCaps.copyWith(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
