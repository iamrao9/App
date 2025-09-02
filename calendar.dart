
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../db/db.dart';
import '../models/vehicle.dart';

class CalendarScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  const CalendarScreen({super.key, this.onChanged});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focused = DateTime.now();
  DateTime? selected;
  List<Vehicle> items = [];

  Future<void> _load(DateTime day) async {
    items = await AppDatabase.instance.getExpiringOn(day);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    selected = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _load(selected!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expiry Calendar')),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: focused,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            selectedDayPredicate: (d) => selected != null &&
                d.year == selected!.year && d.month == selected!.month && d.day == selected!.day,
            onDaySelected: (sel, foc) {
              setState(() { selected = sel; focused = foc; });
              _load(sel);
            },
          ),
          const Divider(),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('इस दिन कोई expiry नहीं है'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final v = items[i];
                      return ListTile(
                        title: Text('${v.vehicleNumber} • ${v.customerName}'),
                        subtitle: const Text('इस दिन expiry है'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
