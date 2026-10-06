class User {
  final int id;
  final String username;
  final String email;
  final String? shopName;
  final String? phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.shopName,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      shopName: json['shop_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'shop_name': shopName,
      'phone_number': phoneNumber,
    };
  }
}
