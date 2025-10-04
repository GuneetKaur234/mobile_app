// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcome => 'Bienvenue';

  @override
  String get pickup => 'Ramassage';

  @override
  String get delivery => 'Livraison';

  @override
  String get settings => 'Paramètres';

  @override
  String get selectLanguage => 'Sélectionnez votre langue';

  @override
  String get continueButton => 'Continuer';

  @override
  String get letsGetYouSetUp => 'Configurons votre compte !';

  @override
  String get name => 'Nom';

  @override
  String get licenseNumber => 'Numéro de Permis';

  @override
  String get company => 'Entreprise';

  @override
  String get scacCode => 'Code SCAC';

  @override
  String get phone => 'Téléphone';

  @override
  String get saveAndContinue => 'Enregistrer & Continuer';

  @override
  String cannotBeEmpty(Object field) {
    return '$field ne peut pas être vide';
  }

  @override
  String get unableToConnect =>
      'Impossible de se connecter au serveur. Vérifiez votre connexion.';

  @override
  String get connectionTimeout =>
      'Le délai de connexion a expiré. Vous n\'êtes pas approuvé ou le serveur est inaccessible.';

  @override
  String unexpectedError(Object error) {
    return 'Erreur inattendue : $error';
  }

  @override
  String get notApproved =>
      'Vous n\'êtes pas approuvé. Veuillez contacter votre entreprise.';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get noRecentLoads => 'Aucun chargement récent trouvé.';

  @override
  String get load => 'Chargement';

  @override
  String get customer => 'Client';

  @override
  String get status => 'Statut';

  @override
  String get completed => 'Terminé';

  @override
  String get pending => 'En attente';

  @override
  String get pickupInfo => 'Informations de ramassage';

  @override
  String get trailerUpload => 'Téléversement de la remorque';

  @override
  String get deliveryInfo => 'Informations de livraison';

  @override
  String get deliveryCompletedSnack => 'Livraison terminée !';

  @override
  String get loadNumber => 'Numéro de chargement';

  @override
  String get pickupNumber => 'Numéro de ramassage';

  @override
  String get noLoadDetails => 'Aucun détail de chargement trouvé.';

  @override
  String get loadDetails => 'Détails du chargement';

  @override
  String get pickupDetails => 'Détails du ramassage';

  @override
  String get truckNumber => 'Numéro du camion';

  @override
  String get trailerNumber => 'Numéro de la remorque';

  @override
  String get equipmentType => 'Type d\'équipement';

  @override
  String get equipmentTypeRequired => 'Le type d\'équipement est requis';

  @override
  String get customerRequired => 'Le client est requis';

  @override
  String get orderNumber => 'Numéro de commande';

  @override
  String get reeferPreCool => 'Pré-refroidissement du reefere (°F)';

  @override
  String get pickupInfoSaved => 'Informations de ramassage enregistrées';

  @override
  String get pickupInfoSavedTransit =>
      'Informations de ramassage enregistrées et statut mis à jour à En transit';

  @override
  String get failedToSave => 'Échec de l\'enregistrement';

  @override
  String networkError(Object error) {
    return 'Erreur réseau : $error';
  }

  @override
  String get pictureUpload => 'Téléversement d’images';

  @override
  String get trailerPicture => 'Photo de la remorque';

  @override
  String get pulp => 'Pulpe';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get pulpPicture => 'Photo de la pulpe';

  @override
  String get pulpReason => 'Sinon, pourquoi ?';

  @override
  String get reeferPicture => 'Photo du réfrigéré';

  @override
  String get loadSecurePicture => 'Photo du chargement sécurisé';

  @override
  String get sealedTrailerPicture => 'Photo de la remorque scellée';

  @override
  String get bol => 'Connaissement (BOL)';

  @override
  String get reeferTempShipper =>
      'Température réfrigérée définie par l’expéditeur';

  @override
  String get reeferTempBol => 'Température réfrigérée sur le BOL';

  @override
  String get temperatureUnit => 'Unité de température';

  @override
  String get sealNumber => 'Numéro de sceau';

  @override
  String get pickupNotes => 'Notes de ramassage';

  @override
  String get save => 'Enregistrer';

  @override
  String get sendPickupEmail => 'Envoyer l’email de ramassage';

  @override
  String get pickupEmailSuccess => 'Email de ramassage envoyé avec succès !';

  @override
  String get pickupEmailFailed => 'Échec de l’envoi de l’email de ramassage';

  @override
  String missingFields(Object fields) {
    return 'Veuillez fournir : $fields';
  }

  @override
  String get fillReeferTemp => 'Veuillez remplir les températures réfrigérées';

  @override
  String get upload => 'Téléverser';

  @override
  String get addMoreFiles => 'Ajouter d\'autres fichiers';

  @override
  String get failedToLoadFiles => 'Échec du chargement des fichiers';

  @override
  String errorLoadingFiles(Object error) {
    return 'Erreur lors du chargement des fichiers : $error';
  }

  @override
  String errorPickingImages(Object error) {
    return 'Erreur lors de la sélection des images : $error';
  }

  @override
  String pleaseProvide(Object fields) {
    return 'Veuillez fournir : $fields';
  }

  @override
  String get deliveryNumber => 'Numéro de livraison';

  @override
  String get enterDeliveryNumber => 'Veuillez entrer un numéro de livraison';

  @override
  String get podFiles => 'Fichiers POD';

  @override
  String get uploadAtLeastOnePod =>
      'Veuillez télécharger au moins un fichier POD';

  @override
  String get deliveryInfoSaved =>
      'Informations de livraison enregistrées avec succès';

  @override
  String get deliveryEmailSent => 'Email de livraison envoyé avec succès !';

  @override
  String get failedToLoadDeliveryInfo =>
      'Échec du chargement des informations de livraison';

  @override
  String errorLoadingDeliveryInfo(Object error) {
    return 'Erreur lors du chargement des informations de livraison : $error';
  }

  @override
  String get sendEmail => 'Envoyer l’email';

  @override
  String get notes => 'Notes';

  @override
  String get error => 'Erreur';

  @override
  String get tripCompleted => 'Trajet terminé !';

  @override
  String get deliverySentSuccess =>
      'Les informations de livraison ont été envoyées avec succès 🎉';

  @override
  String get goToDashboard => 'Aller au tableau de bord';

  @override
  String get status_in_transit => 'En tránsito';

  @override
  String get status_pickup_completed => 'Recogida completada';

  @override
  String get status_delivered => 'Entregado';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get fullName => 'Nom Complet';

  @override
  String get saveProfile => 'Enregistrer le Profil';

  @override
  String get failedFetchProfile => 'Échec de la récupération du profil';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès';

  @override
  String fieldRequired(Object field) {
    return '$field est requis';
  }

  @override
  String get account => 'Compte';

  @override
  String get preferences => 'Préférences';

  @override
  String get support => 'Support';

  @override
  String get security => 'Sécurité';

  @override
  String get appInfo => 'À propos de l\'application';

  @override
  String get viewUpdateDriverDetails =>
      'Voir / mettre à jour les informations du conducteur';

  @override
  String get appPreferences => 'Préférences de l\'application';

  @override
  String get darkModeFontSize => 'Mode sombre, taille de la police';

  @override
  String get helpSupport => 'Aide & Support';

  @override
  String get contactDispatcherHotlineFaq =>
      'Contacter le répartiteur, hotline, FAQ';

  @override
  String get privacySecurity => 'Confidentialité & Sécurité';

  @override
  String get managePermissions => 'Gérer les permissions';

  @override
  String get aboutApp => 'À propos de l\'application';

  @override
  String get versionCompanyContact =>
      'Informations sur la version, contact de l\'entreprise';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get fontSize => 'Taille de la police';

  @override
  String get language => 'Langue';
}
