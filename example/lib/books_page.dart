///
/// This example shows off and interaction with [AndroidContentProvider],
/// defined by `example_provider` app.
///
library;

import 'package:android_content_provider/android_content_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BooksPage extends HookConsumerWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(booksDataStateHolderProvider.select((value) => value));
    final books = state.books;
    final bookDataManager = ref.watch(bookDataManagerProvider);

    final textEditingController = useTextEditingController();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((timestamp) {
        bookDataManager.query();
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books example'),
        leading: BackButton(onPressed: Navigator.of(context).pop),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.success == false
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Couldn't fetch books. Did you install the `example_provider` app?",
                          textAlign: TextAlign.center,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: bookDataManager.query,
                        )
                      ],
                    ),
                  ),
                )
              : books!.isEmpty
                  ? const Center(child: Text('No books'))
                  : ListView.builder(
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(book.id.toString()),
                          ),
                          title: Text(book.title),
                          subtitle: Text(book.author),
                        );
                      },
                    ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: 80,
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(labelText: 'Book ID'),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ], // Only numbers can be entered
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => bookDataManager.insert(
                  int.parse(textEditingController.text.trim()),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => bookDataManager.delete(
                  int.parse(textEditingController.text.trim()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final booksDataStateHolderProvider =
    StateNotifierProvider<BookDataStateHolder, BooksState>(
  (ref) => BookDataStateHolder(),
);

final bookDataManagerProvider = Provider(
  (ref) => BookDataManager(
    ref.watch(booksDataStateHolderProvider.notifier),
  ),
);

class BooksState {
  final List<BookData>? books;
  final bool? success;

  const BooksState(this.books, this.success);

  bool get isLoading => success == null;
}

class BookDataStateHolder extends StateNotifier<BooksState> {
  BookDataStateHolder() : super(_initState);

  static const _initState = BooksState(null, null);

  void updateBooks(List<BookData>? value) {
    state = BooksState(value, state.success);
  }

  void setLoading() {
    state = _initState;
  }

  void updateSuccess(bool value) {
    state = BooksState(state.books, value);
  }
}

class BookDataManager {
  final BookDataStateHolder _bookDataStateHolder;

  BookDataManager(this._bookDataStateHolder);

  /// A URI of the content provider defined in `example_provider` app.
  static const _baseUri =
      'content://com.nt4f04und.android_content_provider_example.MyAndroidContentProvider';
  static const _booksUri = '$_baseUri/books';

  /// Calls [AndroidContentResolver.query].
  /// We are calling anther app to access its functions, in this case, list a collection of books.
  Future<void> query() async {
    _bookDataStateHolder.setLoading();

    final cursor = await AndroidContentResolver.instance.query(uri: _booksUri);
    if (cursor == null) {
      _bookDataStateHolder.updateSuccess(false);
      return;
    }

    // Register observer to re-request data when the owning app sends notifications
    // that the underlying data changed.
    await cursor.registerContentObserver(BookContentObserver(this));

    // Fetch the data
    final batch = BookData.createBatch(cursor);
    final bookCount =
        (await cursor.batchedGet().getCount().commit()).first as int;
    final booksData = await batch.commitRange(0, bookCount);
    final books =
        booksData.map((data) => BookData.fromCursorData(data)).toList();

    _bookDataStateHolder.updateBooks(books);
    _bookDataStateHolder.updateSuccess(true);
  }

  /// Calls [AndroidContentResolver.delete].
  /// We are calling anther app to access its functions, in this case, delete a book.
  Future<void> insert(int id) async {
    await AndroidContentResolver.instance.insert(
      uri: _booksUri,
      values: BookData(
        id: id,
        title: 'Title $id',
        author: 'Author $id',
      ).toContentValues(),
    );
  }

  /// Calls [AndroidContentResolver.delete].
  /// We are calling anther app to access its functions, in this case, delete a book.
  Future<void> delete(int id) async {
    await AndroidContentResolver.instance.delete(uri: '$_booksUri/$id');
  }
}

class BookContentObserver extends ContentObserver {
  final BookDataManager _bookDataManager;

  BookContentObserver(this._bookDataManager);

  @override
  void onChange(bool selfChange, String? uri, int flags) {
    debugPrint('selfChange $selfChange uri $uri flags $flags');
    // Re-request on update
    _bookDataManager.query();
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

  /// Creates an object from the data retrieved from the cursor.
  factory BookData.fromCursorData(List<Object?> data) => BookData(
        id: data[0] as int,
        title: data[1] as String,
        author: data[2] as String,
      );

  /// Returns a markup of what data to get from the cursor.
  static NativeCursorGetBatch createBatch(NativeCursor cursor) =>
      cursor.batchedGet()
        ..getInt(0)
        ..getString(1)
        ..getString(2);

  ContentValues toContentValues() => ContentValues()
    ..putInt('id', id)
    ..putString('title', title)
    ..putString('author', author);
}
