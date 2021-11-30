import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';

void main() {
  group('MimeTypeInfo', () {
    MimeTypeInfo createMimeTypeInfo({
      String label = 'label',
      List<int>? icon,
      String contentDescription = 'contentDescription',
    }) =>
        MimeTypeInfo(
          label: label,
          icon: icon != null
              ? Uint8List.fromList(icon)
              : Uint8List.fromList(const []),
          contentDescription: contentDescription,
        );

    test('constructor and properties', () {
      final mimeTypeInfo = createMimeTypeInfo();
      expect(mimeTypeInfo.label, 'label');
      expect(mimeTypeInfo.icon, const <int>[]);
      expect(mimeTypeInfo.contentDescription, 'contentDescription');
    });

    test('toString', () {
      final mimeTypeInfoShort = createMimeTypeInfo();
      final mimeTypeInfoMiddle =
          createMimeTypeInfo(icon: List.generate(10, (index) => index));
      final mimeTypeInfoLong =
          createMimeTypeInfo(icon: List.generate(100, (index) => index));
      expect(mimeTypeInfoShort.toString(),
          'MimeTypeInfo(label: label, icon: [], contentDescription: contentDescription)');
      expect(mimeTypeInfoMiddle.toString(),
          'MimeTypeInfo(label: label, icon: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], contentDescription: contentDescription)');
      expect(mimeTypeInfoLong.toString(),
          'MimeTypeInfo(label: label, icon: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ... and 90 more], contentDescription: contentDescription)');
    });

    test('serialization', () {
      final mimeTypeInfo = createMimeTypeInfo();
      expect(mimeTypeInfo.toMap(),
          MimeTypeInfo.fromMap(mimeTypeInfo.toMap()).toMap());
      expect(() => mimeTypeInfo.toMap()..['key'] = 'value',
          throwsUnsupportedError);
    });
  });
}
