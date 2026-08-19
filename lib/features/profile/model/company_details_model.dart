class CompanyProfileResponse {
  final bool? status;
  final int? statusCode;
  final String? message;
  final CompanyProfileData? data;

  CompanyProfileResponse({this.status, this.statusCode, this.message, this.data});

  factory CompanyProfileResponse.fromJson(Map<String, dynamic> json) {
    return CompanyProfileResponse(
      status: json['status'] as bool?,
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? CompanyProfileData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class CompanyProfileData {
  final int? id;
  final String? name;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? email;
  final String? logo;

  CompanyProfileData({
    this.id,
    this.name,
    this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phone,
    this.email,
    this.logo,
  });

  factory CompanyProfileData.fromJson(Map<String, dynamic> json) {
    return CompanyProfileData(
      id: json['id'] as int?,
      name: json['name'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logo: json['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'email': email,
      'logo': logo,
    };
  }
}