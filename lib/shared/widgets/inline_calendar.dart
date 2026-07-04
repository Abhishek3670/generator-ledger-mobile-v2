import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A custom inline calendar widget supporting range selection and styling matching the design system.
class InlineCalendar extends StatefulWidget {
  /// The currently selected start date.
  final DateTime? startDate;

  /// The currently selected end date.
  final DateTime? endDate;

  /// Callback triggered when the selected date range changes.
  final Function(DateTime? start, DateTime? end) onRangeSelected;

  /// Creates an [InlineCalendar].
  const InlineCalendar({
    super.key,
    this.startDate,
    this.endDate,
    required this.onRangeSelected,
  });

  @override
  State<InlineCalendar> createState() => _InlineCalendarState();
}

class _InlineCalendarState extends State<InlineCalendar> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    // Default to start date month, or current date month
    _focusedMonth = widget.startDate ?? DateTime.now();
  }

  // Weekday names
  static const List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  // Month names
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Helper to generate the list of days to display in the grid (always 42 days, i.e., 6 weeks)
  List<DateTime> _generateCalendarDays() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    
    // Find the previous Sunday to start the calendar grid
    int daysBefore = firstDayOfMonth.weekday % 7; // Sunday is 0/7, Monday is 1, etc.
    final startDate = firstDayOfMonth.subtract(Duration(days: daysBefore));

    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  void _onDayTapped(DateTime day) {
    // Reset range or select start/end
    if (widget.startDate == null || (widget.startDate != null && widget.endDate != null)) {
      widget.onRangeSelected(day, null);
    } else {
      if (day.isBefore(widget.startDate!)) {
        widget.onRangeSelected(day, null);
      } else {
        widget.onRangeSelected(widget.startDate, day);
      }
    }
  }

  bool _isDateSelected(DateTime day) {
    if (widget.startDate == null) return false;
    
    // Check if matching start or end date
    final startMatches = _isSameDay(day, widget.startDate!);
    final endMatches = widget.endDate != null && _isSameDay(day, widget.endDate!);
    
    return startMatches || endMatches;
  }

  bool _isDateInRange(DateTime day) {
    if (widget.startDate == null || widget.endDate == null) return false;
    
    final midnightDay = DateTime(day.year, day.month, day.day);
    final midnightStart = DateTime(widget.startDate!.year, widget.startDate!.month, widget.startDate!.day);
    final midnightEnd = DateTime(widget.endDate!.year, widget.endDate!.month, widget.endDate!.day);
    
    return midnightDay.isAfter(midnightStart) && midnightDay.isBefore(midnightEnd);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateCalendarDays();
    final monthName = _months[_focusedMonth.month - 1];

    return Container(
      height: 310,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
              Text(
                '$monthName ${_focusedMonth.year}',
                style: AppTypography.bodyMedium.copyWith(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday headers Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays.map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == _focusedMonth.month;
                final isSelected = _isDateSelected(day);
                final isInRange = _isDateInRange(day);
                final isToday = _isSameDay(day, DateTime.now());

                // Styling determination
                Color textColor = AppColors.primary;
                if (!isCurrentMonth) {
                  textColor = AppColors.border; // Grayed out
                } else if (isSelected) {
                  textColor = Colors.white;
                } else if (isInRange) {
                  textColor = AppColors.primary;
                }

                BoxDecoration? cellDecoration;
                if (isSelected) {
                  cellDecoration = const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  );
                } else if (isInRange) {
                  cellDecoration = BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(4),
                  );
                } else if (isToday) {
                  cellDecoration = BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 1.5),
                    shape: BoxShape.circle,
                  );
                }

                return GestureDetector(
                  onTap: () => _onDayTapped(day),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: cellDecoration,
                    child: Text(
                      '${day.day}',
                      style: AppTypography.bodySmall.copyWith(
                        color: textColor,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
