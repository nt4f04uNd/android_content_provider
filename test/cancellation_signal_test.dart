import 'dart:async';

import 'package:android_content_provider/android_content_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceivedCancellationSignal', () {
    const channel = MethodChannel(
        'com.nt4f04und.android_content_provider/CancellationSignal/id');

    test('constructor and dispose', () async {
      int initCount = 0;
      channel.setMockMethodCallHandler((call) {
        initCount += 1;
        expect(call.method, 'init');
        return null;
      });
      final signal = ReceivedCancellationSignal.fromId('id');
      expect(signal.cancelled, false);
      await channel.invokeMockMethod('dispose', null);
      int cancelledCount = 0;
      signal.setCancelListener(() {
        cancelledCount += 1;
      });
      expect(signal.cancelled, false);
      expect(cancelledCount, 0);
      expect(initCount, 1);
    });

    test('cancellation', () async {
      final signal = ReceivedCancellationSignal.fromId('id');
      expect(signal.cancelled, false);
      int cancelledCount = 0;
      signal.setCancelListener(() {
        cancelledCount += 1;
      });
      await channel.invokeMockMethod('cancel', null);
      expect(signal.cancelled, true);
      expect(cancelledCount, 1);

      // Check setting new listener after cancellation calls it rightaway.
      signal.setCancelListener(() {
        cancelledCount += 1;
      });
      expect(signal.cancelled, true);
      expect(cancelledCount, 2);
    });
  });

  group('CancellationSignal', () {
    test('cancellation', () async {
      final signal = CancellationSignal();
      final channel = MethodChannel(
          'com.nt4f04und.android_content_provider/CancellationSignal/${signal.id}');
      int cancelledCount = 0;
      signal.setCancelListener(() {
        cancelledCount += 1;
      });
      await channel.invokeMockMethod('init', null);
      final completer = Completer<void>();
      channel.setMockMethodCallHandler((call) {
        completer.complete();
        return null;
      });
      signal.cancel();
      expect(signal.cancelled, true);
      expect(cancelledCount, 1);
      await completer.future;
    });
  });
}

extension MethodChannelMockInvoke on MethodChannel {
  Future<void> invokeMockMethod(String method, dynamic arguments) async {
    const codec = StandardMethodCodec();
    final data = codec.encodeMethodCall(MethodCall(method, arguments));

    return ServicesBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      name,
      data,
      (ByteData? data) {},
    );
  }
}
