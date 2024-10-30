import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_sync/app/more/downloads/active_downloads_screen.dart';
import 'package:tube_sync/model/media.dart';
import 'package:tube_sync/services/downloader_service.dart';
import 'package:tube_sync/services/media_service.dart';
import 'package:tube_sync/provider/playlist_provider.dart';

class MediaMenuSheet extends StatelessWidget {
  final Media media;

  const MediaMenuSheet(this.media, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Drag Handle
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 4,
              width: kMinInteractiveDimension,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (media.downloaded != true)
            ListTile(
              onTap: () {
                DownloaderService().download(media);
                Navigator.pop(context);
                ActiveDownloadsScreen.showEnqueuedSnackbar(context);
              },
              leading: Icon(Icons.download_rounded),
              title: Text("Download"),
            ),
          if (media.downloaded == true)
            ListTile(
              onTap: () {
                MediaService().delete(media);
                context.read<PlaylistProvider>().updateDownloadStatus(
                      media: media,
                    );
                Navigator.pop(context);
              },
              leading: Icon(Icons.delete_rounded),
              title: Text("Delete"),
            )
        ],
      ),
    );
  }
}
