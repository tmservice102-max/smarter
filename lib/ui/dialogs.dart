// Dialogs copied from the Android DialogUtil (dialog_app.xml layout).
import 'package:material_ui/material_ui.dart';

import 'kit.dart';
import 'strings.dart';

const dialogBg = Color(0xFF16171D);

/// The standard dialog: icon, title, close button, message, No / Yes.
Future<bool> appDialog(
  BuildContext context, {
  required String icon,
  required String title,
  required String msg,
  String yes = S.yes,
  String? no = S.no,
}) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (_, a, _, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(a),
      child: FadeTransition(opacity: a, child: child),
    ),
    pageBuilder: (ctx, _, _) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280.sdp,
          padding: EdgeInsets.all(5.sdp),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(3.sdp),
            border: Border.all(color: const Color(0xFF26272E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Ic(icon, size: 35.sdp, pad: 5.sdp, color: C.title),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(9.sdp),
                      child: T(title, size: 13, color: C.title, lines: 1, weight: FontWeight.bold),
                    ),
                  ),
                  IconTap('ic_close', size: 35, pad: 5, color: C.title, onTap: () => Navigator.pop(ctx, false)),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.sdp, horizontal: 8.sdp),
                child: T(msg, size: 13, color: C.titleSub, align: TextAlign.center),
              ),
              Padding(
                padding: EdgeInsets.all(5.sdp),
                child: Row(
                  children: [
                    if (no != null) ...[
                      Expanded(
                        child: GradButton(
                          text: no,
                          gradient: G.primaryBtn,
                          textSize: 13,
                          onTap: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      SizedBox(width: 10.sdp),
                    ],
                    Expanded(
                      child: GradButton(text: yes, textSize: 13, onTap: () => Navigator.pop(ctx, true)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return r ?? false;
}

/// Bottom-style panel used for menus and option lists (dialog_radio_btn).
Future<R?> panelDialog<R>(BuildContext context, {required String title, required Widget child, double width = 300}) {
  return showGeneralDialog<R>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    pageBuilder: (ctx, _, _) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width.sdp,
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
          padding: EdgeInsets.all(8.sdp),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(3.sdp),
            border: Border.all(color: const Color(0xFF26272E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(width: 5.sdp),
                  Expanded(child: T(title, size: 13, color: C.title, lines: 1)),
                  IconTap('ic_close', size: 30, pad: 5, color: C.title, onTap: () => Navigator.pop(ctx)),
                ],
              ),
              SizedBox(height: 5.sdp),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

/// List of radio options; returns the chosen index.
Future<int?> choiceDialog(
  BuildContext context, {
  required String title,
  required List<String> options,
  required int selected,
}) {
  return panelDialog<int>(
    context,
    title: title,
    child: ListView(
      shrinkWrap: true,
      children: [
        for (var i = 0; i < options.length; i++)
          Tap(
            onTap: () => Navigator.pop(context, i),
            builder: (f) => Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sdp, vertical: 7.sdp),
              color: f ? const Color(0x2DFFFFFF) : null,
              child: Row(
                children: [
                  Icon(
                    i == selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: i == selected ? C.select : Colors.white70,
                    size: 16.sdp,
                  ),
                  SizedBox(width: 8.sdp),
                  Expanded(child: T(options[i], size: 11)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// Full-screen spinner like Android's ProgressDialog.
class Busy {
  static OverlayEntry? _e;
  static void show(BuildContext context) {
    if (_e != null) return;
    _e = OverlayEntry(
      builder: (_) => const ColoredBox(color: Color(0x66000000), child: Loader(size: 40)),
    );
    Overlay.of(context, rootOverlay: true).insert(_e!);
  }

  static void hide() {
    _e?.remove();
    _e = null;
  }
}
