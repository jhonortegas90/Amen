import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../../admin/data/admin_catalog_repository.dart';
import '../domain/altar_music_track.dart';

abstract class AltarMusicRepository {
  Stream<List<AltarMusicTrack>> watchMusicTracks();
  Future<String> createMusicTrack({required String title, required String artist});
  Future<void> updateMusicTrack(AltarMusicTrack track);
  Future<void> deleteMusicTrack(AltarMusicTrack track);
  Future<CatalogMediaUpload> uploadMusicAudio({
    required String trackId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  });
  Future<void> seedDefaultTrack();
}

class DemoAltarMusicRepository implements AltarMusicRepository {
  DemoAltarMusicRepository() {
    _controller.add(_tracks);
  }

  final _controller = StreamController<List<AltarMusicTrack>>.broadcast();
  final List<AltarMusicTrack> _tracks = [
    AltarMusicTrack(
      id: 'm1',
      title: 'Still Waters',
      artist: 'Amen Worship',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      audioPath: 'altar_music/m1/audio/still_waters.mp3',
      isActive: true,
      sortOrder: 10,
      createdAt: DateTime.now(),
    ),
    AltarMusicTrack(
      id: 'm2',
      title: 'Evening Grace',
      artist: 'Amen Worship',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      audioPath: 'altar_music/m2/audio/evening_grace.mp3',
      isActive: true,
      sortOrder: 20,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Stream<List<AltarMusicTrack>> watchMusicTracks() {
    return _controller.stream;
  }

  @override
  Future<String> createMusicTrack({required String title, required String artist}) async {
    final newId = 'm${_tracks.length + 1}';
    final track = AltarMusicTrack(
      id: newId,
      title: title,
      artist: artist,
      audioUrl: '',
      audioPath: '',
      isActive: true,
      sortOrder: (_tracks.length + 1) * 10,
      createdAt: DateTime.now(),
    );
    _tracks.add(track);
    _controller.add(List.from(_tracks));
    return newId;
  }

  @override
  Future<void> updateMusicTrack(AltarMusicTrack track) async {
    final idx = _tracks.indexWhere((t) => t.id == track.id);
    if (idx != -1) {
      _tracks[idx] = track;
      _controller.add(List.from(_tracks));
    }
  }

  @override
  Future<void> deleteMusicTrack(AltarMusicTrack track) async {
    _tracks.removeWhere((t) => t.id == track.id);
    _controller.add(List.from(_tracks));
  }

  @override
  Future<CatalogMediaUpload> uploadMusicAudio({
    required String trackId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final upload = CatalogMediaUpload(
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      path: 'altar_music/$trackId/audio/$filename',
      contentType: contentType,
      size: bytes.length,
    );
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx != -1) {
      _tracks[idx] = _tracks[idx].copyWith(
        audioUrl: upload.url,
        audioPath: upload.path,
      );
      _controller.add(List.from(_tracks));
    }
    return upload;
  }

  @override
  Future<void> seedDefaultTrack() async {}
}

class FirebaseAltarMusicRepository implements AltarMusicRepository {
  FirebaseAltarMusicRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('altar_music');

  @override
  Stream<List<AltarMusicTrack>> watchMusicTracks() {
    return _collection.orderBy('sortOrder').snapshots().map((snapshot) {
      return snapshot.docs
          .map(AltarMusicTrack.fromFirestore)
          .toList(growable: false);
    });
  }

  @override
  Future<void> seedDefaultTrack() async {
    try {
      final doc = _collection.doc('default_serenity');
      final snap = await doc.get();
      if (!snap.exists) {
        final track = AltarMusicTrack(
          id: 'default_serenity',
          title: 'Serenity',
          artist: 'Amen Worship',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          audioPath: '',
          isActive: true,
          sortOrder: 10,
          createdAt: DateTime.now(),
        );
        await doc.set({
          ...track.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  @override
  Future<String> createMusicTrack({required String title, required String artist}) async {
    final doc = _collection.doc();
    final track = AltarMusicTrack(
      id: doc.id,
      title: title,
      artist: artist,
      audioUrl: '',
      audioPath: '',
      isActive: true,
      sortOrder: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
    );
    await doc.set({
      ...track.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  @override
  Future<void> updateMusicTrack(AltarMusicTrack track) async {
    await _collection.doc(track.id).set(
          track.toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteMusicTrack(AltarMusicTrack track) async {
    // Delete Firestore document
    await _collection.doc(track.id).delete();
    
    // Delete files in Storage if path is present
    if (track.audioPath.isNotEmpty) {
      try {
        await _storage.ref(track.audioPath).delete();
      } catch (_) {
        // Safe to ignore if storage file is already deleted or not found
      }
    }
  }

  @override
  Future<CatalogMediaUpload> uploadMusicAudio({
    required String trackId,
    required String filename,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safeName = _safeFilename(filename);
    final path = 'altar_music/$trackId/audio/$safeName';
    final ref = _storage.ref(path);
    
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    
    final url = await ref.getDownloadURL();
    final upload = CatalogMediaUpload(
      url: url,
      path: path,
      contentType: contentType,
      size: bytes.length,
    );

    await _collection.doc(trackId).set({
      'audioUrl': upload.url,
      'audioPath': upload.path,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return upload;
  }

  String _safeFilename(String filename) {
    final parts = filename.split('.');
    final extension = parts.length > 1 ? '.${parts.last.toLowerCase()}' : '';
    final stem = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join('.')
        : filename;
    final safeStem = stem
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safeStem.isEmpty ? 'track' : safeStem}-$timestamp$extension';
  }
}

final altarMusicRepositoryProvider = Provider<AltarMusicRepository>((ref) {
  final bootstrap = ref.watch(firebaseBootstrapProvider);
  if (bootstrap.isLive) {
    return FirebaseAltarMusicRepository();
  }
  return DemoAltarMusicRepository();
});

final altarMusicTracksProvider = StreamProvider<List<AltarMusicTrack>>((ref) {
  return ref.watch(altarMusicRepositoryProvider).watchMusicTracks();
});

final publishedAltarMusicTracksProvider = Provider<AsyncValue<List<AltarMusicTrack>>>((ref) {
  final tracksAsync = ref.watch(altarMusicTracksProvider);
  return tracksAsync.whenData((tracks) => tracks.where((t) => t.isActive).toList());
});
