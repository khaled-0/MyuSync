import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myusync/app/app_theme.dart';
import 'package:myusync/app/player/mini_player_sheet.dart';
import 'package:myusync/app/playlist/media_entry_builder.dart';
import 'package:myusync/app/playlist/playlist_header.dart';
import 'package:myusync/model/media.dart';
import 'package:myusync/model/objectbox.g.dart';
import 'package:myusync/provider/player_provider.dart';
import 'package:myusync/provider/playlist_provider.dart';

class PlaylistTab extends StatelessWidget {
  const PlaylistTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      body: Consumer<PlaylistProvider>(
        child: PlaylistHeader(
          playAll: () => launchPlayer(context: context),
          shufflePlay: () => launchPlayer(
            context: context,
            playlist: context.read<PlaylistProvider>(),
            prepare: (player) => player.shuffle(preserveCurrentIndex: false),
          ),
        ),
        builder: (context, playlist, header) {
          if (AppTheme.isDesktop) {
            return RefreshIndicator(
              onRefresh: playlist.refresh,
              child: Row(
                children: [
                  Flexible(flex: 3, child: header!),
                  Flexible(
                    flex: 5,
                    child: playlistView(context, playlist),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: playlist.refresh,
            child: playlistView(context, playlist, header: header),
          );
        },
      ),
    );
  }

  Widget playlistView(
    BuildContext context,
    PlaylistProvider playlist, {
    Widget? header,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight * 2),
      itemCount: playlist.medias.length + (header != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (header != null && index == 0) return header;
        final media = playlist.medias[index - (header != null ? 1 : 0)];
        return MediaEntryBuilder(
          media,
          onTap: () => launchPlayer(context: context, initialMedia: media),
        );
      },
    );
  }

  static void launchPlayer({
    required BuildContext context,
    PlaylistProvider? playlist,
    Media? initialMedia,
    void Function(PlayerProvider provider)? prepare,
  }) {
    _scaffoldOf(context)?.showBottomSheet(
      (_) => ChangeNotifierProvider<PlayerProvider>(
        create: (_) => PlayerProvider(
          context.read<Store>(),
          playlist ?? context.read<PlaylistProvider>(),
          start: initialMedia,
          prepare: prepare,
        ),
        child: const MiniPlayerSheet(),
      ),
      enableDrag: true,
      shape: InputBorder.none,
      elevation: 0,
    );
  }

  static ScaffoldState? _scaffoldOf(BuildContext context) =>
      context.read<GlobalKey<ScaffoldState>>().currentState;
}
