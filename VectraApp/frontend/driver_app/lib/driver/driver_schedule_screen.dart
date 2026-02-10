import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_colors.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Time slots
  final List<String> _timeSlots = [
    '06:00 - 09:00',
    '09:00 - 12:00',
    '12:00 - 15:00',
    '15:00 - 18:00',
    '18:00 - 21:00',
    '21:00 - 00:00',
  ];
  
  // Selected time slots for each day
  final Map<DateTime, Set<String>> _selectedSlots = {};
  
  // Recurring schedule
  bool _isRecurring = false;
  final Set<int> _recurringDays = {}; // 1=Monday, 7=Sunday

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _toggleTimeSlot(String slot) {
    if (_selectedDay == null) return;
    
    final dayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    
    setState(() {
      if (_selectedSlots[dayKey] == null) {
        _selectedSlots[dayKey] = {};
      }
      
      if (_selectedSlots[dayKey]!.contains(slot)) {
        _selectedSlots[dayKey]!.remove(slot);
      } else {
        _selectedSlots[dayKey]!.add(slot);
      }
    });
  }

  void _applyRecurringSchedule() {
    if (_recurringDays.isEmpty || _selectedSlots[_selectedDay] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select days and time slots first'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    
    // Apply schedule to next 4 weeks
    final slots = _selectedSlots[_selectedDay]!;
    final startDate = DateTime.now();
    
    for (int i = 0; i < 28; i++) {
      final date = startDate.add(Duration(days: i));
      if (_recurringDays.contains(date.weekday)) {
        final dayKey = DateTime(date.year, date.month, date.day);
        _selectedSlots[dayKey] = Set.from(slots);
      }
    }
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recurring schedule applied for next 4 weeks!'),
        backgroundColor: AppColors.hyperLime,
      ),
    );
  }

  void _showSchedulePreview() {
    final scheduledDays = _selectedSlots.entries
        .where((e) => e.value.isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.carbonGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Schedule Preview',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${scheduledDays.length} days scheduled',
                style: GoogleFonts.dmSans(
                  color: AppColors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: scheduledDays.length,
                  itemBuilder: (context, index) {
                    final entry = scheduledDays[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(entry.key),
                            style: GoogleFonts.outfit(
                              color: AppColors.hyperLime,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((slot) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.hyperLime.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.hyperLime),
                                ),
                                child: Text(
                                  slot,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.hyperLime,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildRecurringSchedule(),
                    const SizedBox(height: 16),
                    _buildTimeSlots(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.white10),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Manager',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Set your availability',
                  style: GoogleFonts.dmSans(
                    color: AppColors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.skyBlue,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.hyperLime,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppColors.neonGreen,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: GoogleFonts.dmSans(color: Colors.white),
          weekendTextStyle: GoogleFonts.dmSans(color: AppColors.white70),
          outsideTextStyle: GoogleFonts.dmSans(color: AppColors.white30),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.dmSans(
            color: AppColors.hyperLime,
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: GoogleFonts.dmSans(
            color: AppColors.hyperLime,
            fontWeight: FontWeight.bold,
          ),
        ),
        eventLoader: (day) {
          final dayKey = DateTime(day.year, day.month, day.day);
          return _selectedSlots[dayKey]?.isNotEmpty == true ? [1] : [];
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildRecurringSchedule() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recurring Schedule',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                activeColor: AppColors.hyperLime,
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            Text(
              'Select Days',
              style: GoogleFonts.dmSans(
                color: AppColors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                final isSelected = _recurringDays.contains(dayNum);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _recurringDays.remove(dayNum);
                      } else {
                        _recurringDays.add(dayNum);
                      }
                    });
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.hyperLime.withOpacity(0.2)
                          : AppColors.deepBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.hyperLime : AppColors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        weekDays[index],
                        style: GoogleFonts.dmSans(
                          color: isSelected ? AppColors.hyperLime : AppColors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildTimeSlots() {
    if (_selectedDay == null) return const SizedBox();
    
    final dayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final selectedSlots = _selectedSlots[dayKey] ?? {};
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Time Slots',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(_selectedDay!),
            style: GoogleFonts.dmSans(
              color: AppColors.hyperLime,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              final slot = _timeSlots[index];
              final isSelected = selectedSlots.contains(slot);
              
              return GestureDetector(
                onTap: () => _toggleTimeSlot(slot),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.hyperLime.withOpacity(0.2)
                        : AppColors.deepBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.hyperLime : AppColors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.access_time,
                        color: isSelected ? AppColors.hyperLime : AppColors.white50,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot,
                        style: GoogleFonts.dmSans(
                          color: isSelected ? AppColors.hyperLime : AppColors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showSchedulePreview,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.skyBlue),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.preview, color: AppColors.skyBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Preview',
                      style: GoogleFonts.dmSans(
                        color: AppColors.skyBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isRecurring) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _applyRecurringSchedule,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.hyperLime, AppColors.neonGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.hyperLime.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.repeat, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Apply Recurring',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
