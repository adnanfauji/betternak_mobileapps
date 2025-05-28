class CustomerDetails {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;

  CustomerDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}
