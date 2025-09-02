
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/db.dart';
import 'models/vehicle.dart';
import 'screens/add_edit_vehicle.dart';
import 'screens/calendar.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();
  await NotificationService.instance.init();
  runApp(const MaharajaApp());
}

class MaharajaApp extends StatelessWidget {
  const MaharajaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maharaja Solutions – Insurance Reminder',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Vehicle> vehicles = [];
  bool loading = true;

  Future<void> _load() async {
    vehicles = await AppDatabase.instance.getVehicles();
    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(Vehicle v) {
    final now = DateTime.now();
    DateTime? nearest = v.nearestExpiry();
    if (nearest == null) return Colors.grey;
    if (DateTime(nearest.year, nearest.month, nearest.day)
        .isBefore(DateTime(now.year, now.month, now.day))) {
      return Colors.red;
    }
    if (nearest.difference(now).inDays <= 10) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime? d) =>
      d == null ? '-' : DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maharaja Solutions'),
        actions: [
          IconButton(
            tooltip: 'Calendar',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CalendarScreen(onChanged: _load)));
              _load();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'backup') {
                await BackupService.instance.backupToDrive(context);
              } else if (v == 'restore') {
                await BackupService.instance.restoreFromDrive(context);
                await _load();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'backup', child: Text('Backup to Drive')),
              PopupMenuItem(value: 'restore', child: Text('Restore from Drive')),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
              ? const Center(child: Text('कोई रिकॉर्ड नहीं मिला। + पर टैप करके जोड़ें'))
              : ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (_, i) {
                    final v = vehicles[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(v),
                          child: const Icon(Icons.directions_car, color: Colors.white),
                        ),
                        title: Text('${v.vehicleNumber} • ${v.customerName}'),
                        subtitle: Text(
                          'Ins: ${_formatDate(v.insuranceExpiry)}  |  Fit: ${_formatDate(v.fitnessExpiry)}  |  PUC: ${_formatDate(v.pucExpiry)}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'edit') {
                              await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => AddEditVehicleScreen(vehicle: v)));
                              _load();
                            } else if (val == 'delete') {
                              await AppDatabase.instance.deleteVehicle(v.id!);
                              await NotificationService.instance.cancelForVehicle(v.id!);
                              _load();
                            }
                          },
                          itemBuilder: (c) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
