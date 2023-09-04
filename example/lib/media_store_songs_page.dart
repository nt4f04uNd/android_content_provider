///
/// This example shows off fetching songs from MediaStore with [AndroidContentResolver].
///

import 'package:android_content_provider/android_content_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaStoreSongsPage extends HookConsumerWidget {
  const MediaStoreSongsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs =
        ref.watch(mediaStoreSongsStateHolderProvider.select((value) => value));
    final mediaStoreSongsManager = ref.watch(mediaStoreSongsManagerProvider);

    useEffect(() {
      mediaStoreSongsManager.init();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaStore songs example'),
        leading: const BackButton(),
      ),
      body: songs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final book = songs[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(book.id.toString()),
                  ),
                  title: Text(book.title),
                );
              },
            ),
    );
  }
}

final mediaStoreSongsStateHolderProvider =
    StateNotifierProvider<MediaStoreSongsStateHolder, List<SongData>?>(
  (ref) => MediaStoreSongsStateHolder(),
);

final mediaStoreSongsManagerProvider = Provider(
  (ref) => MediaStoreSongsManager(
    ref.watch(mediaStoreSongsStateHolderProvider.notifier),
  ),
);

class MediaStoreSongsStateHolder extends StateNotifier<List<SongData>?> {
  MediaStoreSongsStateHolder() : super(null);

  void update(List<SongData>? value) {
    state = value;
  }
}

class MediaStoreSongsManager {
  final MediaStoreSongsStateHolder _mediaStoreSongsStateHolder;

  MediaStoreSongsManager(this._mediaStoreSongsStateHolder);

  Future<void> init() async {
    await Permission.storage.request();

    final cursor = await AndroidContentResolver.instance.query(
      // MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
      uri: 'content://media/external/audio/media',
      projection: SongData.contentProviderProjection,
      selection: null,
      selectionArgs: null,
      sortOrder: null,
    );
    try {
      final end = (await cursor!.batchedGet().getCount().commit()).first as int;
      final batch = SongData.createBatch(cursor);

      late List<List<Object?>> songsData;

      // Fast!
      // While a bit less flexible, commitRange is much faster (approximately 10x)
      await measure(() async {
        songsData = await batch.commitRange(0, end);
      });

      final songs =
          songsData.map((data) => SongData.fromCursorData(data)).toList();
      _mediaStoreSongsStateHolder.update(songs);

      // Slow!
      // But can be useful for lots of atomic operations on large cursors.
      List<SongData> slowSongs = [];
      await measure(() async {
        while (await cursor.moveToNext()) {
          final songData = await batch.commit();
          slowSongs.add(SongData.fromCursorData(songData));
        }
      });

      final songTitles = slowSongs.map((e) => e.title);
      final slowSongTitles = slowSongs.map((e) => e.title);
      final same = songTitles.toString() == slowSongTitles.toString();
      // Prints true
      debugPrint(
        'Slow and fast songs are same: $same $songTitles $slowSongTitles',
      );
    } finally {
      cursor?.close();
    }
  }
}

Future<void> measure(Function callback) async {
  final s = Stopwatch();
  s.start();
  await callback();
  s.stop();
  debugPrint('elapsed ${s.elapsedMilliseconds}');
}

class SongData {
  final int id;
  final String title;

  const SongData({
    required this.id,
    required this.title,
  });

  static const contentProviderProjection = [
    '_id',
    'title',
  ];

  /// Creates an object from the data retrieved from the cursor.
  factory SongData.fromCursorData(List<Object?> data) => SongData(
        id: data[0] as int,
        title: data[1] as String,
      );

  /// Returns a markup of what data to get from the cursor.
  static NativeCursorGetBatch createBatch(NativeCursor cursor) =>
      cursor.batchedGet()
        ..getInt(0)
        ..getString(1);
}
