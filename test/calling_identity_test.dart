import 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';

void main() {
  group('CallingIdentity', () {
    test('toString', () {
      final identity = CallingIdentity.fromId('someId');
      expect(identity.id, 'someId');
      expect(identity.toString(), 'CallingIdentity(someId)');
    });

    test('equality', () {
      final identity = CallingIdentity.fromId('someId');
      expect(identity, CallingIdentity.fromId('someId'));
      expect(identity, isNot(CallingIdentity.fromId('someOtherId')));
    });
  });
}
