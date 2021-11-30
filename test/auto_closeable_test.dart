import 'package:android_content_provider/android_content_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCloseable extends Closeable {
  TestCloseable(this.error);
  final String error;

  bool closeCalled = false;

  @override
  void close() {
    closeCalled = true;
  }
}

class TestAutoCloseable extends Closeable {
  TestAutoCloseable(this.error, {String? errorMessage})
      : super.auto(errorMessage: errorMessage);
  final String error;

  @override
  void close() {
    throw error;
  }
}

void main() {
  group('Closeable', () {
    testWidgets('close is not called', (WidgetTester tester) async {
      await autoCloseScope(() async {
        TestCloseable('error');
      });
      expect(await tester.takeException(), null);
    });
  });

  group('Closeable.auto', () {
    testWidgets('close is called and exceptions from it are reported',
        (WidgetTester tester) async {
      await autoCloseScope(() async {
        TestAutoCloseable('error');
      });
      expect(await tester.takeException(), 'error');
    });

    test('contsturctor throws outside autoCloseScope with default message', () {
      expect(
        () => TestAutoCloseable('error'),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message',
              'TestAutoCloseable must be created inside `autoCloseScope`'),
        ),
      );
    });

    test('contsturctor throws outside autoCloseScope with custom message', () {
      expect(
        () => TestAutoCloseable('error', errorMessage: 'some_message'),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'some_message'),
        ),
      );
    });

    testWidgets('close is called when registration throws',
        (WidgetTester tester) async {
      final closeable = TestCloseable('error');
      expect(
        () => Closeable.autoClose(closeable),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message',
              'TestCloseable must be created inside `autoCloseScope`'),
        ),
      );
      expect(closeable.closeCalled, true);
    });
  });
}
