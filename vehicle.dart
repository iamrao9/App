
class Vehicle {
  int? id;
  String customerName;
  String mobile;
  String vehicleNumber;
  DateTime? insuranceExpiry;
  DateTime? fitnessExpiry;
  DateTime? pucExpiry;

  Vehicle({
    this.id,
    required this.customerName,
    required this.mobile,
    required this.vehicleNumber,
    this.insuranceExpiry,
    this.fitnessExpiry,
    this.pucExpiry,
  });

  factory Vehicle.fromMap(Map<String, dynamic> m) => Vehicle(
        id: m['id'] as int?,
        customerName: m['customer_name'] ?? '',
        mobile: m['mobile'] ?? '',
        vehicleNumber: m['vehicle_number'] ?? '',
        insuranceExpiry: m['insurance_expiry'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['insurance_expiry'])
            : null,
        fitnessExpiry: m['fitness_expiry'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['fitness_expiry'])
            : null,
        pucExpiry: m['puc_expiry'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['puc_expiry'])
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_name': customerName,
        'mobile': mobile,
        'vehicle_number': vehicleNumber,
        'insurance_expiry': insuranceExpiry?.millisecondsSinceEpoch,
        'fitness_expiry': fitnessExpiry?.millisecondsSinceEpoch,
        'puc_expiry': pucExpiry?.millisecondsSinceEpoch,
      };

  /// Returns the nearest upcoming/overdue expiry among insurance/fitness/puc
  DateTime? nearestExpiry() {
    final dates = [insuranceExpiry, fitnessExpiry, pucExpiry]
        .where((d) => d != null)
        .cast<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }
}
