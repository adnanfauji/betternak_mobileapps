class CustomerDetails {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? country;

  // Additional fields that might be useful
  final String? profileImageUrl;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerDetails({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.country = 'Indonesia', // Default country
    this.profileImageUrl,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  // Full name getter
  String get fullName =>
      [firstName ?? '', lastName ?? ''].where((e) => e.isNotEmpty).join(' ');

  // Full address getter
  String get fullAddress => [
    address ?? '',
    city ?? '',
    province ?? '',
    postalCode ?? '',
    country ?? '',
  ].where((e) => e.isNotEmpty).join(', ');

  // Factory constructor to create CustomerDetails from JSON
  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      id: json['id']?.toString(),
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      email: json['email'],
      phone: json['phone'] ?? json['phone_number'],
      address: json['address'] ?? json['street_address'],
      city: json['city'],
      province: json['province'] ?? json['state'],
      postalCode: json['postal_code'] ?? json['postalCode'] ?? json['zip_code'],
      country: json['country'] ?? 'Indonesia',
      profileImageUrl: json['profile_image'] ?? json['avatar'],
      isVerified:
          json['is_verified'] == true ||
          json['isVerified'] == true ||
          json['verified'] == true,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
    );
  }

  // Convert CustomerDetails instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'country': country,
      'profile_image': profileImageUrl,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Convert to shipping address for order processing
  Map<String, dynamic> toShippingAddress() {
    return {
      'recipient_name': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'country': country,
    };
  }

  // Create a copy of CustomerDetails with some fields replaced
  CustomerDetails copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    String? country,
    String? profileImageUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerDetails(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerDetails &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.phone == phone &&
        other.address == address &&
        other.city == city &&
        other.province == province &&
        other.postalCode == postalCode &&
        other.country == country;
  }

  // Override hash code
  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        address.hashCode ^
        city.hashCode ^
        province.hashCode ^
        postalCode.hashCode ^
        country.hashCode;
  }

  // String representation of customer details (for debugging)
  @override
  String toString() {
    return 'CustomerDetails(id: $id, name: $fullName, email: $email, phone: $phone)';
  }

  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Validate Indonesian phone number
  static bool isValidIndonesianPhone(String phone) {
    // Basic Indonesian phone format: +62 or 0 followed by 9-12 digits
    final phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{7,11}$');
    return phoneRegex.hasMatch(phone);
  }

  // Validate if customer details are complete enough for shipping
  bool isCompleteForShipping() {
    return firstName != null &&
        firstName!.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        city != null &&
        city!.isNotEmpty &&
        province != null &&
        province!.isNotEmpty &&
        postalCode != null &&
        postalCode!.isNotEmpty;
  }
}
