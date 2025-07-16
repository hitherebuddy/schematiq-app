import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/forecast_model.dart';
import 'package:schematiq/providers/plan_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class PowerModeScreen extends ConsumerStatefulWidget {
  final String planId;
  const PowerModeScreen({super.key, required this.planId});

  @override
  ConsumerState<PowerModeScreen> createState() => _PowerModeScreenState();
}

class _PowerModeScreenState extends ConsumerState<PowerModeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ForecastEvent> _selectedEvents = [];

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // Update the list of events for the newly selected day
        final events = ref.read(forecastProvider(widget.planId)).value ?? [];
        _selectedEvents = _getEventsForDay(selectedDay, events);
      });
    }
  }

  List<ForecastEvent> _getEventsForDay(DateTime day, List<ForecastEvent> allEvents) {
    return allEvents.where((event) {
      return day.isAfter(event.startDate.subtract(const Duration(days: 1))) &&
             day.isBefore(event.endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Color _getEffortColor(String effort) {
    switch (effort.toLowerCase()) {
      case 'high':
        return AppColors.accent;
      case 'medium':
        return AppColors.primary;
      case 'low':
        return AppColors.primary.withOpacity(0.5);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecastAsync = ref.watch(forecastProvider(widget.planId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Execution Forecast'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.2), AppColors.background],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: forecastAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (err, stack) => Center(child: Text('Error loading forecast: $err')),
        data: (events) {
          return Column(
            children: [
              TableCalendar<ForecastEvent>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                eventLoader: (day) => _getEventsForDay(day, events),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markerDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final isMilestone = events.any((e) => (e as ForecastEvent).isMilestone);
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getEffortColor((events.first as ForecastEvent).effort).withOpacity(0.8),
                            ),
                          ),
                          if (isMilestone)
                            const Icon(Icons.star_rounded, color: Colors.yellowAccent, size: 14),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Divider(color: Colors.white24),
              ),
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text('Select a day to see events'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = _selectedEvents[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(left: BorderSide(color: _getEffortColor(event.effort), width: 4)),
                            ),
                            child: Row(
                              children: [
                                if (event.isMilestone)
                                  const Icon(Icons.star_rounded, color: Colors.yellowAccent, size: 18),
                                if (event.isMilestone) const SizedBox(width: 8),
                                Expanded(child: Text(event.stepTitle)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}