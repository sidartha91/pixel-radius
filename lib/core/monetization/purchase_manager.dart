import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PurchaseEvent { purchased, restored, nothingToRestore, error, storeUnavailable }

/// Gestion de l'achat non-consommable `premium_unlock_world`.
class PurchaseManager extends ChangeNotifier {
  PurchaseManager._(this._prefs);

  static const String premiumProductId = 'premium_unlock_world';
  static const String _kPremium = 'iap.premiumUnlocked';

  final SharedPreferences _prefs;
  // Initialisé seulement sur iOS/Android (aucune implémentation web).
  late final InAppPurchase _iap;
  final StreamController<PurchaseEvent> _events = StreamController<PurchaseEvent>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _premiumProduct;
  bool _storeAvailable = false;
  bool _isPremium = false;
  bool _busy = false;
  bool _restoreInProgress = false;
  bool _restoreFoundSomething = false;

  bool get isPremium => _isPremium;
  bool get isStoreAvailable => _storeAvailable;
  bool get isBusy => _busy;
  ProductDetails? get premiumProduct => _premiumProduct;
  String? get premiumPrice => _premiumProduct?.price;

  /// Événements à afficher (SnackBar) par l'UI.
  Stream<PurchaseEvent> get events => _events.stream;

  static Future<PurchaseManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    final manager = PurchaseManager._(prefs);
    manager._isPremium = prefs.getBool(_kPremium) ?? false;
    await manager._init();
    return manager;
  }

  Future<void> _init() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android)) {
      _storeAvailable = false;
      return;
    }
    try {
      _iap = InAppPurchase.instance;
      _storeAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[PurchaseManager] isAvailable : $e');
      _storeAvailable = false;
    }
    if (!_storeAvailable) {
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        debugPrint('[PurchaseManager] stream error : $e');
        _setBusy(false);
        _events.add(PurchaseEvent.error);
      },
    );

    try {
      final response = await _iap.queryProductDetails(<String>{premiumProductId});
      if (response.productDetails.isNotEmpty) {
        _premiumProduct = response.productDetails.first;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[PurchaseManager] Produits introuvables : ${response.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('[PurchaseManager] queryProductDetails : $e');
    }
    notifyListeners();
  }

  Future<void> buyPremium() async {
    if (_isPremium) return;
    if (!_storeAvailable || _premiumProduct == null) {
      _events.add(PurchaseEvent.storeUnavailable);
      return;
    }
    _setBusy(true);
    try {
      final param = PurchaseParam(productDetails: _premiumProduct!);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _setBusy(false);
        _events.add(PurchaseEvent.error);
      }
    } catch (e) {
      debugPrint('[PurchaseManager] buyNonConsumable : $e');
      _setBusy(false);
      _events.add(PurchaseEvent.error);
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _events.add(PurchaseEvent.storeUnavailable);
      return;
    }
    _setBusy(true);
    _restoreInProgress = true;
    _restoreFoundSomething = false;
    try {
      await _iap.restorePurchases();
      // Les achats restaurés arrivent via purchaseStream. Si rien n'arrive
      // dans le délai, on informe l'utilisateur qu'il n'y a rien à restaurer.
      Future<void>.delayed(const Duration(seconds: 6), () {
        if (_restoreInProgress) {
          _restoreInProgress = false;
          _setBusy(false);
          if (!_restoreFoundSomething) _events.add(PurchaseEvent.nothingToRestore);
        }
      });
    } catch (e) {
      debugPrint('[PurchaseManager] restorePurchases : $e');
      _restoreInProgress = false;
      _setBusy(false);
      _events.add(PurchaseEvent.error);
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != premiumProductId) {
        if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
        continue;
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _setBusy(true);
        case PurchaseStatus.purchased:
          await _grantPremium();
          _setBusy(false);
          _events.add(PurchaseEvent.purchased);
        case PurchaseStatus.restored:
          _restoreFoundSomething = true;
          _restoreInProgress = false;
          await _grantPremium();
          _setBusy(false);
          _events.add(PurchaseEvent.restored);
        case PurchaseStatus.error:
          _setBusy(false);
          _events.add(PurchaseEvent.error);
        case PurchaseStatus.canceled:
          _setBusy(false);
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          debugPrint('[PurchaseManager] completePurchase : $e');
        }
      }
    }
  }

  Future<void> _grantPremium() async {
    if (_isPremium) return;
    _isPremium = true;
    await _prefs.setBool(_kPremium, true);
    notifyListeners();
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _events.close();
    super.dispose();
  }
}
