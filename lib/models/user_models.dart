import '../config/user_type_config.dart';

abstract class User {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final String? religion;
  final UserType userType;
  final String? email;
  final String? phone;
  final DateTime? createdAt;
  final List<Map<String, dynamic>> addresses;

  const User({
    required this.id,
    required this.name,
    required this.userType,
    this.profileImageUrl,
    this.bannerImageUrl,
    this.religion,
    this.email,
    this.phone,
    this.createdAt,
    this.addresses = const [],
  });

  // Factory method to create appropriate user type from JSON
  factory User.fromJson(Map<String, dynamic> json, UserType userType) {
    switch (userType) {
      case UserType.dharmguru:
        return DharmguruUser.fromJson(json);
      case UserType.kathavachak:
        return KathavachakUser.fromJson(json);
      case UserType.panditji:
        return PanditjiUser.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

class DharmguruUser extends User {
  final String? ashramName;
  final String? guruParampara;
  final List<String>? specialties;
  final String? philosophy;

  const DharmguruUser({
    required String id,
    required String name,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? religion,
    String? email,
    String? phone,
    DateTime? createdAt,
    List<Map<String, dynamic>>? addresses,
    this.ashramName,
    this.guruParampara,
    this.specialties,
    this.philosophy,
  }) : super(
          id: id,
          name: name,
          userType: UserType.dharmguru,
          profileImageUrl: profileImageUrl,
          bannerImageUrl: bannerImageUrl,
          religion: religion,
          email: email,
          phone: phone,
          createdAt: createdAt,
          addresses: addresses ?? const [],
        );

  factory DharmguruUser.fromJson(Map<String, dynamic> json) {
    return DharmguruUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? json['imageUrl'],
      bannerImageUrl: json['bannerImageUrl'] ?? json['coverImageUrl'],
      religion: json['religion'],
      email: json['email'],
      phone: json['phone'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      addresses: json['addresses'] is List ? List<Map<String, dynamic>>.from(json['addresses']) : const [],
      ashramName: json['ashramName'],
      guruParampara: json['guruParampara'],
      specialties: json['specialties'] is List ? List<String>.from(json['specialties']) : null,
      philosophy: json['philosophy'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userType': 'dharmguru',
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'religion': religion,
      'email': email,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
      'ashramName': ashramName,
      'guruParampara': guruParampara,
      'specialties': specialties,
      'philosophy': philosophy,
    };
  }
}

class KathavachakUser extends User {
  final List<String>? kathaTypes;
  final String? performanceStyle;
  final List<String>? languages;
  final String? experience;

  const KathavachakUser({
    required String id,
    required String name,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? religion,
    String? email,
    String? phone,
    DateTime? createdAt,
    List<Map<String, dynamic>>? addresses,
    this.kathaTypes,
    this.performanceStyle,
    this.languages,
    this.experience,
  }) : super(
          id: id,
          name: name,
          userType: UserType.kathavachak,
          profileImageUrl: profileImageUrl,
          bannerImageUrl: bannerImageUrl,
          religion: religion,
          email: email,
          phone: phone,
          createdAt: createdAt,
          addresses: addresses ?? const [],
        );

  factory KathavachakUser.fromJson(Map<String, dynamic> json) {
    return KathavachakUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? json['imageUrl'],
      bannerImageUrl: json['bannerImageUrl'] ?? json['coverImageUrl'],
      religion: json['religion'],
      email: json['email'],
      phone: json['phone'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      addresses: json['addresses'] is List ? List<Map<String, dynamic>>.from(json['addresses']) : const [],
      kathaTypes: json['kathaTypes'] is List ? List<String>.from(json['kathaTypes']) : null,
      performanceStyle: json['performanceStyle'],
      languages: json['languages'] is List ? List<String>.from(json['languages']) : null,
      experience: json['experience'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userType': 'kathavachak',
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'religion': religion,
      'email': email,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
      'kathaTypes': kathaTypes,
      'performanceStyle': performanceStyle,
      'languages': languages,
      'experience': experience,
    };
  }
}

class PanditjiUser extends User {
  final List<String>? ritualSpecialties;
  final String? education;
  final List<String>? certifications;
  final String? experience;

  const PanditjiUser({
    required String id,
    required String name,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? religion,
    String? email,
    String? phone,
    DateTime? createdAt,
    List<Map<String, dynamic>>? addresses,
    this.ritualSpecialties,
    this.education,
    this.certifications,
    this.experience,
  }) : super(
          id: id,
          name: name,
          userType: UserType.panditji,
          profileImageUrl: profileImageUrl,
          bannerImageUrl: bannerImageUrl,
          religion: religion,
          email: email,
          phone: phone,
          createdAt: createdAt,
          addresses: addresses ?? const [],
        );

  factory PanditjiUser.fromJson(Map<String, dynamic> json) {
    return PanditjiUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? json['imageUrl'],
      bannerImageUrl: json['bannerImageUrl'] ?? json['coverImageUrl'],
      religion: json['religion'],
      email: json['email'],
      phone: json['phone'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      addresses: json['addresses'] is List ? List<Map<String, dynamic>>.from(json['addresses']) : const [],
      ritualSpecialties: json['ritualSpecialties'] is List ? List<String>.from(json['ritualSpecialties']) : null,
      education: json['education'],
      certifications: json['certifications'] is List ? List<String>.from(json['certifications']) : null,
      experience: json['experience'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userType': 'panditji',
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'religion': religion,
      'email': email,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
      'ritualSpecialties': ritualSpecialties,
      'education': education,
      'certifications': certifications,
      'experience': experience,
    };
  }
}