import 'package:flutter/material.dart';
import '../../intentions/domain/intention.dart';

class Circle {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final String creatorUid;
  final List<String> memberUids;
  final int themeGradientIndex;
  final DateTime createdAt;

  const Circle({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.creatorUid,
    required this.memberUids,
    required this.themeGradientIndex,
    required this.createdAt,
  });

  Circle copyWith({
    String? id,
    String? name,
    String? description,
    String? inviteCode,
    String? creatorUid,
    List<String>? memberUids,
    int? themeGradientIndex,
    DateTime? createdAt,
  }) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      creatorUid: creatorUid ?? this.creatorUid,
      memberUids: memberUids ?? this.memberUids,
      themeGradientIndex: themeGradientIndex ?? this.themeGradientIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CircleIntention {
  final String id;
  final String circleId;
  final String authorUid;
  final String text;
  final DateTime createdAt;
  final int amenCount;
  final PrayerCategory category;
  final bool isAnonymous;
  final String? authorName;
  final String? authorAvatarUrl;
  final Set<String> amenUserUids; // tracks which mock users said amen

  const CircleIntention({
    required this.id,
    required this.circleId,
    required this.authorUid,
    required this.text,
    required this.createdAt,
    required this.amenCount,
    required this.category,
    required this.isAnonymous,
    this.authorName,
    this.authorAvatarUrl,
    this.amenUserUids = const {},
  });

  CircleIntention copyWith({
    String? id,
    String? circleId,
    String? authorUid,
    String? text,
    DateTime? createdAt,
    int? amenCount,
    PrayerCategory? category,
    bool? isAnonymous,
    String? authorName,
    String? authorAvatarUrl,
    Set<String>? amenUserUids,
  }) {
    return CircleIntention(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      authorUid: authorUid ?? this.authorUid,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      amenCount: amenCount ?? this.amenCount,
      category: category ?? this.category,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      amenUserUids: amenUserUids ?? this.amenUserUids,
    );
  }
}

// Predefined visually stunning gradient themes for circles
final List<List<Color>> circleGradients = [
  [const Color(0xFF1D2671), const Color(0xFFC33764)], // Velvet Sunset
  [const Color(0xFF0F2027), const Color(0xFF203A43)], // Slate Deep Ocean
  [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Neon Garden
  [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)], // Deep Purple Dream
  [const Color(0xFFFF416C), const Color(0xFFFF4B2B)], // Coral Flame
  [const Color(0xFF1F1C2C), const Color(0xFF928DAB)], // Midnight Slate
];
