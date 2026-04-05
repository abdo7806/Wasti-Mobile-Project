class MedicalCenter {
  final int id;
  final String name;
  final String address;
  final String phone;

  MedicalCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory MedicalCenter.fromJson(Map<String, dynamic> json) {
    return MedicalCenter(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'غير محدد',
      address: json['address'] ?? 'غير محدد',
      phone: json['phone'] ?? 'غير محدد',
    );
  }
}
