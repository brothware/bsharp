import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

sealed class TipJarState {
  const TipJarState();
}

final class TipJarLoading extends TipJarState {
  const TipJarLoading();
}

final class TipJarAvailable extends TipJarState {
  const TipJarAvailable(this.products);

  final List<ProductDetails> products;
}

final class TipJarUnavailable extends TipJarState {
  const TipJarUnavailable();
}

final class TipJarPurchasing extends TipJarState {
  const TipJarPurchasing();
}

final class TipJarPurchased extends TipJarState {
  const TipJarPurchased();
}

final class TipJarFailed extends TipJarState {
  const TipJarFailed(this.message);

  final String message;
}

class TipJarService {
  TipJarService() {
    unawaited(_init());
  }

  static const coffeeId = 'bsharp_tip_coffee';
  static const mealId = 'bsharp_tip_meal';
  static const Set<String> _productIds = {coffeeId, mealId};

  final _stateController = StreamController<TipJarState>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Stream<TipJarState> get stateStream => _stateController.stream;

  Future<void> _init() async {
    _stateController.add(const TipJarLoading());

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _stateController.add(const TipJarUnavailable());
      return;
    }

    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdate,
    );

    final response = await InAppPurchase.instance.queryProductDetails(
      _productIds,
    );

    if (response.productDetails.isEmpty) {
      _stateController.add(const TipJarUnavailable());
      return;
    }

    final sorted = List<ProductDetails>.from(response.productDetails)
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    _stateController.add(TipJarAvailable(sorted));
  }

  Future<void> purchase(ProductDetails product) async {
    _stateController.add(const TipJarPurchasing());
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyConsumable(purchaseParam: param);
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _stateController.add(const TipJarPurchased());
          if (purchase.pendingCompletePurchase) {
            unawaited(InAppPurchase.instance.completePurchase(purchase));
          }
        case PurchaseStatus.error:
          _stateController.add(
            TipJarFailed(purchase.error?.message ?? 'Purchase failed'),
          );
        case PurchaseStatus.canceled:
          unawaited(_restoreAvailableState());
        case PurchaseStatus.pending:
          _stateController.add(const TipJarPurchasing());
      }
    }
  }

  Future<void> _restoreAvailableState() async {
    final response = await InAppPurchase.instance.queryProductDetails(
      _productIds,
    );
    if (response.productDetails.isNotEmpty) {
      final sorted = List<ProductDetails>.from(response.productDetails)
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      _stateController.add(TipJarAvailable(sorted));
    } else {
      _stateController.add(const TipJarUnavailable());
    }
  }

  void dispose() {
    unawaited(_purchaseSub?.cancel());
    unawaited(_stateController.close());
  }
}
