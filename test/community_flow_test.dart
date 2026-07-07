import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amen/src/features/community/data/community_notifier.dart';
import 'package:amen/src/features/intentions/domain/intention.dart';

void main() {
  group('CommunityNotifier & State Management Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('build method sets up empty initial state in production mode', () {
      final state = container.read(communityStateProvider);
      
      expect(state.circles.isEmpty, isTrue);
      expect(state.circleIntentions.isEmpty, isTrue);
    });

    test('createCircle adds a new circle to the top of list with a secure invite code', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      await notifier.createCircle('Devotional Circle', 'A test description', 2);
      
      final state = container.read(communityStateProvider);
      expect(state.circles.length, 1);
      
      final newCircle = state.circles.first;
      expect(newCircle.name, 'Devotional Circle');
      expect(newCircle.description, 'A test description');
      expect(newCircle.themeGradientIndex, 2);
      expect(newCircle.creatorUid, 'user-uid');
      expect(newCircle.inviteCode.startsWith('AMEN-'), isTrue);
      // Format should be AMEN-XXXX-XXXX (14 chars)
      expect(newCircle.inviteCode.length, 14);
    });

    test('joinCircle succeeds with a valid code starting with AMEN-', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      final success = await notifier.joinCircle('AMEN-TEST-CODE');
      expect(success, isTrue);
      
      final state = container.read(communityStateProvider);
      expect(state.circles.length, 1);
      
      final joined = state.circles.last;
      expect(joined.inviteCode, 'AMEN-TEST-CODE');
      expect(joined.name, 'Joined Circle (TEST-CODE)');
      
      // Verification that a welcome prayer was posted to the joined circle
      final circlePrayers = state.circleIntentions.where((ci) => ci.circleId == joined.id).toList();
      expect(circlePrayers.length, 1);
      expect(circlePrayers.first.text.contains('Welcome to our private prayer circle'), isTrue);
    });

    test('joinCircle fails if the code has already been joined', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      // Let's join first
      final success1 = await notifier.joinCircle('AMEN-DUPL-CODE');
      expect(success1, isTrue);
      
      // Try joining same code again
      final success2 = await notifier.joinCircle('AMEN-DUPL-CODE');
      expect(success2, isFalse);
      
      final state = container.read(communityStateProvider);
      expect(state.error, 'You are already a member of this circle.');
    });

    test('joinCircle fails if code does not start with AMEN-', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      final success = await notifier.joinCircle('INVALID-CODE');
      expect(success, isFalse);
      
      final state = container.read(communityStateProvider);
      expect(state.error, 'Invalid invitation code format. Must start with AMEN-');
    });

    test('leaveCircle removes the circle and its intentions', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      // Setup: Join a circle and add an intention
      await notifier.joinCircle('AMEN-TEMP-LEAV');
      final stateBefore = container.read(communityStateProvider);
      expect(stateBefore.circles.length, 1);
      final circleId = stateBefore.circles.first.id;
      
      await notifier.shareIntentionToCircle(
        circleId: circleId,
        text: 'Temporary prayer',
        category: PrayerCategory.general,
        isAnonymous: true,
      );
      
      // Verify setup
      final stateAfterSetup = container.read(communityStateProvider);
      expect(stateAfterSetup.circleIntentions.length, 2); // 1 welcome + 1 custom
      
      // Leave circle
      await notifier.leaveCircle(circleId);
      
      final stateAfter = container.read(communityStateProvider);
      expect(stateAfter.circles.isEmpty, isTrue);
      expect(stateAfter.circleIntentions.isEmpty, isTrue);
    });

    test('shareIntentionToCircle adds an intention successfully', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      // Setup: Create a circle
      await notifier.createCircle('Devotional Circle', 'A test description', 2);
      final stateSetup = container.read(communityStateProvider);
      final circleId = stateSetup.circles.first.id;
      
      await notifier.shareIntentionToCircle(
        circleId: circleId,
        text: 'Praying for safety on my trip.',
        category: PrayerCategory.guidance,
        isAnonymous: false,
        authorName: 'Blessed Pilgrim',
      );
      
      final state = container.read(communityStateProvider);
      expect(state.circleIntentions.length, 1);
      
      final newIntention = state.circleIntentions.first;
      expect(newIntention.text, 'Praying for safety on my trip.');
      expect(newIntention.circleId, circleId);
      expect(newIntention.category, PrayerCategory.guidance);
      expect(newIntention.isAnonymous, isFalse);
      expect(newIntention.authorName, 'Blessed Pilgrim');
    });

    test('sayAmenToCircleIntention toggles amen count and user uid tracking', () async {
      final notifier = container.read(communityStateProvider.notifier);
      
      // Setup: Create a circle and post an intention
      await notifier.createCircle('Circle 1', 'Desc', 1);
      final stateSetup = container.read(communityStateProvider);
      final circleId = stateSetup.circles.first.id;
      
      await notifier.shareIntentionToCircle(
        circleId: circleId,
        text: 'Prayer request',
        category: PrayerCategory.general,
        isAnonymous: false,
        authorName: 'User',
      );
      
      final stateBefore = container.read(communityStateProvider);
      final intentionId = stateBefore.circleIntentions.first.id;
      
      // Verify initial states: 0 amens
      final target = stateBefore.circleIntentions.firstWhere((ci) => ci.id == intentionId);
      expect(target.amenCount, 0);
      expect(target.amenUserUids.contains('user-uid'), isFalse);

      // Say Amen
      await notifier.sayAmenToCircleIntention(circleId, intentionId);

      final stateAfter1 = container.read(communityStateProvider);
      final targetAfter1 = stateAfter1.circleIntentions.firstWhere((ci) => ci.id == intentionId);
      expect(targetAfter1.amenCount, 1);
      expect(targetAfter1.amenUserUids.contains('user-uid'), isTrue);

      // Tap Amen again (toggles off)
      await notifier.sayAmenToCircleIntention(circleId, intentionId);

      final stateAfter2 = container.read(communityStateProvider);
      final targetAfter2 = stateAfter2.circleIntentions.firstWhere((ci) => ci.id == intentionId);
      expect(targetAfter2.amenCount, 0);
      expect(targetAfter2.amenUserUids.contains('user-uid'), isFalse);
    });
  });
}
