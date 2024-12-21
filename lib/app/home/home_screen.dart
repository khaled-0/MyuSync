import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:tubesync/app/app_theme.dart';
import 'package:tubesync/app/library/import_playlist_dialog.dart';
import 'package:tubesync/app/library/library_tab.dart';
import 'package:tubesync/app/more/more_tab.dart';
import 'package:tubesync/clients/in_app_update_client.dart';
import 'package:tubesync/model/objectbox.g.dart';
import 'package:tubesync/model/preferences.dart';
import 'package:tubesync/provider/library_provider.dart';

import 'home_app_bar.dart';
import 'home_navigation_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: HomeNavigationBar.length,
      child: MultiProvider(
        providers: [
          //FIXME https://github.com/fluttercommunity/plus_plugins/issues/1241
          StreamProvider<InternetStatus>(
            create: (_) => InternetConnection().onStatusChange,
            initialData: InternetStatus.connected,
          ),
          Provider<GlobalKey<ScaffoldState>>(create: (_) => GlobalKey()),
          ChangeNotifierProvider<LibraryProvider>(
            create: (_) => LibraryProvider(context.read<Store>()),
          ),
        ],
        builder: (context, child) {
          if (AppTheme.isDesktop) {
            return Row(
              children: [
                const HomeNavigationBar.rail(),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Scaffold(
                    key: Provider.of<GlobalKey<ScaffoldState>>(context),
                    appBar: const HomeAppBar(),
                    body: child!,
                    bottomNavigationBar: const HomeNavigationBar(),
                  ),
                ),
              ],
            );
          }
          return Scaffold(
            key: Provider.of<GlobalKey<ScaffoldState>>(context),
            appBar: const HomeAppBar(),
            body: child!,
            bottomNavigationBar: const HomeNavigationBar(),
          );
        },
        child: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [const HomeTab(), MoreTab()],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final homeNavigator = GlobalKey<NavigatorState>();
  StreamSubscription? shareHandler;
  late final prefs = context.read<Store>().box<Preferences>();

  @override
  void initState() {
    super.initState();
    // TODO: Add IOS Support
    if (Platform.isAndroid) {
      shareHandler = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(handleSharedData);

      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then(handleSharedData)
          .whenComplete(ReceiveSharingIntent.instance.reset);
    }

    // Check for update
    if (prefs.getValue(Preference.inAppUpdate, true)!) {
      InAppUpdateClient.checkFromGitHub().then((changes) {
        if (!mounted || changes == null) return;
        InAppUpdateClient.showUpdateDialog(context, changes);
      }).catchError((_) {});
    }
  }

  void handleSharedData(List<SharedMediaFile> value) {
    final url = value.firstOrNull?.path;
    if (url == null || !mounted) return;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<LibraryProvider>(),
        child: ImportPlaylistDialog(url: url),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    shareHandler?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
      child: NavigatorPopHandler(
        onPopWithResult: (_) => homeNavigator.currentState?.pop(),
        child: Navigator(
          key: homeNavigator,
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => const LibraryTab(),
          ),
        ),
      ),
    );
  }
}
