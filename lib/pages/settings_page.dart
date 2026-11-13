// Settings (SettingActivity: grid of row_list_setting cards) and its sub pages.
import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../models.dart';
import '../parental.dart';
import '../session.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'details_kit.dart';
import 'nav.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = Store.currentAccount;
    final xtream = a?.type == AccountType.xtream;
    final items = <(String, String, VoidCallback)>[
      (S.general_setting, 'ic_player_setting', () => go(context, const _GeneralPage())),
      (S.ui, 'ic_pencil_ruler', () => go(context, const _UiPage())),
      if (xtream) (S.stream_format, 'ic_file_settings', () => go(context, const _FormatPage())),
      (S.multiple_screen, 'ic_grid_view', () => go(context, const _MultiScreenSetting())),
      (S.clear_data, 'ic_clean_code', () => go(context, const _ClearDataPage())),
      if (xtream) (S.automation, 'ic_engineering', () => go(context, const _AutomationPage())),
      (S.player_setting, 'ic_video_settings', () => go(context, const _PlayerPage())),
      (S.time_format, 'ic_time', () => go(context, const _TimeFormatPage())),
      (S.download_setting, 'ic_file_download_not', () => go(context, const _DownloadPage())),
      (S.notifications, 'ic_round_notifications', () => go(context, const NotificationsPage())),
      (S.parental_control, 'ic_player_lock', () => Parental.setup(context)),
      if (xtream) (S.profile, 'ic_profile', () => go(context, const ProfilePage())),
      (S.feedback, 'ic_feedback', () => feedbackDialog(context, 'Feedback')),
      (S.privacy_policy, 'ic_shield_keyhole', openPrivacy),
      (S.terms_and_conditions, 'ic_todo', openTerms),
      (S.about, 'ic_information', () => go(context, const _AboutPage())),
    ];
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(title: S.settings, icon: 'ic_setting'),
            SizedBox(height: 5.sdp),
            Expanded(
              child: Builder(
                builder: (context) {
                  // 4 columns of 90sdp square cards, like SettingActivity.
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 10.sdp),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisExtent: 100.sdp),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final (name, icon, onTap) = items[i];
                      return Center(
                        child: SizedBox(
                          width: 90.sdp,
                          height: 90.sdp,
                          child: Tap(
                            onTap: onTap,
                            builder: (f) => SaveBox(
                              focused: f,
                              padding: EdgeInsets.all(1.sdp),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2.sdp),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset('assets/img/card_bg.webp', fit: BoxFit.cover),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Ic(icon, size: 30.sdp, color: C.title),
                                        SizedBox(height: 5.sdp),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4.sdp),
                                          child: T(
                                            name,
                                            size: 9,
                                            color: C.title,
                                            weight: FontWeight.bold,
                                            lines: 2,
                                            align: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Common frame of the sub settings: title, SAVE button, bordered card.
class _SettingFrame extends StatelessWidget {
  final String title;
  final VoidCallback? onSave;
  final Widget child;
  const _SettingFrame({required this.title, this.onSave, required this.child});
  @override
  Widget build(BuildContext context) => PageBg(
    child: Padding(
      padding: EdgeInsets.all(5.sdp),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PageTop(title: title, icon: 'ic_setting'),
              ),
              if (onSave != null)
                Tap(
                  onTap: onSave,
                  builder: (f) => SaveBox(
                    focused: f,
                    padding: EdgeInsets.only(right: 10.sdp),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Ic('ic_save', size: 30.sdp, pad: 7.sdp),
                        T(S.save, size: 12),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 5.sdp),
          Expanded(
            child: Container(width: double.infinity, decoration: cardSub(), child: child),
          ),
        ],
      ),
    ),
  );
}

/// CheckBox row (focused_edt look).
class _Check extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Check(this.text, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => Tap(
    onTap: () => onChanged(!value),
    builder: (f) => Container(
      padding: EdgeInsets.all(6.sdp),
      margin: EdgeInsets.only(bottom: 5.sdp),
      decoration: BoxDecoration(color: f ? const Color(0x2DFFFFFF) : null, borderRadius: BorderRadius.circular(2.sdp)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? C.primary : Colors.white70,
            size: 20.sdp,
          ),
          SizedBox(width: 8.sdp),
          Flexible(child: T(text, size: 12, color: C.title)),
        ],
      ),
    ),
  );
}

/// RadioButton row.
class _Radio extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _Radio(this.text, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      padding: EdgeInsets.all(10.sdp),
      color: f ? const Color(0x2DFFFFFF) : null,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? C.select : Colors.white70,
            size: 18.sdp,
          ),
          SizedBox(width: 10.sdp),
          T(text, size: 13, color: C.title),
        ],
      ),
    ),
  );
}

void _saved(BuildContext context) {
  toast(context, 'Saved');
  Navigator.maybePop(context);
}

/// A list of radio choices with a SAVE button.
class _ChoicePage extends StatefulWidget {
  final String title;
  final List<String> options;
  final int initial;
  final ValueChanged<int> onSave;
  const _ChoicePage({required this.title, required this.options, required this.initial, required this.onSave});
  @override
  State<_ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<_ChoicePage> {
  late int _v = widget.initial;
  @override
  Widget build(BuildContext context) => _SettingFrame(
    title: widget.title,
    onSave: () {
      widget.onSave(_v);
      _saved(context);
    },
    child: Center(
      child: SizedBox(
        width: 300.sdp,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.options.length; i++)
              _Radio(widget.options[i], i == _v, () => setState(() => _v = i)),
          ],
        ),
      ),
    ),
  );
}

class _TimeFormatPage extends StatelessWidget {
  const _TimeFormatPage();
  @override
  Widget build(BuildContext context) => _ChoicePage(
    title: S.time_format,
    options: const ['24 Hours Format', '12 Hours Format'],
    initial: Store.use24h ? 0 : 1,
    onSave: (v) => Store.use24h = v == 0,
  );
}

class _FormatPage extends StatelessWidget {
  const _FormatPage();
  @override
  Widget build(BuildContext context) => _ChoicePage(
    title: S.stream_format,
    options: const ['Default', 'MPEGTS(.ts)', 'HLS(.m3u8)'],
    initial: Store.streamFormat,
    onSave: (v) => Store.streamFormat = v,
  );
}

class _PlayerPage extends StatelessWidget {
  const _PlayerPage();
  @override
  Widget build(BuildContext context) => _ChoicePage(
    title: S.player_setting,
    options: [S.hardware_decoding, S.software_decoding],
    initial: Store.hardwareDecoding ? 0 : 1,
    onSave: (v) => Store.hardwareDecoding = v == 0,
  );
}

class _AutomationPage extends StatelessWidget {
  const _AutomationPage();
  static const hours = [0, 5, 12, 24, 48];
  @override
  Widget build(BuildContext context) => _ChoicePage(
    title: '${S.automation} (auto update data)',
    options: const ['Off', 'Every 5 hours', 'Every 12 hours', 'Every day', 'Every 2 days'],
    initial: hours.indexOf(Store.autoUpdateHours).clamp(0, hours.length - 1),
    onSave: (v) => Store.autoUpdateHours = hours[v],
  );
}

class _MultiScreenSetting extends StatelessWidget {
  const _MultiScreenSetting();
  @override
  Widget build(BuildContext context) => _ChoicePage(
    title: S.multiple_screen,
    options: const ['Ask every time', 'Screen 1', 'Screen 2', 'Screen 3', 'Screen 4', 'Screen 5'],
    initial: Store.prefs.getInt('multi_screen') ?? 0,
    onSave: (v) => Store.prefs.setInt('multi_screen', v),
  );
}

class _GeneralPage extends StatefulWidget {
  const _GeneralPage();
  @override
  State<_GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<_GeneralPage> {
  bool _autoplay = Store.autoplayNext;
  bool _reverse = Store.prefs.getBool('cat_reverse') ?? false;
  @override
  Widget build(BuildContext context) => _SettingFrame(
    title: S.general_setting,
    onSave: () {
      Store.autoplayNext = _autoplay;
      Store.prefs.setBool('cat_reverse', _reverse);
      _saved(context);
    },
    child: SingleChildScrollView(
      padding: EdgeInsets.all(20.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Check(S.autoplay_next_episode, _autoplay, (v) => setState(() => _autoplay = v)),
          _Check(S.categories_reverse_order, _reverse, (v) => setState(() => _reverse = v)),
        ],
      ),
    ),
  );
}

class _UiPage extends StatefulWidget {
  const _UiPage();
  @override
  State<_UiPage> createState() => _UiPageState();
}

class _UiPageState extends State<_UiPage> {
  bool _title = Store.showCardTitle;
  bool _download = Store.showDownload;
  @override
  Widget build(BuildContext context) => _SettingFrame(
    title: S.ui_setting,
    onSave: () {
      Store.showCardTitle = _title;
      Store.showDownload = _download;
      _saved(context);
    },
    child: SingleChildScrollView(
      padding: EdgeInsets.all(20.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Check('Show movie / series name', _title, (v) => setState(() => _title = v)),
          _Check(S.show_download_button, _download, (v) => setState(() => _download = v)),
        ],
      ),
    ),
  );
}

class _DownloadPage extends StatefulWidget {
  const _DownloadPage();
  @override
  State<_DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<_DownloadPage> {
  bool _wifi = Store.prefs.getBool('dl_wifi') ?? true;
  bool _mobile = Store.prefs.getBool('dl_mobile') ?? true;
  @override
  Widget build(BuildContext context) => _SettingFrame(
    title: S.download_setting,
    onSave: () {
      Store.prefs.setBool('dl_wifi', _wifi);
      Store.prefs.setBool('dl_mobile', _mobile);
      _saved(context);
    },
    child: SingleChildScrollView(
      padding: EdgeInsets.all(20.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          T(S.download_network_description, size: 11, color: C.titleSub),
          SizedBox(height: 10.sdp),
          _Check(S.download_network_wifi, _wifi, (v) => setState(() => _wifi = v)),
          _Check(S.download_network_mobile, _mobile, (v) => setState(() => _mobile = v)),
        ],
      ),
    ),
  );
}

class _ClearDataPage extends StatelessWidget {
  const _ClearDataPage();

  Future<void> _run(BuildContext context, String name, Future<bool> Function() action) async {
    final ok = await appDialog(context, icon: 'ic_trash', title: name, msg: S.sure_delete);
    if (!ok) return;
    final done = await action();
    if (context.mounted) toast(context, done ? name : S.already_cleared);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, Future<bool> Function())>[
      (
        S.clear_cache,
        'ic_clean_code',
        () async {
          PaintingBinding.instance.imageCache.clear();
          return true;
        },
      ),
      (S.clear_channels, 'ic_trash', () => Store.clearRecentOf(ContentType.live)),
      (S.clear_movies, 'ic_trash', () => Store.clearRecentOf(ContentType.movie)),
      (S.clear_series, 'ic_trash', () => Store.clearRecentOf(ContentType.series)),
      (S.clear_playback_movies, 'ic_trash', () => Store.clearResume('movie:')),
      (S.clear_playback_episodes, 'ic_trash', () => Store.clearResume('episode:')),
    ];
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(title: S.clear_data, icon: 'ic_setting'),
            SizedBox(height: 5.sdp),
            Expanded(
              child: ListView(
                children: [
                  for (final (name, icon, action) in rows)
                    Tap(
                      onTap: () => _run(context, name, action),
                      builder: (f) => Container(
                        height: 43.sdp,
                        margin: EdgeInsets.only(bottom: 4.sdp),
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF),
                          borderRadius: BorderRadius.circular(1.sdp),
                          border: Border.all(color: f ? const Color(0xFFFFAB00) : C.border, width: 1.sdp),
                        ),
                        child: Row(
                          children: [
                            Ic(icon, size: 40.sdp, pad: 10.sdp, color: C.title),
                            T(name, size: 14, color: C.title),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  Widget _row(String icon, String title, String value, {VoidCallback? onTap}) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      color: f ? const Color(0x2DFFFFFF) : null,
      padding: EdgeInsets.symmetric(vertical: 2.sdp),
      child: Row(
        children: [
          SizedBox(width: 5.sdp),
          Ic(icon, size: 40.sdp, pad: 10.sdp, color: C.title),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                T(title, size: 13, color: C.title, weight: FontWeight.bold),
                SizedBox(height: 1.sdp),
                T(value.isEmpty ? S.n_a : value, size: 12, color: C.titleSub, lines: 1),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  BoxDecoration get _border => BoxDecoration(
    borderRadius: BorderRadius.circular(5.sdp),
    border: Border.all(color: C.titleSub.withValues(alpha: 0.35), width: 1.sdp),
  );

  @override
  Widget build(BuildContext context) {
    final app = Session.app;
    final line = Container(
      height: 1.sdp,
      color: const Color(0x12FFFFFF),
      margin: EdgeInsets.only(top: 5.sdp),
    );
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(title: S.about, icon: 'ic_information'),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 5.sdp),
                      decoration: _border,
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10.sdp),
                            child: Logo(size: 70.sdp),
                          ),
                          Container(width: 1.sdp, height: 90.sdp, color: C.border),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(10.sdp),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  T(AppConfig.appName, size: 16, color: C.title, weight: FontWeight.bold),
                                  SizedBox(height: 3.sdp),
                                  T(
                                    (app?.description.isNotEmpty ?? false) ? app!.description : S.love_this_app,
                                    size: 12,
                                    color: C.titleSub,
                                    lines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(top: 10.sdp),
                            decoration: _border,
                            child: Column(
                              children: [
                                _row('ic_building', S.company, app?.author ?? ''),
                                line,
                                _row(
                                  'ic_mail',
                                  S.email,
                                  app?.email ?? '',
                                  onTap: (app?.email.isNotEmpty ?? false)
                                      ? () => openExternal('mailto:${app!.email}')
                                      : null,
                                ),
                                line,
                                _row(
                                  'ic_global',
                                  S.website,
                                  app?.website ?? '',
                                  onTap: (app?.website.isNotEmpty ?? false) ? () => openWeb(app!.website) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.sdp),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(top: 10.sdp),
                            decoration: _border,
                            child: Column(
                              children: [
                                _row('ic_phone', S.contact, app?.contact ?? ''),
                                line,
                                _row('ic_information', S.version, AppConfig.version),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(10.sdp),
                      child: T(S.made_with_in, size: 11, color: C.titleSub, weight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
