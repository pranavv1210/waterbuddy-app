import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterbuddy_superapp/core/exceptions/exceptions.dart';
import 'package:waterbuddy_superapp/core/services/payments/razorpay_service.dart';

class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseFunctions implements FirebaseFunctions {
  FakeFirebaseFunctions(this.callable);
  final HttpsCallable callable;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return callable;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpsCallable implements HttpsCallable {
  FakeHttpsCallable(this.mockResult);
  final HttpsCallableResult mockResult;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    return mockResult as HttpsCallableResult<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpsCallableResult<T> implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);
  
  @override
  final T data;
}

void main() {
  group('RazorpayService Payment Verification Tests', () {
    test('Successful verification', () async {
      final mockResult = FakeHttpsCallableResult({'success': true});
      final fakeFunctions = FakeFirebaseFunctions(FakeHttpsCallable(mockResult));
      final fakeFirestore = FakeFirebaseFirestore();

      final razorpayService = RazorpayService(fakeFirestore, fakeFunctions);

      await expectLater(
        razorpayService.verifyPaymentWithBackend(
          orderId: 'order_123',
          razorpayPaymentId: 'pay_123',
          razorpayOrderId: 'ord_123',
          razorpaySignature: 'sig_123',
        ),
        completes,
      );
    });

    test('Failed verification throws PaymentException', () async {
      final mockResult = FakeHttpsCallableResult({'success': false});
      final fakeFunctions = FakeFirebaseFunctions(FakeHttpsCallable(mockResult));
      final fakeFirestore = FakeFirebaseFirestore();

      final razorpayService = RazorpayService(fakeFirestore, fakeFunctions);

      expect(
        () => razorpayService.verifyPaymentWithBackend(
          orderId: 'order_123',
          razorpayPaymentId: 'pay_123',
          razorpayOrderId: 'ord_123',
          razorpaySignature: 'sig_123',
        ),
        throwsA(isA<PaymentException>()),
      );
    });
  });
}
