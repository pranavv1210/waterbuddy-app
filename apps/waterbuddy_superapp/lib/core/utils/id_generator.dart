import 'dart:math';

class IdGenerator {
  IdGenerator._();

  static final _random = Random();
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static String generateId(String prefix) {
    final buffer = StringBuffer('WB-$prefix-');
    for (var i = 0; i < 8; i++) {
      buffer.write(_chars[_random.nextInt(_chars.length)]);
    }
    return buffer.toString();
  }

  static String generateOrderId() => generateId('ORD');
  static String generateRefundId() => generateId('RFD');
  static String generatePaymentId() => generateId('PAY');
  static String generateWalletId() => generateId('WAL');
  static String generateDriverId() => generateId('DRV');
  static String generateSellerId() => generateId('SEL');
}
