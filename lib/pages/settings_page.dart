// Settings (SettingActivity: grid of row_list_setting cards) and its sub pages.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'speed_test_page.dart';

/// Wifi Setting / Notification Setting: iOS only lets apps open their own
/// page in the Settings app.
Future<void> _openPhoneSettings(BuildContext context) async {
  try {
    if (await launchUrl(Uri.parse('app-settings:'))) return;
  } catch (_) {}
  if (context.mounted) toast(context, 'Open the Settings app on your phone');
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = Store.currentAccount;
    final xtream = a?.type == AccountType.xtream;
    // Same order as SettingActivity (VPN is not part of the iPhone app).
    final items = <(String, String, VoidCallback)>[
      (S.general_setting, 'ic_player_setting', () => go(context, const _GeneralPage())),
      (S.ui, 'ic_pencil_ruler', () => go(context, const _UiPage())),
      if (xtream) (S.stream_format, 'ic_file_settings', () => go(context, const _FormatPage())),
      (S.multiple_screen, 'ic_grid_view', () => go(context, const _MultiScreenSetting())),
      (S.clear_data, 'ic_clean_code', () => go(context, const _ClearDataPage())),
      if (xtream) (S.automation, 'ic_engineering', () => go(context, const _AutomationPage())),
      (S.player_setting, 'ic_video_settings', () => go(context, const _PlayerPage())),
      (S.time_format, 'ic_time', () => go(context, const _TimeFormatPage())),
      (S.wifi_setting, 'ic_wifi', () => _openPhoneSettings(context)),
      (S.download_setting, 'ic_file_download_not', () => go(context, const _DownloadPage())),
      (S.post_notification, 'ic_round_notification', () => _openPhoneSettings(context)),
      (S.notifications, 'ic_round_notifications', () => go(context, const NotificationsPage())),
      (S.parental_control, 'ic_player_lock', () => Parental.setup(context)),
      if (xtream) (S.profile, 'ic_profile', () => go(context, const ProfilePage())),
      (S.speed_test, 'ic_speed', () => go(context, const SpeedTestPage())),
      (S.feedback, 'ic_feedback', () => feedbackDialog(context, 'Feedback')),
      (S.privacy_policy, 'ic_shield_keyhole', openPrivacy),
      (S.terms_and_conditions, 'ic_todo', openTerms),
      (S.about, 'ic_information', () => go(context, const _AboutPage())),
    ];
    // AdapterSetting: 4 columns as wide as a quarter of the screen, 60% as
    // high, with a 3sdp margin round each card.
    final tileH = MediaQuery.sizeOf(context).width / 4 * 0.6;
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(title: S.settings, icon: 'ic_setting'),
            SizedBox(height: 5.sdp),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.only(bottom: 20.sdp),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: tileH + 6.sdp,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final (name, icon, onTap) = items[i];
                  return Padding(
                    padding: EdgeInsets.all(3.sdp),
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
                                    padding: EdgeInsets.symmetric(horizontal: 5.sdp),
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
/// SAVE shows a spinner for half a second, then the "Save Data" toast, and
/// the page stays open like the Android activities.
class _SettingFrame extends StatefulWidget {
  final String title;
  final FutureOr<void> Function()? onSave;
  final Widget child;
  const _SettingFrame({required this.title, this.onSave, required this.child});
  @override
  State<_SettingFrame> createState() => _SettingFrameState();
}

class _SettingFrameState extends State<_SettingFrame> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onSave!();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _saving = false);
    toast(context, 'Save Data');
  }

  @override
  Widget build(BuildContext context) => PageBg(
    child: Padding(
      padding: EdgeInsets.all(5.sdp),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PageTop(title: widget.title, icon: 'ic_setting'),
              ),
              if (widget.onSave != null) _SaveButton(text: S.save, icon: 'ic_save', busy: _saving, onTap: _save),
            ],
          ),
          SizedBox(height: 5.sdp),
          Expanded(
            child: Container(width: double.infinity, decoration: cardSub(), child: widget.child),
          ),
        ],
      ),
    ),
  );
}

/// ll_btn_save / btn_select: icon (or spinner) then text, focused_save_btn.
class _SaveButton extends StatelessWidget {
  final String text;
  final String icon;
  final bool busy;
  final VoidCallback onTap;
  final double iconPad;
  const _SaveButton({
    required this.text,
    required this.icon,
    required this.busy,
    required this.onTap,
    this.iconPad = 7,
  });
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => SaveBox(
      focused: f,
      padding: EdgeInsets.only(right: 10.sdp),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 35.sdp,
            height: 30.sdp,
            child: busy
                ? Padding(
                    padding: EdgeInsets.all(8.sdp),
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Ic(icon, size: 30.sdp, pad: iconPad.sdp),
          ),
          T(text, size: 12),
        ],
      ),
    ),
  );
}

/// CheckBox row (focused_edt background, white button tint).
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
      decoration: BoxDecoration(color: f ? const Color(0x2DFFFFFF) : null, borderRadius: BorderRadius.circular(2.sdp)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(value ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.white, size: 20.sdp),
          SizedBox(width: 8.sdp),
          Flexible(child: T(text, size: 12, color: C.title)),
        ],
      ),
    ),
  );
}

/// A "label  value  ⌄" row that opens a radio dialog (ll_recently_movie,
/// ll_auto_update).
class _DropRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DropRow(this.label, this.value, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 5.sdp),
    child: Tap(
      onTap: onTap,
      builder: (f) => Container(
        padding: EdgeInsets.all(5.sdp),
        decoration: BoxDecoration(
          color: f ? const Color(0x2DFFFFFF) : null,
          borderRadius: BorderRadius.circular(2.sdp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: T(label, size: 12)),
            SizedBox(width: 10.sdp),
            T(value, size: 12, color: C.titleSub),
            SizedBox(width: 2.sdp),
            Ic('ic_round_arrow_down', size: 20.sdp),
            SizedBox(width: 5.sdp),
          ],
        ),
      ),
    ),
  );
}

/// A list of radio choices with a SAVE button (RadioGroup 30sdp from the
/// left, centred vertically).
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
    onSave: () => widget.onSave(_v),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 30.sdp),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                RadioRow(widget.options[i], i == _v, () => setState(() => _v = i)),
            ],
          ),
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

/// SettingAutomationActivity: which sections the start-up refresh updates,
/// and after how many hours.
class _AutomationPage extends StatefulWidget {
  const _AutomationPage();
  @override
  State<_AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<_AutomationPage> {
  bool _live = Store.updateLive;
  bool _movies = Store.updateMovies;
  bool _series = Store.updateSeries;
  int _hours = Store.autoUpdateHours;

  Future<void> _pickHours() async {
    final r = await radioBtnDialog(
      context,
      title: S.select_reload_hours,
      options: [
        for (final h in const [1, 3, 4, 5, 7, 10]) (h, '$h Hours'),
      ],
      selected: Store.autoUpdateHours,
    );
    if (r == null || !mounted) return;
    toast(context, 'Changed hours ($r)');
    setState(() => _hours = r);
  }

  @override
  Widget build(BuildContext context) => _SettingFrame(
    title: S.automation,
    onSave: () {
      Store.updateLive = _live;
      Store.updateMovies = _movies;
      Store.updateSeries = _series;
      Store.autoUpdateHours = _hours;
    },
    child: SingleChildScrollView(
      padding: EdgeInsets.all(20.sdp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Check(S.auto_update_live, _live, (v) => setState(() => _live = v)),
          _Check(S.auto_update_movies, _movies, (v) => setState(() => _movies = v)),
          _Check(S.auto_update_series, _series, (v) => setState(() => _series = v)),
          _DropRow(S.auto_reload_data, '$_hours Hours', _pickHours),
        ],
      ),
    ),
  );
}

/// SettingMultiScreenActivity: "Show Multi-Screen Popup" and the saved layout.
class _MultiScreenSetting extends StatefulWidget {
  const _MultiScreenSetting();
  @override
  State<_MultiScreenSetting> createState() => _MultiScreenSettingState();
}

class _MultiScreenSettingState extends State<_MultiScreenSetting> {
  bool _popup = Store.multiScreenPopup;
  bool _busy = false;

  Future<void> _select() async {
    final r = await screenDialog(context);
    if (r == null || !mounted) return;
    Store.multiScreenLayout = r;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, 'Changed screen');
  }

  @override
  Widget build(BuildContext context) {
    const names = ['one', 'two', 'three', 'four', 'five'];
    final n = Store.multiScreenLayout.clamp(1, 5);
    return _SettingFrame(
      title: S.multi_screen_settings,
      onSave: () => Store.multiScreenPopup = _popup,
      child: Padding(
        padding: EdgeInsets.all(25.sdp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Check(S.show_multi_screen_popup, _popup, (v) => setState(() => _popup = v)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 5.sdp, top: 2.sdp),
                    child: T(S.choose_multi_screen_layout, size: 12),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _SaveButton(text: S.select, icon: 'ic_add_circle', iconPad: 8, busy: _busy, onTap: _select),
                      SizedBox(width: 10.sdp),
                      Image.asset(
                        'assets/img/screen_${names[n - 1]}.webp',
                        width: 60.sdp,
                        height: 40.sdp,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// SettingGeneralActivity: two columns split by a thin line.
class _GeneralPage extends StatefulWidget {
  const _GeneralPage();
  @override
  State<_GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<_GeneralPage> {
  final _playlist = Store.currentAccount?.type == AccountType.playlist;
  bool _autoplay = Store.autoplayNext;
  bool _reverse = Store.prefs.getBool('cat_reverse') ?? false;
  bool _audio = Store.splashAudio;
  int _movieLimit = Store.movieLimit;
  int _liveLimit = Store.liveLimit;
  final _agent = TextEditingController(text: Store.agentName);

  @override
  void dispose() {
    _agent.dispose();
    super.dispose();
  }

  Future<int?> _pickLimit(int current) async {
    final r = await radioBtnDialog(
      context,
      title: S.select_recently_limit,
      options: [
        for (final n in const [10, 20, 30, 40, 50, 55]) (n, '$n Lists'),
      ],
      selected: current,
    );
    if (r != null && mounted) toast(context, 'Changed limit ($r)');
    return r;
  }

  @override
  Widget build(BuildContext context) => _SettingFrame(
    title: S.general_setting,
    onSave: () {
      Store.agentName = _agent.text.trim();
      if (!_playlist) Store.autoplayNext = _autoplay;
      Store.prefs.setBool('cat_reverse', _reverse);
      Store.splashAudio = _audio;
      Store.liveLimit = _liveLimit;
      Store.movieLimit = _movieLimit;
    },
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 16,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.sdp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_playlist) _Check(S.autoplay_next_episode, _autoplay, (v) => setState(() => _autoplay = v)),
                Padding(
                  padding: EdgeInsets.only(top: _playlist ? 0 : 5.sdp),
                  child: _Check(S.categories_reverse_order, _reverse, (v) => setState(() => _reverse = v)),
                ),
                if (!_playlist) ...[
                  _DropRow(S.recently_added_limit_movie_series, '$_movieLimit', () async {
                    final r = await _pickLimit(_movieLimit);
                    if (r != null) setState(() => _movieLimit = r);
                  }),
                  _DropRow(S.recently_added_limit_live_tv, '$_liveLimit', () async {
                    final r = await _pickLimit(_liveLimit);
                    if (r != null) setState(() => _liveLimit = r);
                  }),
                ],
                Padding(
                  padding: EdgeInsets.fromLTRB(5.sdp, 10.sdp, 3.sdp, 3.sdp),
                  child: T(S.set_playlist_agent, size: 12, color: C.titleSub),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.sdp),
                  child: SizedBox(
                    width: 240.sdp,
                    child: PillField(icon: 'ic_profile', hint: S.app_name, controller: _agent),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 1.sdp,
          margin: EdgeInsets.symmetric(vertical: 1.sdp),
          color: const Color(0x12FFFFFF),
        ),
        Expanded(
          flex: 10,
          child: Padding(
            padding: EdgeInsets.all(20.sdp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_Check(S.splash_screen_music, _audio, (v) => setState(() => _audio = v))],
            ),
          ),
        ),
      ],
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
