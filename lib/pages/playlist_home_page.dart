// Home for M3U playlist users (activity_themes_one_ui_playlist):
// Live TV on the left, VOD and Multiscreen on the right.
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'downloads_page.dart';
import 'home_page.dart';
import 'multi_screen_page.dart';
import 'nav.dart';
import 'notifications_page.dart';
import 'settings_page.dart';

class PlaylistHomePage extends StatefulWidget {
  const PlaylistHomePage({super.key});
  @override
  State<PlaylistHomePage> createState() => _PlaylistHomePageState();
}

class _PlaylistHomePageState extends State<PlaylistHomePage> with HomeActions {
  @override
  Widget build(BuildContext context) {
    final a = Store.currentAccount;
    final liveBusy = !lib.has(ContentType.live) || progress[ContentType.live] != null;
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Logo(size: 30.sdp),
                  SizedBox(width: 10.sdp),
                  T(S.app_name, size: 16),
                  Expanded(child: T(shortDate(DateTime.now()), size: 11, align: TextAlign.center, lines: 1)),
                  Ic('ic_wifi', size: 35.sdp, pad: 8.sdp),
                  IconTap('ic_round_notifications', onTap: () => go(context, const NotificationsPage())),
                  if (Session.app?.download ?? true)
                    IconTap('iv_downloading', onTap: () => go(context, const DownloadsPage())),
                  IconTap('ic_people', pad: 6, onTap: () => signOut(context)),
                  IconTap('ic_player_setting', onTap: () => go(context, const SettingsPage())),
                ],
              ),
            ),
            SizedBox(height: 3.sdp),
            Expanded(
              flex: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 10,
                    child: BigTile(
                      gradient: G.tv,
                      icon: 'ic_tv',
                      iconSize: 90,
                      title: S.live_tv_home,
                      titleSize: 20,
                      type: ContentType.live,
                      progress: progress[ContentType.live],
                      onTap: () => openSection(ContentType.live, playlist: true),
                      onRenew: () => lib.has(ContentType.live)
                          ? reloadSection(ContentType.live)
                          : downloadSection(ContentType.live),
                    ),
                  ),
                  SizedBox(width: 10.sdp),
                  Expanded(
                    flex: 13,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 20,
                          child: BigTile(
                            gradient: G.movies,
                            icon: 'ic_movie',
                            iconSize: 60,
                            title: 'VOD',
                            titleSize: 19,
                            type: ContentType.movie,
                            progress: progress[ContentType.movie],
                            onTap: () => openSection(ContentType.movie, playlist: true),
                            onRenew: () => lib.has(ContentType.movie)
                                ? reloadSection(ContentType.movie)
                                : downloadSection(ContentType.movie),
                          ),
                        ),
                        SizedBox(height: 10.sdp),
                        Expanded(
                          flex: 7,
                          child: SmallTile(
                            icon: 'ic_multiple_screen',
                            title: S.multiple_screen,
                            dim: liveBusy,
                            onTap: () => needLive(const MultiScreenPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  T('${S.logged_in} ${a?.name ?? ''}', size: 12, lines: 1),
                  const Spacer(),
                  T(greeting(), size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
