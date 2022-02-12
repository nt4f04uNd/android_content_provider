/// This library exposes ContentProvider and related ContentResolver APIs on Android.
///
/// Read more in the [README](https://github.com/nt4f04uNd/android_content_provider).
library android_content_provider;

import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

part 'src/android_content_provider.dart';
part 'src/android_content_resolver.dart';
part 'src/android_content_resolver_compat.dart';
part 'src/annotation.dart';
part 'src/calling_identity.dart';
part 'src/cancellation_signal.dart';
part 'src/codec.dart';
part 'src/content_observer.dart';
part 'src/content_values.dart';
part 'src/contract.dart';
part 'src/cursor.dart';
part 'src/core.dart';
part 'src/mime_type_info.dart';
