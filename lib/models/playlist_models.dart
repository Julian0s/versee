import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:versee/firestore/firestore_data_schema.dart';

/// Strongly-typed model for Playlist documents in Firestore
class PlaylistModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int iconCodePoint;
  final List<PlaylistItemModel> items;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlaylistModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.items,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory PlaylistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaylistModel.fromJson({...data, 'id': doc.id});
  }

  /// Create from JSON/Map
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconCodePoint: json['iconCodePoint'] ?? 0xe5c3, // Icons.queue_music default
      items: (json['items'] as List? ?? [])
          .map((item) => PlaylistItemModel.fromJson(item))
          .toList(),
      itemCount: json['itemCount'] ?? 0,
      createdAt: FirestoreConverter.timestampToDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreConverter.timestampToDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Convert to JSON/Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'items': items.map((item) => item.toJson()).toList(),
      'itemCount': itemCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return FirestoreConverter.prepareForFirestore(toJson());
  }

  /// Create a copy with updated fields
  PlaylistModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? iconCodePoint,
    List<PlaylistItemModel>? items,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if playlist is empty
  bool get isEmpty => items.isEmpty;

  /// Get playlist duration (sum of all item durations)
  Duration get totalDuration {
    int totalMilliseconds = 0;
    for (final item in items) {
      if (item.metadata != null && item.metadata!['duration'] != null) {
        totalMilliseconds += item.metadata!['duration'] as int;
      }
    }
    return Duration(milliseconds: totalMilliseconds);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Strongly-typed model for Playlist items
class PlaylistItemModel {
  final int order;
  final String type; // 'note', 'media', 'verseCollection'
  final String itemId;
  final String title;
  final Map<String, dynamic>? metadata;

  const PlaylistItemModel({
    required this.order,
    required this.type,
    required this.itemId,
    required this.title,
    this.metadata,
  });

  /// Create from JSON/Map
  factory PlaylistItemModel.fromJson(Map<String, dynamic> json) {
    return PlaylistItemModel(
      order: json['order'] ?? 0,
      type: json['type'] ?? '',
      itemId: json['itemId'] ?? '',
      title: json['title'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON/Map
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'type': type,
      'itemId': itemId,
      'title': title,
      'metadata': metadata ?? {},
    };
  }

  /// Create a copy with updated fields
  PlaylistItemModel copyWith({
    int? order,
    String? type,
    String? itemId,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    return PlaylistItemModel(
      order: order ?? this.order,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistItemModel &&
        other.itemId == itemId &&
        other.type == type;
  }

  @override
  int get hashCode => itemId.hashCode ^ type.hashCode;
}