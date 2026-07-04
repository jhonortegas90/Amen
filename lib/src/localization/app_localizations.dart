import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('es'), Locale('fr')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get _language {
    final code = locale.languageCode.toLowerCase();
    return supportedLocales.any((item) => item.languageCode == code)
        ? code
        : 'en';
  }

  String _pick(Map<String, String> values) =>
      values[_language] ?? values['en']!;

  String get appName => 'Amen';
  String get globalEchoWall => _pick({
    'en': 'Global Echo Wall',
    'es': 'Muro Eco Global',
    'fr': 'Mur Echo Mondial',
  });
  String get anonymousUnited => _pick({
    'en': 'Anonymous. United in prayer.',
    'es': 'Anónimos. Unidos en oración.',
    'fr': 'Anonymes. Unis dans la prière.',
  });
  String get pinned =>
      _pick({'en': 'Pinned', 'es': 'Fijada', 'fr': 'Épinglée'});
  String get amen => 'Amen';
  String get sharePrayer => _pick({
    'en': 'Share a prayer',
    'es': 'Comparte una oración',
    'fr': 'Partager une prière',
  });
  String get composeTitle => _pick({
    'en': 'Place a quiet prayer on the wall.',
    'es': 'Deja una oración silenciosa en el muro.',
    'fr': 'Dépose une prière silencieuse sur le mur.',
  });
  String get composeHint => _pick({
    'en': 'What are you carrying tonight?',
    'es': '¿Qué llevas contigo esta noche?',
    'fr': 'Que portes-tu ce soir ?',
  });
  String get postPrayer => _pick({
    'en': 'Post prayer',
    'es': 'Publicar oración',
    'fr': 'Publier la prière',
  });
  String get tooLong => _pick({
    'en': 'Keep it within 250 characters.',
    'es': 'Mantén el texto dentro de 250 caracteres.',
    'fr': 'Garde le texte sous 250 caractères.',
  });
  String get emptyPrayer => _pick({
    'en': 'Write a short prayer first.',
    'es': 'Escribe primero una oración breve.',
    'fr': 'Écris d’abord une courte prière.',
  });
  String get blockedPrayer => _pick({
    'en': 'Please soften this wording before posting.',
    'es': 'Suaviza estas palabras antes de publicar.',
    'fr': 'Adoucis ces mots avant de publier.',
  });
  String get someoneSaidAmen => _pick({
    'en': 'Someone just said Amen to your prayer.',
    'es': 'Alguien acaba de decir Amén a tu oración.',
    'fr': 'Quelqu’un vient de dire Amen à ta prière.',
  });
  String get oneWorld => _pick({
    'en': 'One world. One prayer.',
    'es': 'Un mundo. Una oración.',
    'fr': 'Un monde. Une prière.',
  });
  String get pinToTop =>
      _pick({'en': 'Pin to Top', 'es': 'Fijar arriba', 'fr': 'Épingler'});
  String get sponsoredPause => _pick({
    'en': 'A quiet pause from our sponsor',
    'es': 'Una pausa tranquila de nuestro patrocinador',
    'fr': 'Une pause douce de notre partenaire',
  });
  String get demoMode => _pick({
    'en': 'Demo mode until Firebase options are installed.',
    'es': 'Modo demo hasta instalar las opciones de Firebase.',
    'fr': 'Mode démo jusqu’à l’installation des options Firebase.',
  });
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
