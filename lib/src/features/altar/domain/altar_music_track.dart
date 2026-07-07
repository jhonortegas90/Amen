import 'package:cloud_firestore/cloud_firestore.dart';

class AltarMusicTrack {
  const AltarMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.audioPath,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String audioPath;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Placeholder art url for lock screen
  static const String defaultArtUrl = 'https://firebasestorage.googleapis.com/v0/b/amencircle.appspot.com/o/assets%2Fmusic_placeholder.png?alt=media';

  static const List<AltarMusicTrack> demoTracks = [
    AltarMusicTrack(
      id: 'demo_m1',
      title: 'Still Waters',
      artist: 'Amen Worship',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      audioPath: '',
      isActive: true,
      sortOrder: 10,
    ),
    AltarMusicTrack(
      id: 'demo_m2',
      title: 'Evening Grace',
      artist: 'Amen Worship',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      audioPath: '',
      isActive: true,
      sortOrder: 20,
    ),
  ];

  static AltarMusicTrack fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return AltarMusicTrack(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Track',
      artist: data['artist'] as String? ?? 'Unknown Artist',
      audioUrl: data['audioUrl'] as String? ?? '',
      audioPath: data['audioPath'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.trim(),
      'artist': artist.trim(),
      'audioUrl': audioUrl,
      'audioPath': audioPath,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AltarMusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? audioPath,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AltarMusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      audioPath: audioPath ?? this.audioPath,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
