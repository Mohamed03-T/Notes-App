import 'app_localizations.dart';

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
  String get folderName => 'Nom du Dossier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get selectBackgroundColor => 'Sélectionner la Couleur de Fond';

  @override
  String get confirmDelete => 'Confirmer la Suppression';

  @override
  String deleteConfirmMessage(String folderName) {
    return 'Êtes-vous sûr de vouloir supprimer le dossier "$folderName" ?\nToutes les notes qu\'il contient seront supprimées.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get noFolders => 'Aucun dossier';

  @override
  String daysAgo(int count) {
    if (count == 1) return 'Il y a 1 jour';
    return 'Il y a $count jours';
  }

  @override
  String hoursAgo(int count) {
    if (count == 1) return 'Il y a 1 heure';
    return 'Il y a $count heures';
  }

  @override
  String minutesAgo(int count) {
    if (count == 1) return 'Il y a 1 minute';
    return 'Il y a $count minutes';
  }

  @override
  String get now => 'Maintenant';
}
