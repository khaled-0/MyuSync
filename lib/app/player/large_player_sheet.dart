import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myusync/app/app_theme.dart';
import 'package:myusync/app/player/components/action_buttons.dart';
import 'package:myusync/app/player/components/artwork.dart';
import 'package:myusync/app/player/components/lyrics.dart';
import 'package:myusync/app/player/player_menu_sheet.dart';
import 'package:myusync/app/player/components/seekbar.dart';
import 'package:myusync/app/player/components/sleep_time_indicator.dart';
import 'package:myusync/app/player/player_queue_sheet.dart';
import 'package:myusync/model/media.dart';
import 'package:myusync/provider/player_provider.dart';
import 'package:window_manager/window_manager.dart';

class LargePlayerSheet extends StatefulWidget {
  const LargePlayerSheet({super.key});

  @override
  State<LargePlayerSheet> createState() => _LargePlayerSheetState();
}

class _LargePlayerSheetState extends State<LargePlayerSheet>
    with TickerProviderStateMixin {
  late final tabController = TabController(length: 3, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const RotatedBox(
            quarterTurns: -1, // Negative 90 Deg
            child: Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        title: const DragToMoveArea(
          child: Text("MyuSync"),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<PlayerProvider>(),
                child: const PlayerMenuSheet(),
              ),
            ),
            icon: const Icon(Icons.more_vert_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Music'),
                icon: Icon(Icons.art_track_rounded),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Lyrics'),
                icon: Icon(Icons.lyrics_rounded),
              ),
              ButtonSegment(
                value: 2,
                label: Text('Video'),
                icon: Icon(Icons.play_circle_fill_rounded),
              ),
            ],
            showSelectedIcon: false,
            selected: {tabController.index},
            onSelectionChanged: (value) => setState(
              () => tabController.animateTo(value.first),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                const Artwork(),
                const Lyrics(),
                const Center(child: Text("Soon")),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SleepTimeIndicator(),
              ],
            ),
          ),
          const SeekBar(),
          const SizedBox(height: 12),
          if (AppTheme.isDesktop)
            Row(
              children: [
                const SizedBox(width: 8),
                const ActionButtons(),
                Expanded(child: queueView(context)),
              ],
            )
          else ...{
            const ActionButtons(),
            const SizedBox(height: 36),
            queueView(context),
          },
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget queueView(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<PlayerProvider>().nowPlaying,
      builder: (context, media, _) => Card.outlined(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 12),
          onTap: showPlayerQueue,
          title: Text(
            media.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                media.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Selector<PlayerProvider, List<Media>>(
                selector: (_, provider) => provider.playlist,
                builder: (context, playlist, _) => Text(
                  "${playlist.indexOf(media) + 1}/${playlist.length}"
                  " \u2022 ${playlistInfo(context)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
          leading: const Icon(Icons.playlist_play_rounded),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
      ),
    );
  }

  String playlistInfo(BuildContext context) {
    final playlist = context.read<PlayerProvider>().playlistInfo;
    if (playlist.length == 1) {
      return "${playlist[0].title} by ${playlist[0].author}";
    }

    return "${playlist[0].title} and ${playlist.length - 1} more";
  }

  void showPlayerQueue() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PlayerProvider>(),
        child: const PlayerQueueSheet(),
      ),
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
    );
  }
}
