class Device {
  final int energy;
  final int vol;
  final int ampe;
  final int wat;

  Device({
    required this.energy,
    required this.vol,
    required this.ampe,
    required this.wat,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      energy: json['Energy'] as int? ?? 0,
      vol: json['Vol'] as int? ?? 0,
      ampe: json['ampe'] as int? ?? 0,
      wat: json['wat'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'DeviceData { energy: $energy, vol: $vol, ampe: $ampe, wat: $wat }';
  }
}
