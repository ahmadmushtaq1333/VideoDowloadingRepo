import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A simple multi-timezone digital clock widget.
///
/// Uses the device time (UTC) and applies fixed offsets for zones. For full
/// DST-aware behavior use the `timezone` package — I can add that if you want.
class MultiTimezoneClock extends StatefulWidget {
  final Map<String, Duration> zones;
  final TextStyle? labelStyle;
  final TextStyle? timeStyle;
  final String timeFormat;

  const MultiTimezoneClock({
    Key? key,
    required this.zones,
    this.labelStyle,
    this.timeStyle,
    this.timeFormat = 'HH:mm:ss',
  }) : super(key: key);

  @override
  State<MultiTimezoneClock> createState() => _MultiTimezoneClockState();
}

class _MultiTimezoneClockState extends State<MultiTimezoneClock> {
  late Timer _timer;
  late DateTime _nowUtc;

  @override
  void initState() {
    super.initState();
    _nowUtc = DateTime.now().toUtc();
    final msToNextSecond = 1000 - DateTime.now().millisecond;
    _timer = Timer(Duration(milliseconds: msToNextSecond), _startPeriodicTick);
  }

  void _startPeriodicTick() {
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      _nowUtc = DateTime.now().toUtc();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) => DateFormat(widget.timeFormat).format(dt);

  @override
  Widget build(BuildContext context) {
    final labelStyle = widget.labelStyle ?? Theme.of(context).textTheme.bodySmall;
    final timeStyle = widget.timeStyle ?? Theme.of(context).textTheme.titleLarge;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('World Clocks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...widget.zones.entries.map((entry) {
              final label = entry.key;
              final offset = entry.value;
              final zoneTime = _nowUtc.add(offset);
              final formatted = _formatTime(zoneTime);
              final offsetSign = offset.isNegative ? '-' : '+';
              final absOffset = offset.abs();
              final hours = absOffset.inHours;
              final minutes = absOffset.inMinutes.remainder(60);
              final offsetStr = 'UTC$offsetSign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: labelStyle),
                          Text(offsetStr, style: labelStyle?.copyWith(fontSize: (labelStyle.fontSize ?? 12) - 2)),
                        ],
                      ),
                    ),
                    Text(formatted, style: timeStyle),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
