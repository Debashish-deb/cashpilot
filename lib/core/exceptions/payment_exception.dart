/// Payment-related exceptions
class PaymentException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  PaymentException(this.message, {this.code, this.details});

  @override
  String toString() => 'PaymentException: $message${code != null ? ' (code: $code)' : ''}';
}
