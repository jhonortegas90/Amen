class OnboardingConfig {
  const OnboardingConfig._();

  static const String googleButtonText = 'Sign in with Google';
  static const String appleButtonText = 'Sign in with Apple';

  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String termsOfServiceTitle = 'Terms of Service';

  /// List of high-resolution image URLs for the continuous animated collage.
  /// Easily update or replace these URLs with your own custom images or local assets.
  static const List<String> collageImages = [
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80', // Sunrise ocean peace
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=800&q=80', // Mountain nature light
    'https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=800&q=80', // Family warmth & togetherness
    'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80', // Peaceful meditation & prayer
    'https://images.unsplash.com/photo-1470240731273-7821a6eeb6bd?auto=format&fit=crop&w=800&q=80', // Rays of sunlight in forest
    'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?auto=format&fit=crop&w=800&q=80', // Golden sky sunset
    'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=800&q=80', // Gentle leaves & sunlight
    'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=800&q=80', // Forest path light
    'https://images.unsplash.com/photo-1499209974431-9dac3ada00d7?auto=format&fit=crop&w=800&q=80', // Calm lake reflection
  ];

  static const String privacyPolicyText = '''
Privacy & Data Commitment:
• Your prayers are 100% anonymous on the global wall.
• We never sell, rent, or trade your personal data.
• Social authentication (Google & Apple) is used solely to secure your account and sync your saved preferences across devices.
• You can delete your account and data at any time from settings.
''';

  static const String termsOfServiceText = '''
Community Guidelines & Terms:
• Amen is a sacred, respectful space for prayer, gratitude, and reflection.
• Harassment, hate speech, abusive language, or profanity is strictly prohibited and filtered automatically.
• Violations will result in content removal and account suspension.
''';
}
