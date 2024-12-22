import 'package:flutter/foundation.dart';
import 'package:partyplanner/core/services/firebase_service.dart';
import 'package:partyplanner/core/services/notification_service.dart';
import 'package:partyplanner/models/item.dart';
import 'package:partyplanner/models/party.dart';

enum ItemsViewState { initial, loading, loaded, error }

class ItemsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;

  ItemsViewState _state = ItemsViewState.initial;
  String? _error;
  bool _isLoading = false;
  Party? _currentParty;
  List<Item> _items = [];

  ItemCategory? _selectedCategory;
  String? _searchQuery;
  bool _showOnlyUnassigned = false;
  bool _showOnlyMyItems = false;

  ItemsViewModel({
    required FirebaseService firebaseService,
    required NotificationService notificationService,
  })  : _firebaseService = firebaseService,
        _notificationService = notificationService;

  ItemsViewState get state => _state;
  String? get error => _error;
  bool get isLoading => _isLoading;
  Party? get currentParty => _currentParty;
  List<Item> get items => _filteredAndSortedItems;
  ItemCategory? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  bool get showOnlyUnassigned => _showOnlyUnassigned;
  bool get showOnlyMyItems => _showOnlyMyItems;

  List<Item> get _filteredAndSortedItems {
    List<Item> filteredItems = List.from(_items);

    if (_selectedCategory != null) {
      filteredItems = filteredItems
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) =>
              item.name.toLowerCase().contains(_searchQuery!.toLowerCase()))
          .toList();
    }

    if (_showOnlyUnassigned) {
      filteredItems =
          filteredItems.where((item) => item.assignedToUserId == null).toList();
    }

    if (_showOnlyMyItems) {
      filteredItems = filteredItems
          .where((item) =>
              item.assignedToUserId == _firebaseService.currentUser?.uid)
          .toList();
    }

    filteredItems.sort((a, b) {
      if (a.status != b.status) {
        return a.status.index.compareTo(b.status.index);
      }

      if (a.category != b.category) {
        return a.category.index.compareTo(b.category.index);
      }

      return a.name.compareTo(b.name);
    });

    return filteredItems;
  }

  Future<void> setCurrentParty(Party party) async {
    _currentParty = party;
    _items = party.items;
    notifyListeners();
  }

  Future<bool> addItem({
    required String name,
    required String description,
    required ItemCategory category,
    required int quantity,
    String? unit,
    bool isRequired = true,
  }) async {
    if (_currentParty == null) return false;

    try {
      _setLoading(true);

      final newItem = Item(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        category: category,
        status: ItemStatus.needed,
        quantity: quantity,
        unit: unit,
        isRequired: isRequired,
        createdByUserId: _firebaseService.currentUser!.uid,
        createdAt: DateTime.now(),
      );

      await _firebaseService.addItemToParty(_currentParty!.id, newItem);

      _items.add(newItem);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateItem(
    Item oldItem, {
    String? name,
    String? description,
    ItemCategory? category,
    int? quantity,
    String? unit,
    bool? isRequired,
  }) async {
    if (_currentParty == null) return false;

    try {
      _setLoading(true);

      final updatedItem = oldItem.copyWith(
        name: name,
        description: description,
        category: category,
        quantity: quantity,
        unit: unit,
        isRequired: isRequired,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateItem(
          _currentParty!.id, oldItem, updatedItem);

      final index = _items.indexWhere((item) => item.id == oldItem.id);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteItem(Item item) async {
    if (_currentParty == null) return false;

    try {
      _setLoading(true);
      await _firebaseService.deleteItem(_currentParty!.id, item);

      _items.removeWhere((i) => i.id == item.id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignItemToSelf(String itemId) async {
    if (_currentParty == null) return false;
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return false;

    try {
      _setLoading(true);
      await _firebaseService.assignItem(_currentParty!.id, itemId, userId);

      if (_currentParty!.organizerId != userId) {
        await _notificationService.sendPartyNotification(
          partyId: _currentParty!.id,
          title: 'Nouvel item assigné',
          body:
              "${_firebaseService.currentUser?.displayName ?? 'Quelqu\'un'} s'est assigné un nouvel item",
          recipientIds: [_currentParty!.organizerId],
        );
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> unassignItem(String itemId) async {
    if (_currentParty == null) return false;

    try {
      _setLoading(true);
      await _firebaseService.unassignItem(_currentParty!.id, itemId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markItemAsBrought(String itemId) async {
    if (_currentParty == null) return false;

    try {
      _setLoading(true);
      await _firebaseService.markItemAsBrought(_currentParty!.id, itemId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setCategory(ItemCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleShowOnlyUnassigned() {
    _showOnlyUnassigned = !_showOnlyUnassigned;
    notifyListeners();
  }

  void toggleShowOnlyMyItems() {
    _showOnlyMyItems = !_showOnlyMyItems;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _state = loading ? ItemsViewState.loading : ItemsViewState.loaded;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _state = ItemsViewState.initial;
    _error = null;
    _isLoading = false;
    _currentParty = null;
    _items = [];
    _selectedCategory = null;
    _searchQuery = null;
    _showOnlyUnassigned = false;
    _showOnlyMyItems = false;
    notifyListeners();
  }
}
