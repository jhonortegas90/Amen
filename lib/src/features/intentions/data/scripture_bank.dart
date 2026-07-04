import 'dart:math';

import '../domain/intention.dart';

class ScriptureItem {
  const ScriptureItem({
    required this.verse,
    required this.reference,
    required this.shortReflection,
  });

  final String verse;
  final String reference;
  final String shortReflection;
}

class ScriptureBank {
  static final _random = Random();

  static final Map<PrayerCategory, List<ScriptureItem>> _categoryBank = {
    PrayerCategory.healing: [
      const ScriptureItem(
        verse: 'He heals the brokenhearted and binds up their wounds.',
        reference: 'Psalm 147:3',
        shortReflection: 'May God restore health and comfort to body and spirit.',
      ),
      const ScriptureItem(
        verse: 'Lord my God, I called to you for help, and you healed me.',
        reference: 'Psalm 30:2',
        shortReflection: 'Standing in agreement for restoration and divine strength.',
      ),
      const ScriptureItem(
        verse: 'He sent out his word and healed them; he rescued them from the grave.',
        reference: 'Psalm 107:20',
        shortReflection: 'May light and healing peace surround this request.',
      ),
    ],
    PrayerCategory.grief: [
      const ScriptureItem(
        verse: 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
        reference: 'Psalm 34:18',
        shortReflection: 'You are not alone in sorrow. May peace rest gently upon your heart.',
      ),
      const ScriptureItem(
        verse: 'Blessed are those who mourn, for they will be comforted.',
        reference: 'Matthew 5:4',
        shortReflection: 'Praying for grace and gentle warmth in this hour of mourning.',
      ),
    ],
    PrayerCategory.gratitude: [
      const ScriptureItem(
        verse: 'Give thanks to the Lord, for he is good; his love endures forever.',
        reference: 'Psalm 107:1',
        shortReflection: 'Rejoicing with you in praise and thankful hearts.',
      ),
      const ScriptureItem(
        verse: 'Every good and perfect gift is from above, coming down from the Father of the heavenly lights.',
        reference: 'James 1:17',
        shortReflection: 'Joining in gratitude for God’s abundant blessings.',
      ),
    ],
    PrayerCategory.strength: [
      const ScriptureItem(
        verse: 'The Lord is my strength and my shield; my heart trusts in him, and he helps me.',
        reference: 'Psalm 28:7',
        shortReflection: 'May courage replace fear as you lean upon His strength.',
      ),
      const ScriptureItem(
        verse: 'I can do all this through him who gives me strength.',
        reference: 'Philippians 4:13',
        shortReflection: 'Praying for boldness, endurance, and quiet confidence.',
      ),
    ],
    PrayerCategory.peace: [
      const ScriptureItem(
        verse: 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
        reference: 'Philippians 4:6',
        shortReflection: 'Releasing anxiety into the hands of the Almighty.',
      ),
      const ScriptureItem(
        verse: 'Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.',
        reference: 'John 14:27',
        shortReflection: 'May stillness blanket your mind and bring calm to your spirit.',
      ),
    ],
    PrayerCategory.guidance: [
      const ScriptureItem(
        verse: 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
        reference: 'Proverbs 3:5-6',
        shortReflection: 'Praying for clear wisdom and divine direction.',
      ),
      const ScriptureItem(
        verse: 'Your word is a lamp for my feet, a light on my path.',
        reference: 'Psalm 119:105',
        shortReflection: 'May every next step be guided by light and truth.',
      ),
    ],
    PrayerCategory.general: [
      const ScriptureItem(
        verse: 'Therefore I tell you, whatever you ask for in prayer, believe that you have received it, and it will be yours.',
        reference: 'Mark 11:24',
        shortReflection: 'Joining in faith with you before the Throne of Grace.',
      ),
      const ScriptureItem(
        verse: 'For where two or three gather in my name, there am I with them.',
        reference: 'Matthew 18:20',
        shortReflection: 'United in anonymous fellowship and prayer across the world.',
      ),
    ],
  };

  static ScriptureItem getScriptureForCategory(PrayerCategory category) {
    final list = _categoryBank[category] ?? _categoryBank[PrayerCategory.general]!;
    return list[_random.nextInt(list.length)];
  }
}
