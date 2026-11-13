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

/// DialogUtil.radioBtnDialog (dialog_radio_btn.xml): numbered-list icon, bold
/// title, close; radio choices in 2 columns; Cancel / Submit. Returns the
/// chosen value, or null when cancelled.
Future<int?> radioBtnDialog(
  BuildContext context, {
  required String title,
  required List<(int, String)> options,
  required int selected,
}) {
  var current = selected;
  return showGeneralDialog<int>(
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
        child: StatefulBuilder(
          builder: (ctx, set) => Container(
            width: 280.sdp,
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.95),
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
                    Ic('ic_list_numbered', size: 35.sdp, pad: 5.sdp, color: Colors.white),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(9.sdp),
                        child: T(title, size: 13, color: C.title, lines: 1, weight: FontWeight.bold),
                      ),
                    ),
                    IconTap('ic_close', size: 35, pad: 5, onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 10.sdp),
                    child: Column(
                      children: [
                        for (var i = 0; i < options.length; i += 2)
                          Row(
                            children: [
                              for (var k = i; k < i + 2; k++)
                                Expanded(
                                  child: k >= options.length
                                      ? const SizedBox()
                                      : RadioRow(
                                          options[k].$2,
                                          options[k].$1 == current,
                                          () => set(() => current = options[k].$1),
                                          size: 13,
                                          padding: EdgeInsets.only(left: 10.sdp, right: 5.sdp),
                                        ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(5.sdp),
                  child: Row(
                    children: [
                      Expanded(
                        child: GradButton(text: S.cancel, textSize: 13, onTap: () => Navigator.pop(ctx)),
                      ),
                      SizedBox(width: 10.sdp),
                      Expanded(
                        child: GradButton(
                          text: S.submit,
                          gradient: G.primaryBtn,
                          textSize: 13,
                          onTap: () => Navigator.pop(ctx, current),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A RadioButton row (focused_edt background, buttonTint nsTitle).
class RadioRow extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final EdgeInsets? padding;
  const RadioRow(this.text, this.selected, this.onTap, {super.key, this.size = 13, this.padding});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      padding: padding ?? EdgeInsets.all(10.sdp),
      decoration: BoxDecoration(color: f ? const Color(0x2DFFFFFF) : null, borderRadius: BorderRadius.circular(2.sdp)),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.sdp),
            child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: C.title, size: 20.sdp),
          ),
          SizedBox(width: 8.sdp),
          Flexible(
            child: T(text, size: size, color: C.title),
          ),
        ],
      ),
    ),
  );
}

/// DialogUtil.screenDialog (dialog_screen.xml): the five multi-screen layouts,
/// 3 on the first row and 2 on the second. Returns 1..5, or null.
Future<int?> screenDialog(BuildContext context) {
  const names = ['one', 'two', 'three', 'four', 'five'];
  Widget pic(BuildContext ctx, int n) => Expanded(
    child: n == 0
        ? SizedBox(height: 80.sdp)
        : Tap(
            onTap: () => Navigator.pop(ctx, n),
            builder: (f) => Container(
              height: 80.sdp,
              padding: EdgeInsets.all(5.sdp),
              decoration: BoxDecoration(
                color: f ? const Color(0x2DFFFFFF) : null,
                border: f ? Border.all(color: Colors.white, width: 1.sdp) : null,
              ),
              child: Image.asset('assets/img/screen_${names[n - 1]}.webp', fit: BoxFit.contain),
            ),
          ),
  );
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    pageBuilder: (ctx, _, _) => PopScope(
      canPop: true,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(25.sdp),
          child: Center(
            child: Material(
              color: const Color(0xCB1B1B1B),
              child: Padding(
                padding: EdgeInsets.all(15.sdp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.sdp),
                      child: T(S.choose_multi_screen_layout, size: 12),
                    ),
                    Row(children: [pic(ctx, 1), pic(ctx, 2), pic(ctx, 3)]),
                    SizedBox(height: 10.sdp),
                    Row(children: [pic(ctx, 4), pic(ctx, 5), pic(ctx, 0)]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
