import 'package:flutter/material.dart';

class OperatingHoursStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const OperatingHoursStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<OperatingHoursStep> createState() => _OperatingHoursStepState();
}

class _OperatingHoursStepState extends State<OperatingHoursStep> {
  final Map<String, Map<String, String>> _hours = {
    'monday': {'open': '08:00', 'close': '20:00'},
    'tuesday': {'open': '08:00', 'close': '20:00'},
    'wednesday': {'open': '08:00', 'close': '20:00'},
    'thursday': {'open': '08:00', 'close': '20:00'},
    'friday': {'open': '08:00', 'close': '20:00'},
    'saturday': {'open': '09:00', 'close': '18:00'},
    'sunday': {'open': '09:00', 'close': '18:00'},
  };

  final Map<String, String> _dayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    // Initialize with provided data or defaults
    widget.initialData.forEach((day, hours) {
      if (_hours.containsKey(day) && hours is Map<String, dynamic>) {
        _hours[day] = {
          'open': (hours['open'] ?? _hours[day]!['open'])!,
          'close': (hours['close'] ?? _hours[day]!['close'])!,
        };
      }
    });
    _notifyParent();
  }

  void _updateTime(String day, String type, String time) {
    setState(() {
      _hours[day]?[type] = time;
    });
    _notifyParent();
  }

  void _toggleDay(String day, bool? open) {
    setState(() {
      if (open == true) {
        _hours[day] = _hours[day] ?? {'open': '09:00', 'close': '18:00'};
      } else {
        _hours[day] = {'open': '00:00', 'close': '00:00'};
      }
    });
    _notifyParent();
  }

  void _notifyParent() {
    widget.onChanged(Map<String, Map<String, String>>.from(_hours));
  }

  Future<void> _selectTime(
    BuildContext context, 
    String day, 
    String type, 
    String currentTime,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentTime),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateTime(
        day,
        type,
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool _isDayOpen(String day) {
    final hours = _hours[day]!;
    return hours['open'] != '00:00' && hours['close'] != '00:00';
  }

  List<Widget> _buildDayWidgets() {
    final widgets = <Widget>[];
    
    for (final day in _dayNames.keys) {
      if (!_hours.containsKey(day)) continue;
      
      final hours = _hours[day]!;
      final isOpen = _isDayOpen(day);
      
      widgets.add(
        Card(
          key: ValueKey('day_$day'),
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  _dayNames[day]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Switch(
                  value: isOpen,
                  onChanged: (value) => _toggleDay(day, value),
                ),
              ),
              if (isOpen) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TimePickerButton(
                          key: ValueKey('${day}_open'),
                          label: 'Open',
                          time: hours['open']!,
                          onPressed: () => _selectTime(context, day, 'open', hours['open']!),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('to'),
                      ),
                      Expanded(
                        child: _TimePickerButton(
                          key: ValueKey('${day}_close'),
                          label: 'Close',
                          time: hours['close']!,
                          onPressed: () => _selectTime(context, day, 'close', hours['close']!),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Operating Hours',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your tennis center\'s regular operating hours. You can adjust these later in settings.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ..._buildDayWidgets(),
          const SizedBox(height: 16),
          // Add special hours button (coming soon)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Special hours feature coming soon')),
              );
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Add Special Hours (e.g., Holidays)'),
          ),
        ],
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onPressed;

  const _TimePickerButton({
    super.key,
    required this.label,
    required this.time,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).hintColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatTime(time),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time; // Return original time if parsing fails
    }
  }
}
