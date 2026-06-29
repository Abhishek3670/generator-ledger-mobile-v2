import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';

/// Monthly calendar view displaying confirmed bookings and counts per day.
class CalendarView extends StatefulWidget {
  /// The currently selected day.
  final DateTime selectedDay;

  /// The currently focused day.
  final DateTime focusedDay;

  /// Callback triggered when a new day is selected.
  final ValueChanged<DateTime> onDaySelected;

  /// The list of mock bookings to display on the calendar.
  final List<MockBooking> bookings;

  /// Creates a [CalendarView].
  const CalendarView({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.bookings,
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

  List<MockBooking> _getBookingsForDay(DateTime day) {
    return widget.bookings.where((b) {
      return b.date.year == day.year &&
          b.date.month == day.month &&
          b.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Color(0x0D0F172A),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALENDAR',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vendor Bookings',
                      style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                    splashRadius: 20,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                    splashRadius: 20,
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      setState(() {
                        _focusedDay = now;
                      });
                      widget.onDaySelected(now);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Text(
                      'TODAY',
                      style: AppTypography.labelCaps.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month Name
          Center(
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Calendar Grid
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              widget.onDaySelected(selectedDay);
            },
            headerVisible: false,
            calendarFormat: CalendarFormat.month,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 11),
              weekendStyle: AppTypography.labelCaps.copyWith(color: AppColors.danger, fontSize: 11),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              selectedTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              defaultTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
              weekendTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
              outsideDaysVisible: false,
            ),
            eventLoader: _getBookingsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                    ),
                    child: Text(
                      '${events.length}',
                      style: AppTypography.labelCaps.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0,
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
