class Contact {
  final String id;
  final String userId;
  final String name;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? suffix;
  final String? preferredName;
  final String? company;
  final String? jobTitle;
  final String? linkedinUrl;
  final String? email;
  final String? phone;
  final String? firstInteractionContext;
  final String? relationshipNature;
  final String? relationshipGoal;
  final String? maritalStatus;
  final int? kidsCount;
  final String? kidsDetails;
  final String? additionalDetails;
  final int relationshipHealth; // 0-100
  final DateTime? lastContactedAt;
  final int frequencyPreference; // Days between contact
  final DateTime createdAt;
  final List<String>? tags;
  final String? avatarUrl;
  final String? avatarRole;
  final String? avatarSkinTone;
  final String? avatarOutfit;
  final String? avatarAccessory;

  Contact({
    required this.id,
    required this.userId,
    required this.name,
    this.firstName,
    this.middleName,
    this.lastName,
    this.suffix,
    this.preferredName,
    this.company,
    this.jobTitle,
    this.linkedinUrl,
    this.email,
    this.phone,
    this.firstInteractionContext,
    this.relationshipNature,
    this.relationshipGoal,
    this.maritalStatus,
    this.kidsCount,
    this.kidsDetails,
    this.additionalDetails,
    this.relationshipHealth = 100,
    this.lastContactedAt,
    this.frequencyPreference = 30,
    required this.createdAt,
    this.tags,
    this.avatarUrl,
    this.avatarRole,
    this.avatarSkinTone,
    this.avatarOutfit,
    this.avatarAccessory,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      suffix: json['suffix'] as String?,
      preferredName: json['preferred_name'] as String?,
      company: json['company'] as String?,
      jobTitle: json['job_title'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      firstInteractionContext: json['first_interaction_context'] as String?,
      relationshipNature: json['relationship_nature'] as String?,
      relationshipGoal: json['relationship_goal'] as String?,
      maritalStatus: json['marital_status'] as String?,
      kidsCount: json['kids_count'] as int?,
      kidsDetails: json['kids_details'] as String?,
      additionalDetails: json['additional_details'] as String?,
      relationshipHealth: json['relationship_health'] as int? ?? 100,
      lastContactedAt: json['last_contacted_at'] != null
          ? DateTime.parse(json['last_contacted_at'])
          : null,
      frequencyPreference: json['frequency_preference'] as int? ?? 30,
      createdAt: DateTime.parse(json['created_at']),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      avatarUrl: json['avatar_url'] as String?,
      avatarRole: json['avatar_role'] as String?,
      avatarSkinTone: json['avatar_skin_tone'] as String?,
      avatarOutfit: json['avatar_outfit'] as String?,
      avatarAccessory: json['avatar_accessory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'suffix': suffix,
      'preferred_name': preferredName,
      'company': company,
      'job_title': jobTitle,
      'linkedin_url': linkedinUrl,
      'email': email,
      'phone': phone,
      'first_interaction_context': firstInteractionContext,
      'relationship_nature': relationshipNature,
      'relationship_goal': relationshipGoal,
      'marital_status': maritalStatus,
      'kids_count': kidsCount,
      'kids_details': kidsDetails,
      'additional_details': additionalDetails,
      'relationship_health': relationshipHealth,
      'last_contacted_at': lastContactedAt?.toIso8601String(),
      'frequency_preference': frequencyPreference,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
      'avatar_url': avatarUrl,
      'avatar_role': avatarRole,
      'avatar_skin_tone': avatarSkinTone,
      'avatar_outfit': avatarOutfit,
      'avatar_accessory': avatarAccessory,
    };
  }

  Contact copyWith({
    String? id,
    String? userId,
    String? name,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? preferredName,
    String? company,
    String? jobTitle,
    String? linkedinUrl,
    String? email,
    String? phone,
    String? firstInteractionContext,
    String? relationshipNature,
    String? relationshipGoal,
    String? maritalStatus,
    int? kidsCount,
    String? kidsDetails,
    String? additionalDetails,
    int? relationshipHealth,
    DateTime? lastContactedAt,
    int? frequencyPreference,
    DateTime? createdAt,
    List<String>? tags,
    String? avatarUrl,
    String? avatarRole,
    String? avatarSkinTone,
    String? avatarOutfit,
    String? avatarAccessory,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      preferredName: preferredName ?? this.preferredName,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstInteractionContext: firstInteractionContext ?? this.firstInteractionContext,
      relationshipNature: relationshipNature ?? this.relationshipNature,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      kidsCount: kidsCount ?? this.kidsCount,
      kidsDetails: kidsDetails ?? this.kidsDetails,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      relationshipHealth: relationshipHealth ?? this.relationshipHealth,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      frequencyPreference: frequencyPreference ?? this.frequencyPreference,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarRole: avatarRole ?? this.avatarRole,
      avatarSkinTone: avatarSkinTone ?? this.avatarSkinTone,
      avatarOutfit: avatarOutfit ?? this.avatarOutfit,
      avatarAccessory: avatarAccessory ?? this.avatarAccessory,
    );
  }
}
