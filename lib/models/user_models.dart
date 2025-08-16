import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:versee/firestore/firestore_data_schema.dart';

/// Strongly-typed model for User documents in Firestore
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String plan; // 'free' or 'premium'
  final String? language; // 'pt', 'en', 'es'
  final String? theme; // 'dark', 'light'
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.plan,
    this.language,
    this.theme,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firebase Auth User
  factory UserModel.fromAuthUser(User user, {
    String plan = 'free',
    String language = 'pt',
    String theme = 'dark',
  }) {
    final now = DateTime.now();
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      plan: plan,
      language: language,
      theme: theme,
      createdAt: user.metadata.creationTime ?? now,
      updatedAt: now,
    );
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'id': doc.id});
  }

  /// Create from JSON/Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      plan: json['plan'] ?? 'free',
      language: json['language'],
      theme: json['theme'],
      createdAt: FirestoreConverter.timestampToDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreConverter.timestampToDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Convert to JSON/Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'plan': plan,
      'language': language,
      'theme': theme,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return FirestoreConverter.prepareForFirestore(toJson());
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? plan,
    String? language,
    String? theme,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      plan: plan ?? this.plan,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has premium plan
  bool get isPremium => plan == 'premium';

  /// Check if user has free plan
  bool get isFree => plan == 'free';

  /// Check if user uses dark theme
  bool get isDarkTheme => theme == 'dark';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Strongly-typed model for User Settings documents in Firestore
class UserSettingsModel {
  final String userId;
  final BibleVersionSettings bibleVersions;
  final SecondScreenSettings secondScreenSettings;
  final GeneralSettings generalSettings;
  final DateTime updatedAt;

  const UserSettingsModel({
    required this.userId,
    required this.bibleVersions,
    required this.secondScreenSettings,
    required this.generalSettings,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory UserSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSettingsModel.fromJson({...data, 'userId': doc.id});
  }

  /// Create from JSON/Map
  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: json['userId'] ?? '',
      bibleVersions: BibleVersionSettings.fromJson(json['bibleVersions'] ?? {}),
      secondScreenSettings: SecondScreenSettings.fromJson(json['secondScreenSettings'] ?? {}),
      generalSettings: GeneralSettings.fromJson(json['generalSettings'] ?? {}),
      updatedAt: FirestoreConverter.timestampToDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Convert to JSON/Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bibleVersions': bibleVersions.toJson(),
      'secondScreenSettings': secondScreenSettings.toJson(),
      'generalSettings': generalSettings.toJson(),
      'updatedAt': updatedAt,
    };
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return FirestoreConverter.prepareForFirestore(toJson());
  }

  /// Create a copy with updated fields
  UserSettingsModel copyWith({
    String? userId,
    BibleVersionSettings? bibleVersions,
    SecondScreenSettings? secondScreenSettings,
    GeneralSettings? generalSettings,
    DateTime? updatedAt,
  }) {
    return UserSettingsModel(
      userId: userId ?? this.userId,
      bibleVersions: bibleVersions ?? this.bibleVersions,
      secondScreenSettings: secondScreenSettings ?? this.secondScreenSettings,
      generalSettings: generalSettings ?? this.generalSettings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Bible version settings
class BibleVersionSettings {
  final String primaryVersion;
  final String? secondaryVersion;
  final List<String> availableVersions;

  const BibleVersionSettings({
    required this.primaryVersion,
    this.secondaryVersion,
    required this.availableVersions,
  });

  factory BibleVersionSettings.fromJson(Map<String, dynamic> json) {
    return BibleVersionSettings(
      primaryVersion: json['primaryVersion'] ?? 'NVI',
      secondaryVersion: json['secondaryVersion'],
      availableVersions: List<String>.from(json['availableVersions'] ?? ['NVI']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryVersion': primaryVersion,
      'secondaryVersion': secondaryVersion,
      'availableVersions': availableVersions,
    };
  }
}

/// Second screen settings
class SecondScreenSettings {
  final bool enabled;
  final String backgroundColor;
  final String textColor;
  final double fontSize;
  final String fontFamily;
  final bool showBackground;
  final String backgroundType; // 'color', 'image', 'video'

  const SecondScreenSettings({
    required this.enabled,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    required this.fontFamily,
    required this.showBackground,
    required this.backgroundType,
  });

  factory SecondScreenSettings.fromJson(Map<String, dynamic> json) {
    return SecondScreenSettings(
      enabled: json['enabled'] ?? false,
      backgroundColor: json['backgroundColor'] ?? '#000000',
      textColor: json['textColor'] ?? '#FFFFFF',
      fontSize: (json['fontSize'] ?? 24.0).toDouble(),
      fontFamily: json['fontFamily'] ?? 'Roboto',
      showBackground: json['showBackground'] ?? true,
      backgroundType: json['backgroundType'] ?? 'color',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'showBackground': showBackground,
      'backgroundType': backgroundType,
    };
  }
}

/// General app settings
class GeneralSettings {
  final bool autoSave;
  final bool enableNotifications;
  final String defaultNoteType; // 'lyrics' or 'notes'
  final int maxRecentItems;
  final bool enableAnalytics;
  final bool enableCrashReporting;

  const GeneralSettings({
    required this.autoSave,
    required this.enableNotifications,
    required this.defaultNoteType,
    required this.maxRecentItems,
    required this.enableAnalytics,
    required this.enableCrashReporting,
  });

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      autoSave: json['autoSave'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      defaultNoteType: json['defaultNoteType'] ?? 'lyrics',
      maxRecentItems: json['maxRecentItems'] ?? 10,
      enableAnalytics: json['enableAnalytics'] ?? false,
      enableCrashReporting: json['enableCrashReporting'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSave': autoSave,
      'enableNotifications': enableNotifications,
      'defaultNoteType': defaultNoteType,
      'maxRecentItems': maxRecentItems,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
    };
  }
}