///
/// This example shows off how to declare an [AndroidContentProvider].
///
/// To see an example of AndroidContentResolver, check out the `example` app.
///

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:android_content_provider/android_content_provider.dart';
import 'package:collection/collection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AndroidContentProvider example'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'This app does nothing, only defines an AndroidContentProvider, '
              'which can be used by other apps. '
              'To see it in action, launch the `example` app, which interacts with this provider',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class BookData {
  final int id;
  final String title;
  final String author;

  const BookData({
    required this.id,
    required this.title,
    required this.author,
  });

  static const contentProviderProjection = [
    'id',
    'title',
    'author',
  ];

  String get uri => '$booksUri/$id';

  List<Object?> toCursorRow() => [id, title, author];

  factory BookData.fromContentValues(ContentValues contentValues) => BookData(
        id: contentValues.getInt('id')!,
        title: contentValues.getString('title')!,
        author: contentValues.getString('author')!,
      );
}

const baseUri = 'content://com.nt4f04und.android_content_provider_example.MyAndroidContentProvider';
const booksUri = '$baseUri/books';

class MyAndroidContentProvider extends AndroidContentProvider {
  MyAndroidContentProvider(String authority) : super(authority);

  final _booksDataList = List.generate(
    10,
    (index) => BookData(
      id: index,
      title: 'Title $index',
      author: 'Author $index',
    ),
  );

  int? _getBookId(String uri) {
    final regexp = RegExp('$booksUri/([0-9]+)');
    final match = regexp.firstMatch(uri);
    if (match != null) {
      final capturedNumber = match.group(1);
      if (capturedNumber != null) {
        final id = int.tryParse(capturedNumber);
        if (id != null) {
          return id;
        }
      }
    }
    return null;
  }

  bool _isBookUri(String uri) => uri.startsWith(booksUri);

  @override
  Future<int> delete(
    String uri,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    debugPrint('delete $uri');

    // See `example` app for the resolver usage example
    if (_isBookUri(uri)) {
      final id = _getBookId(uri);
      if (id == null) {
        debugPrint('could not find $id');
      } else {
        final book = _booksDataList.firstWhereOrNull((element) => element.id == id);
        if (book != null) {
          _booksDataList.remove(book);
          debugPrint('successfully removed book with id $id');
          await AndroidContentResolver.instance.notifyChange(uri: uri);
          return 1;
        } else {
          debugPrint('delete failed: no book with such id $id');
        }
      }
    }
    return 0;
  }

  @override
  Future<String?> getType(String uri) async {
    return null;
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) async {
    debugPrint('insert $uri');

    // See `example` app for the resolver usage example
    if (_isBookUri(uri)) {
      if (values != null) {
        final book = BookData.fromContentValues(values);
        final index = book.id.clamp(0, _booksDataList.length);
        _booksDataList.insert(index, book);
        debugPrint('successfully insert book with with uri ${book.uri}');
        await AndroidContentResolver.instance.notifyChange(uri: uri);
        return book.uri;
      }
      debugPrint('could not create a book');
    }
    return null;
  }

  @override
  Future<CursorData?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  ) async {
    debugPrint('query $uri');

    if (_isBookUri(uri)) {
      // See example_resolver for the resolver usage example
      final data = MatrixCursorData(
        columnNames: BookData.contentProviderProjection,
        notificationUris: [booksUri],
      );
      for (final bookData in _booksDataList) {
        data.addRow(bookData.toCursorRow());
      }
      return data;
    }
    return null;
  }

  @override
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    return 0;
  }
}

@pragma('vm:entry-point')
void exampleContentProviderEntrypoint() {
  MyAndroidContentProvider(
    'com.nt4f04und.android_content_provider_example.MyAndroidContentProvider',
  );
}
