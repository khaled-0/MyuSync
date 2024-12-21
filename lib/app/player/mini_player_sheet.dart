import 'package:flutter/material.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:provider/provider.dart';
import 'package:tubesync/app/app_theme.dart';
import 'package:tubesync/app/player/components/sleep_time_indicator.dart';
import 'package:tubesync/app/player/large_player_sheet.dart';
import 'package:tubesync/clients/media_client.dart';
import 'package:tubesync/model/media.dart';
import 'package:tubesync/model/objectbox.g.dart';
import 'package:tubesync/model/preferences.dart';
import 'package:tubesync/provider/player_provider.dart';

class MiniPlayerSheet extends StatelessWidget {
  const MiniPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const Key("MiniPlayer"),
      confirmDismiss: (direction) async {
        switch (direction) {
          case DismissDirection.startToEnd:
            context.read<PlayerProvider>().previousTrack();
            return false;

          case DismissDirection.endToStart:
            context.read<PlayerProvider>().nextTrack();
            return false;

          default:
            return false;
        }
      },
      direction: DismissDirection.horizontal,
      background: const Row(
        children: [
          SizedBox(width: 18),
          Icon(Icons.skip_previous_rounded),
        ],
      ),
      secondaryBackground: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.skip_next_rounded),
          SizedBox(width: 18),
        ],
      ),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.2,
        DismissDirection.endToStart: 0.2,
      },
      child: ValueListenableBuilder(
        key: const ValueKey("NowPlaying"),
        valueListenable: context.read<PlayerProvider>().nowPlaying,
        builder: (context, nowPlaying, _) {
          return Column(
            key: ValueKey(nowPlaying.hashCode),
            mainAxisSize: MainAxisSize.min,
            children: [
              mediaDetails(context, nowPlaying),
              // Progress Indicator
              Selector<PlayerProvider, bool>(
                selector: (_, provider) => provider.buffering,
                builder: (_, buffering, progressIndicator) {
                  if (!buffering) return progressIndicator!;
                  return LinearProgressIndicator(
                    minHeight: adaptiveIndicatorHeight,
                  );
                },
                child: StreamBuilder<Duration>(
                  stream: context.read<PlayerProvider>().player.positionStream,
                  builder: (context, snapshot) {
                    final duration = nowPlaying.durationMs;
                    var progress = (duration != null && snapshot.hasData)
                        ? snapshot.requireData.inMilliseconds / duration
                        : null;
                    return LinearProgressIndicator(
                      minHeight: adaptiveIndicatorHeight,
                      value: progress,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double get adaptiveIndicatorHeight {
    return AppTheme.isDesktop ? 3 : 1.5;
  }

  Widget mediaDetails(BuildContext context, Media media) {
    return ListTile(
      onTap: () => openPlayerSheet(context),
      contentPadding: const EdgeInsets.only(left: 8, right: 4),
      leading: leading(context, media),
      titleTextStyle: Theme.of(context).textTheme.bodyMedium,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            media.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            media.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Selector<PlayerProvider, List<Media>>(
            selector: (_, provider) => provider.playlist,
            builder: (context, playlist, _) => Text(
              "${playlist.indexOf(media) + 1}/${playlist.length}"
              " \u2022 ${playlistInfo(context)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      //Player Actions
      trailing: actions(context),
    );
  }

  Widget actions(BuildContext context) {
    return Selector<PlayerProvider, bool>(
      selector: (_, provider) => provider.buffering,
      child: _secondaryAction(context),
      builder: (context, buffering, extraAction) {
        if (buffering) return extraAction ?? const SizedBox();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder(
              stream: context.read<PlayerProvider>().player.playerStateStream,
              builder: (context, state) {
                if (state.data?.playing == true) {
                  return IconButton(
                    onPressed: context.read<PlayerProvider>().player.pause,
                    icon: const Icon(Icons.pause_rounded),
                  );
                }
                return IconButton(
                  onPressed: context.read<PlayerProvider>().player.play,
                  icon: const Icon(Icons.play_arrow_rounded),
                );
              },
            ),
            if (extraAction != null) extraAction,
          ],
        );
      },
    );
  }

  Widget leading(BuildContext context, Media media) {
    return StreamBuilder(
      stream: context.read<PlayerProvider>().sleepTimerCountdown,
      initialData: context.read<PlayerProvider>().sleepTimer,
      builder: (context, snapshot) => CircleAvatar(
        radius: 24,
        backgroundImage: NetworkToFileImage(
          url: media.thumbnailStd,
          file: MediaClient().thumbnailFile(media.thumbnailStd),
        ),
        child: const SleepTimeIndicator.static(),
      ),
    );
  }

  Widget? _secondaryAction(BuildContext context) {
    final action = context.read<Store>().box<Preferences>().getValue<int>(
          Preference.miniPlayerSecondaryAction,
          MiniPlayerSecondaryActions.Close.index,
        )!;

    switch (MiniPlayerSecondaryActions.values[action]) {
      case MiniPlayerSecondaryActions.Close:
        return IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        );
      case MiniPlayerSecondaryActions.Shuffle:
        return IconButton(
          onPressed: () => context.read<PlayerProvider>().shuffle(
                preserveCurrentIndex: false,
              ),
          icon: const Icon(Icons.shuffle_rounded),
        );
      case MiniPlayerSecondaryActions.None:
        return null;
    }
  }

  void openPlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      barrierColor: adaptiveSheetBarrierColor,
      builder: (_) => MultiProvider(
        providers: [
          Provider.value(value: context.read<Store>()),
          ChangeNotifierProvider<PlayerProvider>.value(
            value: context.read<PlayerProvider>(),
          ),
        ],
        child: const LargePlayerSheet(),
      ),
    );
  }

  Color? get adaptiveSheetBarrierColor {
    if (AppTheme.isDesktop) return null;
    return Colors.transparent;
  }

  String playlistInfo(BuildContext context) {
    final playlist = context.read<PlayerProvider>().playlistInfo;
    if (playlist.length == 1) {
      return "${playlist[0].title} by ${playlist[0].author}";
    }

    return "${playlist[0].title} and ${playlist.length - 1} more";
  }
}

// ignore: constant_identifier_names
enum MiniPlayerSecondaryActions { Close, Shuffle, None }
