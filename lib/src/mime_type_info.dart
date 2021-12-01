part of android_content_provider;

/// Detailed description of a specific MIME type, including an icon and label that describe the type
/// https://developer.android.com/reference/android/content/ContentResolver.MimeTypeInfo
class MimeTypeInfo {
  /// Creates a detailed description of a specific MIME type.
  const MimeTypeInfo({
    required this.label,
    required this.icon,
    required this.contentDescription,
  });

  /// A textual representation of this MIME type.
  final String label;

  /// A visual representation of this MIME type.
  final Uint8List icon;

  /// A content description for this MIME type.
  final String contentDescription;

  /// Creates a MIME type description from map.
  factory MimeTypeInfo.fromMap(BundleMap map) => MimeTypeInfo(
        label: map['label'] as String,
        icon: map['icon'] as Uint8List,
        contentDescription: map['contentDescription'] as String,
      );

  /// Converts the MIME type description to map.
  BundleMap toMap() => BundleMap.unmodifiable(<String, Object?>{
        'label': label,
        'icon': icon,
        'contentDescription': contentDescription,
      });

  static const _iconLogLength = 10;

  @override
  String toString() {
    final buffer = StringBuffer(objectRuntimeType(this, 'MimeTypeInfo'));
    buffer.write('(');
    buffer.write('label: $label, ');
    // A list of values to show.
    final iconValuesToShow =
        icon.sublist(0, math.min(_iconLogLength, icon.length)).join(', ');
    buffer.write('icon: [$iconValuesToShow');
    if (icon.length > _iconLogLength) {
      buffer.write(', ... and ${icon.length - _iconLogLength} more');
    }
    buffer.write('], contentDescription: $contentDescription)');
    return buffer.toString();
  }
}
