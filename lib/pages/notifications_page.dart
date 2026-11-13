// Notifications from the panel (NotificationsActivity / row_notification).
import 'package:material_ui/material_ui.dart';

import '../session.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static String _plain(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();

  @override
  Widget build(BuildContext context) {
    final list = Session.app?.notifications ?? const [];
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            Row(
              children: [
                IconTap('ic_player_back', size: 33, pad: 5, onTap: () => Navigator.maybePop(context)),
                Ic('ic_round_notifications', size: 30.sdp, pad: 5.sdp, color: C.title),
                SizedBox(width: 6.sdp),
                T(S.notifications, size: 11),
              ],
            ),
            SizedBox(height: 5.sdp),
            Expanded(
              child: list.isEmpty
                  ? Empty(S.err_no_data_found)
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final n = list[i];
                        final title = '${n['notification_title'] ?? ''}';
                        final msg = '${n['notification_msg'] ?? ''}';
                        final desc = _plain('${n['notification_description'] ?? ''}');
                        return Padding(
                          padding: EdgeInsets.only(left: 5.sdp, bottom: 5.sdp),
                          child: Tap(
                            onTap: () => appDialog(
                              context,
                              icon: 'ic_round_notifications',
                              title: title,
                              msg: desc.isEmpty ? msg : desc,
                              no: null,
                              yes: 'OK',
                            ),
                            builder: (f) => SaveBox(
                              focused: f,
                              padding: EdgeInsets.all(10.sdp),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        T(title, size: 13),
                                        SizedBox(height: 2.sdp),
                                        T(msg, size: 10, color: const Color(0xFFEDEDED)),
                                      ],
                                    ),
                                  ),
                                  Expanded(child: T('${n['notification_on'] ?? ''}', size: 10, align: TextAlign.end)),
                                ],
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
