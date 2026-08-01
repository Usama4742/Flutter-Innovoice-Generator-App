class BusinessModel {
  String name;
  String address;
  String email;
  String phone;
  String? logoPath;

  BusinessModel({
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
    this.logoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
      'logoPath': logoPath,
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      name: map['name'],
      address: map['address'],
      email: map['email'],
      phone: map['phone'],
      logoPath: map['logoPath'],
    );
  }
}