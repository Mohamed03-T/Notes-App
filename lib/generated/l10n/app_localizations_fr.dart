// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Application de Notes';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearanceAndDisplay => 'Apparence et Affichage';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get darkModeSubtitle => 'Activer le thème sombre pour l\'application';

  @override
  String get fontSize => 'Taille de Police';

  @override
  String get fontSizeSubtitle => 'Moyen';

  @override
  String get languageAndRegion => 'Langue et Région';

  @override
  String get language => 'Langue';

  @override
  String get timezone => 'Fuseau Horaire';

  @override
  String get timezoneSubtitle => 'GMT+3 (Riyad)';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Activer les Notifications';

  @override
  String get enableNotificationsSubtitle => 'Recevoir des notifications de rappel';

  @override
  String get backupAndSync => 'Sauvegarde et Synchronisation';

  @override
  String get autoBackup => 'Sauvegarde Automatique';

  @override
  String get autoBackupSubtitle => 'Sauvegarde automatique des notes';

  @override
  String get exportData => 'Exporter les Données';

  @override
  String get exportDataSubtitle => 'JSON, PDF, TXT';

  @override
  String get importData => 'Importer les Données';

  @override
  String get importDataSubtitle => 'À partir de fichiers externes';

  @override
  String get support => 'Support et Aide';

  @override
  String get helpCenter => 'Centre d\'Aide';

  @override
  String get helpCenterSubtitle => 'FAQ et tutoriels';

  @override
  String get contactUs => 'Nous Contacter';

  @override
  String get contactUsSubtitle => 'support@noteapp.com';

  @override
  String get aboutApp => 'À Propos de l\'Application';

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get version => 'Version : 1.0.0';

  @override
  String get developer => 'Développeur : Mohamed03-T';

  @override
  String get darkModeEnabled => 'Mode sombre activé';

  @override
  String get lightModeEnabled => 'Mode clair activé';

  @override
  String get fontSizeComingSoon => 'Les options de taille de police seront ajoutées prochainement';

  @override
  String get timezoneComingSoon => 'Les options de fuseau horaire seront ajoutées prochainement';

  @override
  String get exportComingSoon => 'Les options d\'export seront ajoutées prochainement';

  @override
  String get importComingSoon => 'Les options d\'import seront ajoutées prochainement';

  @override
  String get helpComingSoon => 'Le centre d\'aide sera ajouté prochainement';

  @override
  String get contactComingSoon => 'Les options de contact seront ajoutées prochainement';

  @override
  String get welcome => 'Bienvenue dans l\'Application de Notes';

  @override
  String get noPagesYet => 'Aucune page pour le moment';

  @override
  String get createFirstPage => 'Commencez par créer votre première page';

  @override
  String get createNewPage => 'Créer une Nouvelle Page';

  @override
  String get addNewPage => 'Ajouter une nouvelle page';

  @override
  String get addNewFolder => 'Ajouter un nouveau dossier';

  @override
  String get loadingData => 'Chargement des données...';

  @override
  String get allPagesTitle => 'Toutes les pages';

  @override
  String get latest => 'Dernier';

  @override
  String foldersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers',
      one: '1 dossier',
      zero: 'Aucun dossier',
    );
    return '$_temp0';
  }

  @override
  String lastUpdated(String when) {
    return 'Dernière mise à jour : $when';
  }

  @override
  String get addPageDescription => 'Ajoutez une nouvelle page pour mieux organiser vos notes';

  @override
  String get pageName => 'Nom de la page';

  @override
  String get pageNameHint => 'ex.: Projets, Idées, Tâches...';

  @override
  String get creating => 'Création...';

  @override
  String get createPage => 'Créer la page';

  @override
  String get manageFolder => 'Gérer le Dossier :';

  @override
  String get unpinFolder => 'Détacher';

  @override
  String get pinFolder => 'Épingler le Dossier';

  @override
  String get renameFolder => 'Renommer le Dossier';

  @override
  String get changeBackgroundColor => 'Changer la Couleur de Fond';

  @override
  String get deleteFolder => 'Supprimer le Dossier';

  @override
  String get folderName => 'Nom du dossier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get selectBackgroundColor => 'Sélectionner la Couleur de Fond';

  @override
  String get confirmDelete => 'Confirmer la Suppression';

  @override
  String deleteConfirmMessage(String folderName) {
    return 'Êtes-vous sûr de vouloir supprimer le dossier \"$folderName\" ?\nToutes les notes qu\'il contient seront supprimées.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get noFolders => 'Aucun dossier';

  @override
  String get noNotes => 'Aucune note';

  @override
  String get noFoldersYet => 'Aucun dossier pour le moment';

  @override
  String get tapPlusToAddFolder => 'Appuyez sur + pour ajouter un nouveau dossier';

  @override
  String get error => 'Erreur';

  @override
  String get folderNotFound => 'Dossier introuvable';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count jours',
      one: 'Il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count heures',
      one: 'Il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count minutes',
      one: 'Il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get now => 'Maintenant';

  @override
  String get splashWelcomeTitle => 'Bienvenue dans l\'Application de Notes';

  @override
  String get splashTagline => 'Organisez vos idées et notes facilement';

  @override
  String get splashLoading => 'Chargement...';

  @override
  String get onboardingPage1Title => 'Contrôle total';

  @override
  String get onboardingPage1Description => 'Créez et organisez vos notes facilement dans des pages et des dossiers.';

  @override
  String get onboardingPage2Title => 'Interface simple';

  @override
  String get onboardingPage2Description => 'Profitez d\'une interface propre et facile à utiliser.';

  @override
  String get onboardingPage3Title => 'Personnalisation du thème';

  @override
  String get onboardingPage3Description => 'Choisissez entre les modes clair et sombre selon votre préférence.';

  @override
  String get onboardingPage4Title => 'Fonctionne hors ligne';

  @override
  String get onboardingPage4Description => 'L\'application fonctionne hors ligne et stocke vos notes localement pour garantir la confidentialité.';

  @override
  String get onboardingPage5Title => 'Plusieurs langues';

  @override
  String get onboardingPage5Description => 'Arabe, français et anglais sont pris en charge pour plus de flexibilité.';

  @override
  String get onboardingPage6Title => 'Sauvegarde & Restauration';

  @override
  String get onboardingPage6Description => 'Les futures mises à jour ajouteront la sauvegarde et la restauration; sans sauvegarde, les notes peuvent être perdues si l\'application est supprimée.';

  @override
  String get onboardingPage7Title => 'Protection des dossiers';

  @override
  String get onboardingPage7Description => 'Définissez un code PIN pour les dossiers afin de garder vos notes privées en sécurité.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingBack => 'Retour';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingFinish => 'Terminé';

  @override
  String foldersInPage(Object page) {
    return 'Dossiers dans $page';
  }

  @override
  String get noFoldersHere => 'Aucun dossier dans cette page';

  @override
  String get addNoteTitleSimple => 'Ajouter une note';

  @override
  String get addNoteTitleArticle => 'Nouvel article';

  @override
  String get addNoteTitleEmail => 'Nouvel e-mail';

  @override
  String get addNoteTitleChecklist => 'Nouvelle liste de contrôle';

  @override
  String get save => 'Enregistrer';

  @override
  String get addFolderTitle => 'Ajouter un nouveau dossier';

  @override
  String get createFolder => 'Créer le dossier';

  @override
  String get addFolderDescription => 'Ajoutez un nouveau dossier pour organiser les notes dans cette page';

  @override
  String inPage(Object page) {
    return 'Dans la page : $page';
  }

  @override
  String get folderNameHint => 'ex : Tâches quotidiennes, Idées, Réunions...';

  @override
  String get creatingFolder => 'Création...';

  @override
  String get notificationsEnabledOn => 'Notifications activées';

  @override
  String get notificationsEnabledOff => 'Notifications désactivées';

  @override
  String get notificationSounds => 'Sons de notification';

  @override
  String get notificationSoundsSubtitle => 'Son par défaut';

  @override
  String get notificationSoundsComingSoon => 'Les options de sons seront ajoutées prochainement';

  @override
  String get autoBackupPeriodicEnabled => 'Sauvegarde automatique activée';

  @override
  String autoBackupLast(String date) {
    return 'Dernière sauvegarde : $date';
  }

  @override
  String get autoBackupPeriodicEnabledSnackOn => 'Sauvegarde automatique activée (fonctionne en mémoire)';

  @override
  String get autoBackupPeriodicEnabledSnackOff => 'Sauvegarde automatique désactivée';

  @override
  String get exportBackupTitle => 'Exporter la sauvegarde';

  @override
  String get exportBackupSubtitle => 'Enregistrer un fichier JSON de sauvegarde';

  @override
  String get exportBackupSaved => 'Sauvegarde enregistrée';

  @override
  String get exportBackupFailed => 'Échec de l\'enregistrement de la sauvegarde';

  @override
  String get importBackupTitle => 'Importer la sauvegarde';

  @override
  String get importBackupSubtitle => 'Choisissez un fichier JSON à importer';

  @override
  String get importBackupSuccess => 'Sauvegarde importée';

  @override
  String get importBackupFailed => 'Échec de l\'importation du fichier';

  @override
  String get restoreFromKeyTitle => 'Restaurer depuis la clé interne';

  @override
  String get restoreFromKeySubtitle => 'Restaurer depuis backup_notes_v2';

  @override
  String get restoreFromKeySuccess => 'Restauré depuis la clé interne';

  @override
  String get restoreFromKeyNotFound => 'Aucune sauvegarde interne trouvée';

  @override
  String get appInfoTitle => 'Informations sur l\'application';

  @override
  String get appDescription => 'Une application de notes moderne et élégante avec prise en charge des thèmes clair et sombre';

  @override
  String get thankYouMessage => 'Merci d\'utiliser l\'application ! 💙';

  @override
  String get composerHint => 'Tapez une note rapide... (ou appuyez sur l\'icône pour les options avancées)';

  @override
  String get composerSend => 'Envoyer';

  @override
  String get composerCreate => 'Créer une note';

  @override
  String get composerSavedSuccess => 'Note enregistrée avec succès ✅';

  @override
  String get composerSavedFailure => 'Échec de l\'enregistrement de la note ❌';

  @override
  String composerError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get composerOptionSimple => 'Note simple';

  @override
  String get composerOptionArticle => 'Article / longue note';

  @override
  String get composerOptionEmail => 'E-mail / message formaté';

  @override
  String get composerOptionChecklist => 'Liste de contrôle / tâches';

  @override
  String get composerOptionCancel => 'Annuler';

  @override
  String get noteTypeSimple => 'Simple';

  @override
  String get noteTypeArticle => 'Article';

  @override
  String get noteTypeEmail => 'E-mail';

  @override
  String get noteTypeChecklist => 'Checklist';

  @override
  String get noteTypeText => 'Texte';

  @override
  String get noteTypeImage => 'Image';

  @override
  String get noteTypeAudio => 'Audio';
}
