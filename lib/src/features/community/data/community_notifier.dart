import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../intentions/domain/intention.dart';
import '../domain/circle.dart';

class CommunityState {
  final List<Circle> circles;
  final List<CircleIntention> circleIntentions;
  final bool isLoading;
  final String? error;

  const CommunityState({
    required this.circles,
    required this.circleIntentions,
    this.isLoading = false,
    this.error,
  });

  CommunityState copyWith({
    List<Circle>? circles,
    List<CircleIntention>? circleIntentions,
    bool? isLoading,
    String? error,
  }) {
    return CommunityState(
      circles: circles ?? this.circles,
      circleIntentions: circleIntentions ?? this.circleIntentions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommunityNotifier extends Notifier<CommunityState> {
  @override
  CommunityState build() {
    return const CommunityState(
      circles: [],
      circleIntentions: [],
    );
  }

  String _generateSecureInviteCode() {
    final random = Random.secure();
    // Exclude ambiguous characters (like 1, I, 0, O, etc.) for visual clarity
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String nextSegment(int length) {
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }
    // E.g., AMEN-8K2A-9P7W
    return 'AMEN-${nextSegment(4)}-${nextSegment(4)}';
  }

  Future<void> createCircle(String name, String description, int gradientIndex) async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 400)); // Simulate network latency

    final newCircle = Circle(
      id: 'circle-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      inviteCode: _generateSecureInviteCode(),
      creatorUid: 'user-uid',
      memberUids: ['user-uid'],
      themeGradientIndex: gradientIndex,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      circles: [newCircle, ...state.circles],
      isLoading: false,
    );
  }

  Future<bool> joinCircle(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 500)); // Simulate network latency

    final code = inviteCode.trim().toUpperCase();

    // Check if user is already in a circle with this code
    final alreadyJoined = state.circles.any((c) => c.inviteCode == code);
    if (alreadyJoined) {
      state = state.copyWith(isLoading: false, error: 'You are already a member of this circle.');
      return false;
    }

    // Mock verification of code
    if (code.startsWith('AMEN-')) {
      final joinedCircle = Circle(
        id: 'circle-joined-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Joined Circle (${code.substring(5)})',
        description: 'Joined via invite code $code.',
        inviteCode: code,
        creatorUid: 'other-uid',
        memberUids: ['user-uid', 'other-uid', 'member-1', 'member-2'],
        themeGradientIndex: Random().nextInt(6),
        createdAt: DateTime.now(),
      );

      // Add a mock welcome prayer for this circle
      final welcomeIntention = CircleIntention(
        id: 'mock-ci-joined-${DateTime.now().millisecondsSinceEpoch}',
        circleId: joinedCircle.id,
        authorUid: 'other-uid',
        text: 'Welcome to our private prayer circle! Tap the button below to share your first prayer requests.',
        createdAt: DateTime.now(),
        amenCount: 0,
        category: PrayerCategory.general,
        isAnonymous: false,
        authorName: 'Circle Creator',
      );

      state = state.copyWith(
        circles: [...state.circles, joinedCircle],
        circleIntentions: [welcomeIntention, ...state.circleIntentions],
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid invitation code format. Must start with AMEN-',
      );
      return false;
    }
  }

  Future<void> leaveCircle(String circleId) async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      circles: state.circles.where((c) => c.id != circleId).toList(),
      circleIntentions: state.circleIntentions.where((ci) => ci.circleId != circleId).toList(),
      isLoading: false,
    );
  }

  Future<void> shareIntentionToCircle({
    required String circleId,
    required String text,
    required PrayerCategory category,
    required bool isAnonymous,
    String? authorName,
  }) async {
    final newIntention = CircleIntention(
      id: 'ci-${DateTime.now().millisecondsSinceEpoch}',
      circleId: circleId,
      authorUid: 'user-uid',
      text: text,
      createdAt: DateTime.now(),
      amenCount: 0,
      category: category,
      isAnonymous: isAnonymous,
      authorName: isAnonymous ? null : (authorName ?? 'You'),
    );

    state = state.copyWith(
      circleIntentions: [newIntention, ...state.circleIntentions],
    );
  }

  Future<void> sayAmenToCircleIntention(String circleId, String intentionId) async {
    state = state.copyWith(
      circleIntentions: state.circleIntentions.map((ci) {
        if (ci.id == intentionId) {
          final isAmened = ci.amenUserUids.contains('user-uid');
          final newUids = Set<String>.from(ci.amenUserUids);
          int count = ci.amenCount;
          if (isAmened) {
            newUids.remove('user-uid');
            count = max(0, count - 1);
          } else {
            newUids.add('user-uid');
            count += 1;
          }
          return ci.copyWith(
            amenCount: count,
            amenUserUids: newUids,
          );
        }
        return ci;
      }).toList(),
    );
  }
}

final communityStateProvider = NotifierProvider<CommunityNotifier, CommunityState>(
  CommunityNotifier.new,
);
