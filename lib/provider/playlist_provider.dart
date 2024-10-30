import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:tube_sync/model/media.dart';
import 'package:tube_sync/model/playlist.dart';
import 'package:tube_sync/services/downloader_service.dart';
import 'package:tube_sync/services/media_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class PlaylistProvider extends ChangeNotifier {
  final Isar isar;
  final _ytClient = yt.YoutubeExplode().playlists;
  final Playlist playlist;
  final List<Media> medias = List.empty(growable: true);

  PlaylistProvider(this.isar, this.playlist) {
    for (final id in playlist.videoIds) {
      final media = isar.medias.where().idEqualTo(id).findFirst();
      if (media != null) medias.add(media);
    }
    notifyListeners();
    updateDownloadStatus();
    refresh();
  }

  Future<void> refresh() async {
    try {
      if (!await DownloaderService.hasInternet) return;
      final vids = await _ytClient.getVideos(playlist.id).toList();
      medias.clear();
      medias.addAll(vids.map(Media.fromYTVideo));
      // Update playlist
      playlist.videoIds.clear();
      playlist.videoIds.addAll(medias.map((m) => m.id));
      // Save to DB
      isar.writeAsyncWith(playlist, (db, data) => db.playlists.put(data));
      isar.writeAsyncWith(medias, (db, data) => db.medias.putAll(data));
      updateDownloadStatus();
      notifyListeners();
    } catch (_) {
      //TODO Error
    }
  }

  void updateDownloadStatus({Media? media}) {
    if (media != null) {
      media.downloaded = MediaService().isDownloaded(media);
      notifyListeners();
      return;
    }

    for (final media in medias) {
      media.downloaded = MediaService().isDownloaded(media);
    }

    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
