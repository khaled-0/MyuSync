import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_sync/model/playlist.dart';
import 'package:tube_sync/provider/library_provider.dart';

class LibraryMenuSheet extends StatelessWidget {
  final Playlist playlist;

  const LibraryMenuSheet(this.playlist, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(12),
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
          ListTile(
            onTap: () {
              context.read<LibraryProvider>().delete(playlist);
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