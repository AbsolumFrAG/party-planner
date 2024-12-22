import 'package:flutter/foundation.dart';
import '../models/party.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';

enum PartyViewState { initial, loading, loaded, error }

class PartyViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;

  PartyViewState _state = PartyViewState.initial;
  String? _error;
  bool _isLoading = false;

  List<Party> _userParties = [];
  List<Party> _organizedParties = [];
  Party? _selectedParty;

  // Filtres et tri
  DateTime? _selectedDate;
  bool _showPastParties = false;
  bool _showOnlyOrganized = false;
  String? _searchQuery;

  PartyViewModel({
    required FirebaseService firebaseService,
    required NotificationService notificationService,
  })  : _firebaseService = firebaseService,
        _notificationService = notificationService {
    // Charger les soirées au démarrage
    _initializeParties();
  }

  // Getters
  PartyViewState get state => _state;
  String? get error => _error;
  bool get isLoading => _isLoading;
  List<Party> get parties => _filteredAndSortedParties;
  List<Party> get organizedParties => _organizedParties;
  Party? get selectedParty => _selectedParty;
  DateTime? get selectedDate => _selectedDate;
  bool get showPastParties => _showPastParties;
  bool get showOnlyOrganized => _showOnlyOrganized;
  String? get searchQuery => _searchQuery;

  // Initialisation des streams de soirées
  void _initializeParties() {
    _setLoading(true);

    // Stream des soirées auxquelles l'utilisateur participe
    _firebaseService.getUserParties().listen(
      (parties) {
        _userParties = parties;
        _state = PartyViewState.loaded;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _state = PartyViewState.error;
        notifyListeners();
      },
    );

    // Stream des soirées organisées par l'utilisateur
    _firebaseService.getOrganizedParties().listen(
      (parties) {
        _organizedParties = parties;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  Future<void> refresh() async {
    _setLoading(true);
    _error = null;

    try {
      // Réinitialiser les streams
      _initializeParties();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Getter pour les soirées filtrées et triées
  List<Party> get _filteredAndSortedParties {
    List<Party> filteredParties = _showOnlyOrganized
        ? List.from(_organizedParties)
        : List.from(_userParties);

    // Filtrer par date
    if (_selectedDate != null) {
      filteredParties = filteredParties.where((party) {
        return party.date.year == _selectedDate!.year &&
            party.date.month == _selectedDate!.month;
      }).toList();
    }

    // Filtrer les soirées passées
    if (!_showPastParties) {
      filteredParties = filteredParties
          .where((party) => party.date.isAfter(DateTime.now()))
          .toList();
    }

    // Recherche textuelle
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredParties = filteredParties
          .where((party) =>
              party.title.toLowerCase().contains(_searchQuery!.toLowerCase()))
          .toList();
    }

    // Tri par date côté client
    filteredParties.sort((a, b) => b.date.compareTo(a.date));

    return filteredParties;
  }

  // Créer une nouvelle soirée
  Future<bool> createParty({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    String? locationDetails,
    required int maxParticipants,
    bool isPrivate = false,
    String? accessCode,
    Map<String, dynamic>? settings,
  }) async {
    try {
      _setLoading(true);

      final userId = _firebaseService.currentUser?.uid;
      if (userId == null) return false;

      final party = Party(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        date: date,
        location: location,
        locationDetails: locationDetails,
        maxParticipants: maxParticipants,
        status: PartyStatus.planning,
        organizerId: userId,
        coOrganizersIds: const [],
        participantsIds: [
          userId
        ], // L'organisateur est automatiquement participant
        items: const [],
        settings: settings,
        createdAt: DateTime.now(),
        isPrivate: isPrivate,
        accessCode: accessCode,
      );

      final partyId = await _firebaseService.createParty(party);
      _selectedParty = party.copyWith(id: partyId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour une soirée
  Future<bool> updateParty({
    required String partyId,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? locationDetails,
    int? maxParticipants,
    bool? isPrivate,
    String? accessCode,
    Map<String, dynamic>? settings,
  }) async {
    try {
      _setLoading(true);

      final party = _selectedParty;
      if (party == null) return false;

      final updatedParty = party.copyWith(
        title: title,
        description: description,
        date: date,
        location: location,
        locationDetails: locationDetails,
        maxParticipants: maxParticipants,
        isPrivate: isPrivate,
        accessCode: accessCode,
        settings: settings,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateParty(partyId, updatedParty);
      _selectedParty = updatedParty;
      _error = null;

      // Notifier les participants des changements
      await _notificationService.sendPartyNotification(
        partyId: partyId,
        title: "Soirée mise à jour",
        body: "La soirée ${updatedParty.title} a été modifiée",
        recipientIds: updatedParty.participantsIds,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une soirée
  Future<bool> deleteParty(String partyId) async {
    try {
      _setLoading(true);

      final party = _selectedParty;
      if (party == null) return false;

      // Notifier les participants avant la suppression
      await _notificationService.sendPartyNotification(
        partyId: partyId,
        title: "Soirée annulée",
        body: "La soirée ${party.title} a été annulée",
        recipientIds: party.participantsIds,
      );

      await _firebaseService.deleteParty(partyId);
      _selectedParty = null;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Rejoindre une soirée
  Future<bool> joinParty(String partyId, {String? accessCode}) async {
    try {
      _setLoading(true);

      final party = _userParties.firstWhere((p) => p.id == partyId);

      // Vérifier le code d'accès si la soirée est privée
      if (party.isPrivate && party.accessCode != accessCode) {
        throw Exception('Code d\'accès invalide');
      }

      await _firebaseService.joinParty(partyId);
      _error = null;

      // Notifier l'organisateur
      await _notificationService.sendPartyNotification(
        partyId: partyId,
        title: "Nouveau participant",
        body:
            "${_firebaseService.currentUser?.displayName ?? 'Quelqu\'un'} a rejoint la soirée",
        recipientIds: [party.organizerId],
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Quitter une soirée
  Future<bool> leaveParty(String partyId) async {
    try {
      _setLoading(true);

      await _firebaseService.leaveParty(partyId);
      if (_selectedParty?.id == partyId) {
        _selectedParty = null;
      }
      _error = null;

      final party = _userParties.firstWhere((p) => p.id == partyId);
      // Notifier l'organisateur
      await _notificationService.sendPartyNotification(
        partyId: partyId,
        title: "Participant parti",
        body:
            "${_firebaseService.currentUser?.displayName ?? 'Quelqu\'un'} a quitté la soirée",
        recipientIds: [party.organizerId],
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sélectionner une soirée
  void selectParty(Party party) {
    _selectedParty = party;
    notifyListeners();
  }

  // Filtres
  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void toggleShowPastParties() {
    _showPastParties = !_showPastParties;
    notifyListeners();
  }

  void toggleShowOnlyOrganized() {
    _showOnlyOrganized = !_showOnlyOrganized;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _state = PartyViewState.initial;
    _error = null;
    _isLoading = false;
    _userParties = [];
    _organizedParties = [];
    _selectedParty = null;
    _selectedDate = null;
    _showPastParties = false;
    _showOnlyOrganized = false;
    _searchQuery = null;
    notifyListeners();
  }

  bool isUserOrganizer(String partyId) {
    final party = _userParties.firstWhere((p) => p.id == partyId);
    final userId = _firebaseService.currentUser?.uid;
    return party.organizerId == userId;
  }
}
