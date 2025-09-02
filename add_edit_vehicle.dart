
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;
  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _number = TextEditingController();
  DateTime? ins, fit, puc;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v != null) {
      _name.text = v.customerName;
      _mobile.text = v.mobile;
      _number.text = v.vehicleNumber;
      ins = v.insuranceExpiry;
      fit = v.fitnessExpiry;
      puc = v.pucExpiry;
    }
  }

  Future<void> _pickDate(BuildContext ctx, void Function(DateTime?) set) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: ctx,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      initialDate: now,
    );
    set(d);
  }

  String _fmt(DateTime? d) =>
      d == null ? '-' : DateFormat('dd MMM yyyy').format(d);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final v = Vehicle(
      id: widget.vehicle?.id,
      customerName: _name.text.trim(),
      mobile: _mobile.text.trim(),
      vehicleNumber: _number.text.trim().toUpperCase(),
      insuranceExpiry: ins,
      fitnessExpiry: fit,
      pucExpiry: puc,
    );
    if (v.id == null) {
      final id = await AppDatabase.instance.insertVehicle(v);
      v.id = id;
      await NotificationService.instance.scheduleForVehicle(v);
    } else {
      await AppDatabase.instance.updateVehicle(v);
      await NotificationService.instance.scheduleForVehicle(v);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Customer Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile'),
            ),
            TextFormField(
              controller: _number,
              decoration: const InputDecoration(labelText: 'Vehicle Number'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text('Insurance: ${_fmt(ins)}')),
              TextButton(onPressed: () => _pickDate(context, (d){ setState(()=> ins = d); }), child: const Text('Select')),
            ]),
            Row(children: [
              Expanded(child: Text('Fitness: ${_fmt(fit)}')),
              TextButton(onPressed: () => _pickDate(context, (d){ setState(()=> fit = d); }), child: const Text('Select')),
            ]),
            Row(children: [
              Expanded(child: Text('PUC: ${_fmt(puc)}')),
              TextButton(onPressed: () => _pickDate(context, (d){ setState(()=> puc = d); }), child: const Text('Select')),
            ]),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
