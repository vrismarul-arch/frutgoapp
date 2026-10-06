class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final String provider;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.provider,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: json['id'] ??
          json['_id'] ??
          '',

      name: json['name']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      // Support both backend names.
      phone: (
        json['phone'] ??
        json['mobile'] ??
        ''
      ).toString(),

      avatar: json['avatar']?.toString() ?? '',

      provider: json['provider']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'provider': provider,
    };
  }

  UserModel copyWith({
    dynamic id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? provider,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      provider: provider ?? this.provider,
    );
  }
}