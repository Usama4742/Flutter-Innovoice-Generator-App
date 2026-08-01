class ItemModel {
  String name;
  int quantity;
  double price;
  double discount;

  ItemModel({
    required this.name,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  double get total =>
      (price * quantity) - discount;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'discount': discount,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      discount: map['discount'],
    );
  }
}