class CustomerModel {
  String name;
  String address;
  String email;
  String phone;

  CustomerModel({
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      name: map['name'],
      address: map['address'],
      email: map['email'],
      phone: map['phone'],
    );
  }
}