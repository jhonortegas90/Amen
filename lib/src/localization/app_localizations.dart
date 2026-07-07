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
  String get home => _pick({'en': 'Home', 'es': 'Inicio', 'fr': 'Accueil'});
  String get community =>
      _pick({'en': 'Community', 'es': 'Comunidad', 'fr': 'Communauté'});
  String get pray => _pick({'en': 'Pray', 'es': 'Orar', 'fr': 'Prier'});
  String get journal =>
      _pick({'en': 'Journal', 'es': 'Diario', 'fr': 'Journal'});
  String get altar => _pick({'en': 'Altar', 'es': 'Altar', 'fr': 'Autel'});
  String get profile =>
      _pick({'en': 'Profile', 'es': 'Perfil', 'fr': 'Profil'});
  String get goodAfternoon => _pick({
    'en': 'Good afternoon',
    'es': 'Buenas tardes',
    'fr': 'Bon après-midi',
  });
  String get takeQuietMoment => _pick({
    'en': 'Take a quiet moment.',
    'es': 'Toma un momento de calma.',
    'fr': 'Prends un moment de calme.',
  });
  String get notifications => _pick({
    'en': 'Notifications',
    'es': 'Notificaciones',
    'fr': 'Notifications',
  });
  String get yourPrayerRhythm => _pick({
    'en': 'Your prayer rhythm',
    'es': 'Tu ritmo de oración',
    'fr': 'Ton rythme de prière',
  });
  String get eveningReflection => _pick({
    'en': 'Evening reflection',
    'es': 'Reflexión de la noche',
    'fr': 'Réflexion du soir',
  });
  String get eveningReflectionBody => _pick({
    'en': 'Take three minutes to release today and record one gratitude.',
    'es': 'Toma tres minutos para soltar el día y guardar una gratitud.',
    'fr':
        'Prends trois minutes pour déposer la journée et noter une gratitude.',
  });
  String get beginReflection => _pick({
    'en': 'Begin reflection',
    'es': 'Comenzar reflexión',
    'fr': 'Commencer',
  });
  String get viewFullRoutine => _pick({
    'en': 'View full routine',
    'es': 'Ver rutina completa',
    'fr': 'Voir la routine',
  });
  String get quickActions => _pick({
    'en': 'Quick actions',
    'es': 'Acciones rápidas',
    'fr': 'Actions rapides',
  });
  String get prayForSomeone => _pick({
    'en': 'Pray for someone',
    'es': 'Orar por alguien',
    'fr': 'Prier pour quelqu’un',
  });
  String get prayerRoom => _pick({
    'en': 'Prayer Room',
    'es': 'Sala de oración',
    'fr': 'Salle de prière',
  });
  String get prayerCompass => _pick({
    'en': 'Prayer Compass',
    'es': 'Brújula de oración',
    'fr': 'Boussole de prière',
  });
  String get continuePraying => _pick({
    'en': 'Continue praying',
    'es': 'Continuar orando',
    'fr': 'Continuer à prier',
  });
  String get prayerForPeace => _pick({
    'en': 'Prayer for peace during uncertainty',
    'es': 'Oración por paz en la incertidumbre',
    'fr': 'Prière pour la paix dans l’incertitude',
  });
  String get threeMinutesRemaining => _pick({
    'en': '3 minutes remaining',
    'es': 'Quedan 3 minutos',
    'fr': '3 minutes restantes',
  });
  String get continueAction =>
      _pick({'en': 'Continue', 'es': 'Continuar', 'fr': 'Continuer'});
  String get yourPrayerCommunity => _pick({
    'en': 'Your prayer community',
    'es': 'Tu comunidad de oración',
    'fr': 'Ta communauté de prière',
  });
  String get prayedForYourIntention => _pick({
    'en': '12 people prayed for your intention.',
    'es': '12 personas oraron por tu intención.',
    'fr': '12 personnes ont prié pour ton intention.',
  });
  String get circleUpdateSummary => _pick({
    'en': 'Family Circle shared a gratitude update.',
    'es': 'Círculo familiar compartió una gratitud.',
    'fr': 'Le cercle familial a partagé une gratitude.',
  });
  String get viewActivity => _pick({
    'en': 'View activity',
    'es': 'Ver actividad',
    'fr': 'Voir l’activité',
  });
  String get viewCircles => _pick({
    'en': 'View circles',
    'es': 'Ver círculos',
    'fr': 'Voir les cercles',
  });
  String get someoneWaiting => _pick({
    'en': 'Someone is waiting for prayer',
    'es': 'Alguien espera una oración',
    'fr': 'Quelqu’un attend une prière',
  });
  String get standWithOnePerson => _pick({
    'en': 'Take two minutes to stand with one person today.',
    'es': 'Toma dos minutos para acompañar a una persona hoy.',
    'fr': 'Prends deux minutes pour accompagner une personne aujourd’hui.',
  });
  String get prayersOfferedToday => _pick({
    'en': '418 prayers offered today',
    'es': '418 oraciones ofrecidas hoy',
    'fr': '418 prières offertes aujourd’hui',
  });
  String get yourPrayerJourney => _pick({
    'en': 'Your prayer journey',
    'es': 'Tu camino de oración',
    'fr': 'Ton chemin de prière',
  });
  String get active =>
      _pick({'en': 'active', 'es': 'activas', 'fr': 'actives'});
  String get answered =>
      _pick({'en': 'answered', 'es': 'respondidas', 'fr': 'exaucées'});
  String get gratitudeMoments => _pick({
    'en': 'gratitude moments',
    'es': 'gratitudes',
    'fr': 'gratitudes',
  });
  String get openJournal => _pick({
    'en': 'Open journal',
    'es': 'Abrir diario',
    'fr': 'Ouvrir le journal',
  });
  String get privateCircles => _pick({
    'en': 'Private circles',
    'es': 'Círculos privados',
    'fr': 'Cercles privés',
  });
  String get createPrivateCircle => _pick({
    'en': 'Create a private circle for family or friends.',
    'es': 'Crea un círculo privado para familia o amistades.',
    'fr': 'Crée un cercle privé pour la famille ou les amis.',
  });
  String get createCircle => _pick({
    'en': 'Create a circle',
    'es': 'Crear círculo',
    'fr': 'Créer un cercle',
  });
  String get gratefulPrompt => _pick({
    'en': 'What are you grateful for today?',
    'es': '¿Por qué das gracias hoy?',
    'fr': 'Pour quoi es-tu reconnaissant aujourd’hui ?',
  });
  String get savePrivately => _pick({
    'en': 'Save privately',
    'es': 'Guardar en privado',
    'fr': 'Enregistrer en privé',
  });
  String get journalSubtitle => _pick({
    'en': 'Personal requests, answered prayers, and gratitude rhythms.',
    'es': 'Peticiones personales, oraciones respondidas y ritmos de gratitud.',
    'fr': 'Demandes personnelles, prières exaucées et rythmes de gratitude.',
  });
  String get activeJournalEmptyTitle => _pick({
    'en': 'Your active requests',
    'es': 'Tus peticiones activas',
    'fr': 'Tes demandes actives',
  });
  String get activeJournalEmptyBody => _pick({
    'en':
        'Write down your personal needs, intentions, or struggles to keep them in focus during your prayer time.',
    'es':
        'Escribe tus necesidades personales, intenciones o luchas para mantenerlas enfocadas durante tu tiempo de oración.',
    'fr':
        'Note tes besoins personnels, intentions ou combats pour les garder à l\'esprit pendant ton temps de prière.',
  });
  String get answeredJournalEmptyTitle => _pick({
    'en': 'Answered prayers',
    'es': 'Oraciones respondidas',
    'fr': 'Prières exaucées',
  });
  String get answeredJournalEmptyBody => _pick({
    'en':
        "When a request is answered, mark it as answered to move it here and celebrate God's faithfulness.",
    'es':
        'Cuando una petición sea respondida, márcala como respondida para moverla aquí y celebrar la fidelidad de Dios.',
    'fr':
        "Lorsqu'une demande est exaucée, marque-la comme exaucée pour la déplacer ici et célébrer la fidélité de Dieu.",
  });
  String get gratitudeJournalEmptyTitle => _pick({
    'en': 'Gratitude rhythm',
    'es': 'Ritmo de gratitud',
    'fr': 'Rythme de gratitude',
  });
  String get gratitudeJournalEmptyBody => _pick({
    'en':
        'Keep track of daily moments of joy, grace, and thanks. Use the input field above to write them down.',
    'es':
        'Registra tus momentos diarios de alegría, gracia y agradecimiento. Usa el campo de entrada de arriba para escribirlos.',
    'fr':
        'Garde une trace des moments quotidiens de joie, de grâce et de remerciement. Utilise le champ de saisie ci-dessus pour les écrire.',
  });
  String get activeLabel =>
      _pick({'en': 'Active', 'es': 'Activas', 'fr': 'Actives'});
  String get answeredLabel =>
      _pick({'en': 'Answered', 'es': 'Respondidas', 'fr': 'Exaucées'});
  String get gratitudeLabel =>
      _pick({'en': 'Gratitude', 'es': 'Gratitud', 'fr': 'Gratitude'});
  String get gratitudeHint => _pick({
    'en': 'Today I am grateful for...',
    'es': 'Hoy doy gracias por...',
    'fr': 'Aujourd’hui, je suis reconnaissant pour...',
  });
  String get saveGratitude => _pick({
    'en': 'Save gratitude',
    'es': 'Guardar gratitud',
    'fr': 'Enregistrer la gratitude',
  });
  String get archivedWithGratitude => _pick({
    'en': 'Archived with gratitude',
    'es': 'Archivada con gratitud',
    'fr': 'Archivée avec gratitude',
  });
  String get justNow =>
      _pick({'en': 'Just now', 'es': 'Ahora mismo', 'fr': 'À l’instant'});
  String get savedThisWeek => _pick({
    'en': 'Saved this week',
    'es': 'Guardada esta semana',
    'fr': 'Enregistrée cette semaine',
  });
  String get back => _pick({'en': 'Back', 'es': 'Atrás', 'fr': 'Retour'});
  String get close => _pick({'en': 'Close', 'es': 'Cerrar', 'fr': 'Fermer'});
  String get cancel =>
      _pick({'en': 'Cancel', 'es': 'Cancelar', 'fr': 'Annuler'});
  String get delete =>
      _pick({'en': 'Delete', 'es': 'Eliminar', 'fr': 'Supprimer'});
  String get view => _pick({'en': 'View', 'es': 'Ver', 'fr': 'Voir'});
  String get accept =>
      _pick({'en': 'Accept', 'es': 'Aceptar', 'fr': 'Accepter'});
  String get dismiss =>
      _pick({'en': 'Dismiss', 'es': 'Descartar', 'fr': 'Ignorer'});
  String get pause => _pick({'en': 'Pause', 'es': 'Pausar', 'fr': 'Pause'});
  String get resume =>
      _pick({'en': 'Resume', 'es': 'Reanudar', 'fr': 'Reprendre'});
  String get pauseScroll => _pick({
    'en': 'Pause scroll',
    'es': 'Pausar scroll',
    'fr': 'Pause défilement',
  });
  String get startScroll => _pick({
    'en': 'Start scroll',
    'es': 'Iniciar scroll',
    'fr': 'Lancer défilement',
  });
  String get publicLabel =>
      _pick({'en': 'Public', 'es': 'Pública', 'fr': 'Publique'});
  String get privateLabel =>
      _pick({'en': 'Private', 'es': 'Privada', 'fr': 'Privée'});
  String get submitAnonymously => _pick({
    'en': 'Submit anonymously',
    'es': 'Enviar de forma anónima',
    'fr': 'Envoyer anonymement',
  });
  String get shownWithoutName => _pick({
    'en': 'Shown without your name.',
    'es': 'Se muestra sin tu nombre.',
    'fr': 'Affiché sans ton nom.',
  });
  String get linkedToProfile => _pick({
    'en': 'Linked to your signed-in profile.',
    'es': 'Vinculado a tu perfil conectado.',
    'fr': 'Lié à ton profil connecté.',
  });
  String get categoryTopic => _pick({
    'en': 'Category / Topic:',
    'es': 'Categoría / tema:',
    'fr': 'Catégorie / sujet :',
  });
  String get publicRequestSent => _pick({
    'en': 'Your request was sent out in prayer.',
    'es': 'Tu petición fue enviada en oración.',
    'fr': 'Ta demande a été envoyée en prière.',
  });
  String get privateRequestSaved => _pick({
    'en': 'Your private request was saved for your journal.',
    'es': 'Tu petición privada se guardó en tu diario.',
    'fr': 'Ta demande privée a été enregistrée dans ton journal.',
  });
  String get sendOutMyRequest => _pick({
    'en': 'Send Out My Request',
    'es': 'Enviar mi petición',
    'fr': 'Envoyer ma demande',
  });
  String get prayButton => _pick({'en': 'Pray', 'es': 'Orar', 'fr': 'Prier'});
  String get intercedingForRequest => _pick({
    'en': 'Interceding in Prayer',
    'es': 'Intercediendo en oración',
    'fr': 'Intercession dans la prière',
  });
  String get iHavePrayedForYou => _pick({
    'en': 'I have prayed for you',
    'es': 'He orado por ti',
    'fr': "J'ai prié pour toi",
  });
  String get aPrayerForIntention => _pick({
    'en': 'A Prayer for this Request',
    'es': 'Una oración por esta petición',
    'fr': 'Une prière pour cette demande',
  });
  String get sendSupport => _pick({
    'en': 'Send support',
    'es': 'Enviar apoyo',
    'fr': 'Envoyer du soutien',
  });
  String liftedUpCount(int count) => _pick({
    'en': '$count lifted up',
    'es': '$count oraciones',
    'fr': '$count prières',
  });
  String get noPrayerRequestsYet => _pick({
    'en': 'No prayer requests yet. Be the first to send one out.',
    'es': 'Aún no hay peticiones. Sé la primera persona en enviar una.',
    'fr':
        'Aucune demande pour le moment. Sois la première personne à en envoyer une.',
  });
  String get readAll =>
      _pick({'en': 'Read All', 'es': 'Leer todo', 'fr': 'Tout lire'});
  String get allLabel => _pick({'en': 'All', 'es': 'Todo', 'fr': 'Tout'});
  String get messagesLabel =>
      _pick({'en': 'Messages', 'es': 'Mensajes', 'fr': 'Messages'});
  String unreadCount(int count) => _pick({
    'en': '$count unread',
    'es': '$count sin leer',
    'fr': '$count non lues',
  });
  String get allNotificationsRead => _pick({
    'en': 'All notifications marked as read.',
    'es': 'Todas las notificaciones se marcaron como leídas.',
    'fr': 'Toutes les notifications ont été marquées comme lues.',
  });
  String errorLoadingNotifications(Object error) => _pick({
    'en': 'Error loading notifications: $error',
    'es': 'Error al cargar notificaciones: $error',
    'fr': 'Erreur lors du chargement des notifications : $error',
  });
  String get emptyNotificationsTitle => _pick({
    'en': 'Your Prayer Activity Feed',
    'es': 'Tu actividad de oración',
    'fr': 'Ton fil d’activité de prière',
  });
  String get emptyNotificationsBody => _pick({
    'en':
        'When fellow believers pray "Amen" or leave an encouraging support message on your prayer requests, you will see them here.',
    'es':
        'Cuando otros creyentes oren "Amén" o dejen un mensaje de apoyo en tus peticiones, lo verás aquí.',
    'fr':
        'Quand d’autres croyants prient « Amen » ou laissent un message de soutien sur tes demandes, tu les verras ici.',
  });
  String get friends => _pick({'en': 'Friends', 'es': 'Amigos', 'fr': 'Amis'});
  String get invites =>
      _pick({'en': 'Invites', 'es': 'Invitaciones', 'fr': 'Invitations'});
  String get urgentMentions => _pick({
    'en': '3 urgent mentions',
    'es': '3 menciones urgentes',
    'fr': '3 mentions urgentes',
  });
  String get urgentMentionsBody => _pick({
    'en': 'Private circles are asking you to pray today.',
    'es': 'Tus círculos privados te piden orar hoy.',
    'fr': 'Tes cercles privés te demandent de prier aujourd’hui.',
  });
  String get signOut =>
      _pick({'en': 'Sign Out', 'es': 'Cerrar sesión', 'fr': 'Se déconnecter'});
  String get signInWithGoogle => _pick({
    'en': 'Sign in with Google',
    'es': 'Iniciar con Google',
    'fr': 'Connexion Google',
  });
  String get signInWithApple => _pick({
    'en': 'Sign in with Apple',
    'es': 'Iniciar con Apple',
    'fr': 'Connexion Apple',
  });
  String get continueAnonymously => _pick({
    'en': 'Continue Anonymously',
    'es': 'Continuar anónimamente',
    'fr': 'Continuer anonymement',
  });
  String get continueAsGuest => _pick({
    'en': 'Continue as Guest',
    'es': 'Continuar como invitado',
    'fr': 'Continuer comme invité',
  });
  String get sendThanks =>
      _pick({'en': 'Send Thanks', 'es': 'Enviar gracias', 'fr': 'Remercier'});
  String get sayAmenBack => _pick({
    'en': 'Say Amen Back',
    'es': 'Responder Amén',
    'fr': 'Répondre Amen',
  });
  String get signInConnectAccount => _pick({
    'en': 'Sign In / Connect Account',
    'es': 'Iniciar / conectar cuenta',
    'fr': 'Connexion / lier le compte',
  });
  String get resetToDefault => _pick({
    'en': 'Reset to Default (100%)',
    'es': 'Restablecer (100 %)',
    'fr': 'Réinitialiser (100 %)',
  });
  String get selectLanguage => _pick({
    'en': 'Select Language',
    'es': 'Seleccionar idioma',
    'fr': 'Choisir la langue',
  });
  String get fontSizeAdjustment => _pick({
    'en': 'Font Size Adjustment',
    'es': 'Ajuste de tamaño de letra',
    'fr': 'Réglage de la taille du texte',
  });
  String get profilePreferencesSubtitle => _pick({
    'en': 'Preferences for language, notifications, and accessibility.',
    'es': 'Preferencias de idioma, notificaciones y accesibilidad.',
    'fr': 'Préférences de langue, notifications et accessibilité.',
  });
  String get preferences =>
      _pick({'en': 'Preferences', 'es': 'Preferencias', 'fr': 'Préférences'});
  String get aboutLegal => _pick({
    'en': 'About & Legal',
    'es': 'Acerca de y legal',
    'fr': 'À propos et légal',
  });
  String get accountSettings => _pick({
    'en': 'Account Settings',
    'es': 'Configuración de cuenta',
    'fr': 'Paramètres du compte',
  });
  String get privacyPolicy => _pick({
    'en': 'Privacy Policy',
    'es': 'Política de privacidad',
    'fr': 'Politique de confidentialité',
  });
  String get termsOfService => _pick({
    'en': 'Terms of Service',
    'es': 'Términos de servicio',
    'fr': 'Conditions d’utilisation',
  });
  String get readPrivacyPractices => _pick({
    'en': 'Read our privacy practices.',
    'es': 'Lee nuestras prácticas de privacidad.',
    'fr': 'Lis nos pratiques de confidentialité.',
  });
  String get readTermsConditions => _pick({
    'en': 'Read our terms & conditions.',
    'es': 'Lee nuestros términos y condiciones.',
    'fr': 'Lis nos conditions générales.',
  });
  String get gentleRemindersEnabled => _pick({
    'en': 'Gentle reminders enabled.',
    'es': 'Recordatorios suaves activados.',
    'fr': 'Rappels doux activés.',
  });
  String get notificationsTurnedOff => _pick({
    'en': 'Notifications turned off.',
    'es': 'Notificaciones desactivadas.',
    'fr': 'Notifications désactivées.',
  });
  String adjustFontSize(int percentage) => _pick({
    'en': 'Adjust text font size ($percentage%).',
    'es': 'Ajusta el tamaño del texto ($percentage %).',
    'fr': 'Ajuste la taille du texte ($percentage %).',
  });
  String get beginYourJourney => _pick({
    'en': 'Begin Your Journey',
    'es': 'Comienza tu camino',
    'fr': 'Commence ton chemin',
  });
  String get guestAccount => _pick({
    'en': 'Guest Account',
    'es': 'Cuenta de invitado',
    'fr': 'Compte invité',
  });
  String get guestSignInBody => _pick({
    'en':
        'Sign in to synchronize your prayers, save private journals, and share intentions with the community across all your devices.',
    'es':
        'Inicia sesión para sincronizar tus oraciones, guardar diarios privados y compartir intenciones en todos tus dispositivos.',
    'fr':
        'Connecte-toi pour synchroniser tes prières, enregistrer tes journaux privés et partager des intentions sur tous tes appareils.',
  });
  String get logOutBody => _pick({
    'en': 'Log out from your current session.',
    'es': 'Cierra tu sesión actual.',
    'fr': 'Déconnecte-toi de ta session actuelle.',
  });
  String get dangerZone => _pick({
    'en': 'Danger Zone',
    'es': 'Zona de peligro',
    'fr': 'Zone de danger',
  });
  String get deleteAccountWarning => _pick({
    'en':
        'Permanently delete your account and all associated data. This action cannot be undone.',
    'es':
        'Elimina permanentemente tu cuenta y todos los datos asociados. Esta acción no se puede deshacer.',
    'fr':
        'Supprime définitivement ton compte et toutes les données associées. Cette action est irréversible.',
  });
  String get deleteAccountConfirm => _pick({
    'en':
        'Are you sure you want to permanently delete your account? This action cannot be undone.',
    'es':
        '¿Seguro que quieres eliminar permanentemente tu cuenta? Esta acción no se puede deshacer.',
    'fr':
        'Veux-tu vraiment supprimer définitivement ton compte ? Cette action est irréversible.',
  });
  String get deleteAccount => _pick({
    'en': 'Delete Account',
    'es': 'Eliminar cuenta',
    'fr': 'Supprimer le compte',
  });
  String get reportPost => _pick({
    'en': 'Report Post',
    'es': 'Reportar publicación',
    'fr': 'Signaler la publication',
  });
  String get submitReport => _pick({
    'en': 'Submit Report',
    'es': 'Enviar reporte',
    'fr': 'Envoyer le signalement',
  });
  String get reportPrompt => _pick({
    'en': 'Please select the reason for reporting this intention:',
    'es': 'Selecciona el motivo para reportar esta intención:',
    'fr': 'Choisis la raison du signalement de cette intention :',
  });
  String get reportThanks => _pick({
    'en': 'Thank you. Post reported for moderator review.',
    'es': 'Gracias. La publicación fue enviada a moderación.',
    'fr': 'Merci. La publication a été envoyée à la modération.',
  });
  String reportError(Object error) => _pick({
    'en': 'Could not submit report: $error',
    'es': 'No se pudo enviar el reporte: $error',
    'fr': 'Impossible d’envoyer le signalement : $error',
  });
  String reportSubmitted(String reason) => _pick({
    'en': 'Report submitted: $reason',
    'es': 'Reporte enviado: $reason',
    'fr': 'Signalement envoyé : $reason',
  });
  String reportReason(String reason) {
    final translated = <String, Map<String, String>>{
      'Harassment or Bullying': {
        'en': 'Harassment or Bullying',
        'es': 'Acoso o intimidación',
        'fr': 'Harcèlement ou intimidation',
      },
      'Offensive Language or Hate': {
        'en': 'Offensive Language or Hate',
        'es': 'Lenguaje ofensivo u odio',
        'fr': 'Langage offensant ou haine',
      },
      'Self-Harm or Violence': {
        'en': 'Self-Harm or Violence',
        'es': 'Autolesión o violencia',
        'fr': 'Automutilation ou violence',
      },
      'Spam or Commercial Post': {
        'en': 'Spam or Commercial Post',
        'es': 'Spam o publicación comercial',
        'fr': 'Spam ou publication commerciale',
      },
      'Other Safety Concern': {
        'en': 'Other Safety Concern',
        'es': 'Otra preocupación de seguridad',
        'fr': 'Autre problème de sécurité',
      },
    }[reason];

    return translated == null ? reason : _pick(translated);
  }

  String prayerCategory(String category) {
    final translated = <String, Map<String, String>>{
      'General': {'en': 'General', 'es': 'General', 'fr': 'Général'},
      'Healing': {'en': 'Healing', 'es': 'Sanidad', 'fr': 'Guérison'},
      'Comfort & Grief': {
        'en': 'Comfort & Grief',
        'es': 'Consuelo y duelo',
        'fr': 'Réconfort et deuil',
      },
      'Gratitude': {'en': 'Gratitude', 'es': 'Gratitud', 'fr': 'Gratitude'},
      'Strength & Courage': {
        'en': 'Strength & Courage',
        'es': 'Fuerza y valor',
        'fr': 'Force et courage',
      },
      'Peace in Anxiety': {
        'en': 'Peace in Anxiety',
        'es': 'Paz en ansiedad',
        'fr': 'Paix dans l’anxiété',
      },
      'Guidance': {'en': 'Guidance', 'es': 'Guía', 'fr': 'Direction'},
    }[category];

    return translated == null ? category : _pick(translated);
  }

  String libraryCategory(String category) {
    final translated = <String, Map<String, String>>{
      'All': {'en': 'All', 'es': 'Todo', 'fr': 'Tout'},
      'Morning': {'en': 'Morning', 'es': 'Mañana', 'fr': 'Matin'},
      'Anxiety & Peace': {
        'en': 'Anxiety & Peace',
        'es': 'Ansiedad y paz',
        'fr': 'Anxiété et paix',
      },
      'Healing': {'en': 'Healing', 'es': 'Sanidad', 'fr': 'Guérison'},
      'Evening': {'en': 'Evening', 'es': 'Noche', 'fr': 'Soir'},
      'Strength': {'en': 'Strength', 'es': 'Fuerza', 'fr': 'Force'},
    }[category];

    return translated == null ? category : _pick(translated);
  }

  String get altarSubtitle => _pick({
    'en': 'Guided prayers for focused, teleprompter-style reflection.',
    'es': 'Oraciones guiadas para una reflexión enfocada.',
    'fr': 'Prières guidées pour une réflexion concentrée.',
  });
  String get supportMessageSent => _pick({
    'en': 'Your encouraging message has been sent in prayer!',
    'es': 'Tu mensaje de ánimo fue enviado en oración.',
    'fr': 'Ton message d’encouragement a été envoyé en prière.',
  });
  String supportMessageError(Object error) => _pick({
    'en': 'Could not send message: $error',
    'es': 'No se pudo enviar el mensaje: $error',
    'fr': 'Impossible d’envoyer le message : $error',
  });
  String get sendPrayerSupportNote => _pick({
    'en': 'Send Prayer Support Note',
    'es': 'Enviar nota de apoyo',
    'fr': 'Envoyer une note de soutien',
  });
  String get supportNoteSubtitle => _pick({
    'en': 'Leave a message of encouragement for this request',
    'es': 'Deja un mensaje de ánimo para esta petición',
    'fr': 'Laisse un message d’encouragement pour cette demande',
  });
  String get supportMessageHint => _pick({
    'en':
        'e.g. Standing in faith with you! May God comfort your heart and bring healing...',
    'es': 'Ej. Oro contigo. Que Dios consuele tu corazón y traiga sanidad...',
    'fr':
        'Ex. Je prie avec toi. Que Dieu console ton cœur et apporte la guérison...',
  });
  String get yourNameOptional => _pick({
    'en': 'Your Name (optional)',
    'es': 'Tu nombre (opcional)',
    'fr': 'Ton nom (facultatif)',
  });
  String get sendAnonymouslyAsBeliever => _pick({
    'en': 'Send anonymously as "Believer in Christ"',
    'es': 'Enviar anónimamente como "Creyente en Cristo"',
    'fr': 'Envoyer anonymement comme « Croyant en Christ »',
  });
  String get sendEncouragement => _pick({
    'en': 'Send Encouragement',
    'es': 'Enviar ánimo',
    'fr': 'Envoyer encouragement',
  });
  String get leaveNote =>
      _pick({'en': 'Leave Note', 'es': 'Dejar nota', 'fr': 'Laisser une note'});
  String get amenAndClose => _pick({
    'en': 'Amen & Close',
    'es': 'Amén y cerrar',
    'fr': 'Amen et fermer',
  });
  String get amenConfirmed => _pick({
    'en': 'AMEN CONFIRMED',
    'es': 'AMÉN CONFIRMADO',
    'fr': 'AMEN CONFIRMÉ',
  });
  String joinedPrayerFor(String category) => _pick({
    'en': 'You joined in prayer for "$category"',
    'es': 'Te uniste en oración por "$category"',
    'fr': 'Tu t’es uni en prière pour « $category »',
  });
  String get brotherSisterInFaith => _pick({
    'en': 'Brother/Sister in Faith',
    'es': 'Hermano/a en la fe',
    'fr': 'Frère/sœur dans la foi',
  });
  String get anonymousBeliever => _pick({
    'en': 'Anonymous Believer',
    'es': 'Creyente anónimo',
    'fr': 'Croyant anonyme',
  });
  String journalEntry(String text) {
    final translated = <String, Map<String, String>>{
      'Wisdom for a difficult conversation this week.': {
        'en': 'Wisdom for a difficult conversation this week.',
        'es': 'Sabiduría para una conversación difícil esta semana.',
        'fr': 'Sagesse pour une conversation difficile cette semaine.',
      },
      'Healing and steady peace for my family.': {
        'en': 'Healing and steady peace for my family.',
        'es': 'Sanidad y paz constante para mi familia.',
        'fr': 'Guérison et paix constante pour ma famille.',
      },
      'Courage to keep showing up with patience.': {
        'en': 'Courage to keep showing up with patience.',
        'es': 'Valor para seguir presente con paciencia.',
        'fr': 'Courage pour continuer à être présent avec patience.',
      },
      'A door opened for work after weeks of waiting.': {
        'en': 'A door opened for work after weeks of waiting.',
        'es': 'Se abrió una puerta laboral después de semanas de espera.',
        'fr':
            'Une porte s’est ouverte pour le travail après des semaines d’attente.',
      },
      'A restored conversation with an old friend.': {
        'en': 'A restored conversation with an old friend.',
        'es': 'Una conversación restaurada con una vieja amistad.',
        'fr': 'Une conversation restaurée avec un vieil ami.',
      },
      'A quiet morning and enough energy for today.': {
        'en': 'A quiet morning and enough energy for today.',
        'es': 'Una mañana tranquila y suficiente energía para hoy.',
        'fr': 'Un matin calme et assez d’énergie pour aujourd’hui.',
      },
      'Someone checked in at the right time.': {
        'en': 'Someone checked in at the right time.',
        'es': 'Alguien preguntó por mí en el momento justo.',
        'fr': 'Quelqu’un a pris des nouvelles au bon moment.',
      },
      'Dinner around the table.': {
        'en': 'Dinner around the table.',
        'es': 'Cena alrededor de la mesa.',
        'fr': 'Un dîner autour de la table.',
      },
    }[text];

    return translated == null ? text : _pick(translated);
  }

  String get ambience =>
      _pick({'en': 'Ambience', 'es': 'Ambiente', 'fr': 'Ambiance'});
  String get muted => _pick({'en': 'Muted', 'es': 'Silencio', 'fr': 'Muet'});
  String get playPause => _pick({
    'en': 'Play or pause',
    'es': 'Reproducir o pausar',
    'fr': 'Lire ou pause',
  });
  String get currentSound => _pick({
    'en': 'Quiet water and soft keys',
    'es': 'Agua tranquila y teclas suaves',
    'fr': 'Eau calme et notes douces',
  });
  String get musicVolume => _pick({
    'en': 'Music volume',
    'es': 'Volumen de música',
    'fr': 'Volume musique',
  });
  String get waterVolume => _pick({
    'en': 'Water volume',
    'es': 'Volumen de agua',
    'fr': 'Volume eau',
  });
  String get sessionTimer =>
      _pick({'en': 'Session timer', 'es': 'Temporizador', 'fr': 'Minuteur'});
  String get changeAmbience => _pick({
    'en': 'Change ambience',
    'es': 'Cambiar ambiente',
    'fr': 'Changer d’ambiance',
  });
  String get stopAudio => _pick({
    'en': 'Stop audio',
    'es': 'Detener audio',
    'fr': 'Arrêter l’audio',
  });
  String get prayerReceived => _pick({
    'en': 'Your prayer was received.',
    'es': 'Tu oración fue recibida.',
    'fr': 'Ta prière a été reçue.',
  });
  String get prayerHub => _pick({
    'en': 'Prayer Hub',
    'es': 'Centro de oración',
    'fr': 'Centre de prière',
  });
  String get savedPrayers => _pick({
    'en': 'Saved prayers',
    'es': 'Oraciones guardadas',
    'fr': 'Prières enregistrées',
  });
  String get recentSessions => _pick({
    'en': 'Recent sessions',
    'es': 'Sesiones recientes',
    'fr': 'Sessions récentes',
  });
  String get activePrayers => _pick({
    'en': 'Active prayers',
    'es': 'Oraciones activas',
    'fr': 'Prières actives',
  });
  String get answeredPrayers => _pick({
    'en': 'Answered prayers',
    'es': 'Oraciones respondidas',
    'fr': 'Prières exaucées',
  });
  String get language =>
      _pick({'en': 'Language', 'es': 'Idioma', 'fr': 'Langue'});
  String get accessibility => _pick({
    'en': 'Accessibility',
    'es': 'Accesibilidad',
    'fr': 'Accessibilité',
  });
  String get privacy =>
      _pick({'en': 'Privacy', 'es': 'Privacidad', 'fr': 'Confidentialité'});
  String get prayWallBadge => _pick({
    'en': 'PRAY WALL',
    'es': 'MURO DE ORACIÓN',
    'fr': 'MUR DE PRIÈRE',
  });
  String get liveWallBadge => _pick({
    'en': 'LIVE COMMUNITY',
    'es': 'COMUNIDAD EN VIVO',
    'fr': 'COMMUNAUTÉ EN DIRECT',
  });
  String get globalPrayWall => _pick({
    'en': 'Global Pray Wall',
    'es': 'Muro de Oración Global',
    'fr': 'Mur de Prière Mondial',
  });
  String get prayWallSubtitle => _pick({
    'en':
        'Live community prayer requests. Stand in faith with brothers & sisters around the world.',
    'es':
        'Peticiones de oración en vivo. Únete en fe con hermanos y hermanas de todo el mundo.',
    'fr':
        'Demandes de prière en direct. Restez uni dans la foi avec les frères et sœurs du monde entier.',
  });
  String get sayAmen =>
      _pick({'en': 'Say Amen', 'es': 'Decir Amén', 'fr': 'Dire Amen'});
  String get viewAllPrayers => _pick({
    'en': 'Give a Pray',
    'es': 'Dar una Oración',
    'fr': 'Donner une Prière',
  });
  String get shareYourPrayer => _pick({
    'en': 'Post Prayer',
    'es': 'Publicar Oración',
    'fr': 'Publier Prière',
  });
  String get amenPremium => 'Amen Premium';
  String get unlockUnlimitedPeace => _pick({
    'en': 'Unlock Unlimited Spiritual Peace',
    'es': 'Desbloquea Paz Espiritual Ilimitada',
    'fr': 'Débloquez une Paix Spirituelle Illimitée',
  });
  String get paywallSubtitle => _pick({
    'en':
        'Unlimited global prayer posts, full ambient audio library, ad-free experience & private circles.',
    'es':
        'Publicaciones de oración ilimitadas, biblioteca de audio ambiental completa, sin anuncios y círculos privados.',
    'fr':
        'Publications de prière illimitées, bibliothèque audio d’ambiance complète, sans publicité et cercles privés.',
  });
  String get yearlyPlanTitle => _pick({
    'en': 'Yearly (Best Value)',
    'es': 'Anual (Mejor Valor)',
    'fr': 'Annuel (Meilleure Offre)',
  });
  String get yearlyPrice => _pick({
    'en': '\$39.99 / year (\$3.33/mo)',
    'es': '\$39.99 / año (\$3.33/mes)',
    'fr': '39,99 \$ / an (3,33 \$/mois)',
  });
  String get monthlyPlanTitle =>
      _pick({'en': 'Monthly', 'es': 'Mensual', 'fr': 'Mensuel'});
  String get monthlyPrice => _pick({
    'en': '\$4.99 / month',
    'es': '\$4.99 / mes',
    'fr': '4,99 \$ / mois',
  });
  String get freeTrialBadge => _pick({
    'en': '7-DAY FREE TRIAL',
    'es': 'PRUEBA GRATIS 7 DÍAS',
    'fr': 'ESSAI GRATUIT 7 JOURS',
  });
  String get startFreeTrial => _pick({
    'en': 'Start 7-Day Free Trial',
    'es': 'Comenzar prueba gratis de 7 días',
    'fr': 'Commencer l’essai gratuit de 7 jours',
  });
  String get subscribeNow => _pick({
    'en': 'Subscribe Now',
    'es': 'Suscribirse ahora',
    'fr': 'S’abonner maintenant',
  });
  String get viewAllFeatures => _pick({
    'en': 'View All Premium Features',
    'es': 'Ver todas las funciones Premium',
    'fr': 'Voir toutes les fonctionnalités Premium',
  });
  String get premiumActive => _pick({
    'en': 'Amen Premium Active',
    'es': 'Amen Premium Activo',
    'fr': 'Amen Premium Actif',
  });
  String get premiumActiveSub => _pick({
    'en': 'Thank you for supporting our prayer ministry!',
    'es': '¡Gracias por apoyar nuestro ministerio de oración!',
    'fr': 'Merci de soutenir notre ministère de prière !',
  });
  String get cancelAnytime => _pick({
    'en': 'Cancel anytime. Safe & secure payment.',
    'es': 'Cancela cuando quieras. Pago seguro.',
    'fr': 'Annulez à tout moment. Paiement sécurisé.',
  });
  String get restorePurchase => _pick({
    'en': 'Restore Purchase',
    'es': 'Restaurar Compra',
    'fr': 'Raurer l’achat',
  });

  String get noCirclesJoinedYet => _pick({
    'en': 'No circles joined yet',
    'es': 'Aún no te has unido a ningún círculo',
    'fr': 'Aucun cercle rejoint pour le moment',
  });
  String get emptyCirclesExplanation => _pick({
    'en': 'Private circles let you share prayers and encouragement with trusted groups. You can create a new circle or wait for an invitation to join one.',
    'es': 'Los círculos privados te permiten compartir oraciones y palabras de aliento con grupos de confianza. Puedes crear un nuevo círculo o esperar una invitación para unirte a uno.',
    'fr': 'Les cercles privés vous permettent de partager des prières et des encouragements avec des groupes de confiance. Vous pouvez créer un nuevo cercle ou attendre une invitation pour en rejoindre un.',
  });
  String get joinWithCode => _pick({
    'en': 'Join with Code',
    'es': 'Unirse con código',
    'fr': 'Rejoindre avec un code',
  });
  String get createCircleButton => _pick({
    'en': 'Create Circle',
    'es': 'Crear círculo',
    'fr': 'Créer un cercle',
  });
  String get joinPrivateCircle => _pick({
    'en': 'Join Private Circle',
    'es': 'Unirse a círculo privado',
    'fr': 'Rejoindre un cercle privé',
  });
  String get enterInviteCode => _pick({
    'en': 'Enter the invitation code shared by the circle creator to join.',
    'es': 'Ingresa el código de invitación compartido por la persona creadora del círculo para unirte.',
    'fr': 'Saisissez le code d’invitation partagé par le créateur du cercle pour le rejoindre.',
  });
  String get joinAction => _pick({
    'en': 'Join',
    'es': 'Unirse',
    'fr': 'Rejoindre',
  });
  String get codeIsRequired => _pick({
    'en': 'Code is required',
    'es': 'El código es obligatorio',
    'fr': 'Le code est requis',
  });
  String get codeMustStartWithAmen => _pick({
    'en': 'Code must start with AMEN-',
    'es': 'El código debe comenzar con AMEN-',
    'fr': 'Le code doit commencer par AMEN-',
  });
  String get joinedCircleSuccess => _pick({
    'en': 'Successfully joined private circle!',
    'es': '¡Te has unido al círculo privado con éxito!',
    'fr': 'Cercle privé rejoint avec succès !',
  });
  String get createPrivateCircleTitle => _pick({
    'en': 'Create a Private Circle',
    'es': 'Crear un círculo privado',
    'fr': 'Créer un cercle privé',
  });
  String get createCircleExplanation => _pick({
    'en': 'Invite family, friends, or study groups to share intentions privately.',
    'es': 'Invita a familiares, amigos o grupos de estudio a compartir intenciones de forma privada.',
    'fr': 'Invitez votre famille, vos amis ou des groupes d’étude à partager des intentions en privé.',
  });
  String get circleNameRequired => _pick({
    'en': 'Circle name is required',
    'es': 'El nombre del círculo es obligatorio',
    'fr': 'Le nom du cercle est requis',
  });
  String get circleNamePlaceholder => _pick({
    'en': 'Circle Name (e.g. Family Devotional)',
    'es': 'Nombre del círculo (ej. Devocional familiar)',
    'fr': 'Nom du cercle (ex. Dévotion familiale)',
  });
  String get circlePurposeRequired => _pick({
    'en': 'Description is required',
    'es': 'La descripción es obligatoria',
    'fr': 'La description est requise',
  });
  String get circlePurposePlaceholder => _pick({
    'en': 'What is the purpose of this circle?',
    'es': '¿Cuál es el propósito de este círculo?',
    'fr': 'Quel est le but de ce cercle ?',
  });
  String get chooseCardTheme => _pick({
    'en': 'CHOOSE A CARD THEME',
    'es': 'ELIGE UN TEMA PARA LA TARJETA',
    'fr': 'CHOISISSEZ UN THÈME DE CARTE',
  });
  String get circleCreatedSuccess => _pick({
    'en': 'Private circle created successfully!',
    'es': '¡Círculo privado creado con éxito!',
    'fr': 'Cercle privé créé avec succès !',
  });
  String get catalogUnavailable => _pick({
    'en': 'Catalog unavailable',
    'es': 'Catálogo no disponible',
    'fr': 'Catalogue indisponible',
  });
  String get noPrayersPublished => _pick({
    'en': 'No prayers published',
    'es': 'No hay oraciones publicadas',
    'fr': 'Aucune prière publiée',
  });
  String get noPrayersPublishedMessage => _pick({
    'en': 'This altar language has no published prayers yet.',
    'es': 'Este idioma del altar no tiene oraciones publicadas aún.',
    'fr': 'Cette langue de l’autel n’a pas encore de prières publiées.',
  });
  String get allCategory => _pick({
    'en': 'All',
    'es': 'Todo',
    'fr': 'Tout',
  });
  String get publishedPrayers => _pick({
    'en': 'Published prayers',
    'es': 'Oraciones publicadas',
    'fr': 'Prières publiées',
  });
  String get loading => _pick({
    'en': 'Loading',
    'es': 'Cargando',
    'fr': 'Chargement',
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
