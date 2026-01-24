import '../models/barcode_scan_result.dart';

extension ProductInfoExtras on ProductInfo {
  ProductInfo copyWithExtras(Map<String, dynamic> additionalExtras) {
    final newExtras = Map<String, dynamic>.from(extras ?? {});
    newExtras.addAll(additionalExtras);
    return copyWith(extras: newExtras);
  }
}
