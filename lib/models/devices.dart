class Device {
  final double energy;
  final double vol;
  final double ampe;
  final double wat;

  Device({
    required this.energy,
    required this.vol,
    required this.ampe,
    required this.wat,
  });

  // Hàm chuyển đổi dữ liệu về kiểu double
  static double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      energy: _toDouble(json['Energy']),
      vol: _toDouble(json['Vol']),
      ampe: _toDouble(json['ampe']),
      wat: _toDouble(json['wat']),
    );
  }

  @override
  String toString() {
    return 'Device { energy: $energy, vol: $vol, ampe: $ampe, wat: $wat }';
  }
}
