// Adult categories lock, like the Android app (DialogUtil.childCountDialog and
// ParentalControlDialog). No password set = adult categories open freely.
import 'package:material_ui/material_ui.dart';

import 'store.dart';
import 'ui/dialogs.dart';
import 'ui/kit.dart';
import 'ui/strings.dart';

class Parental {
  static const _words = ['18+', '+18', '[18+]', 'adults', 'adult', 'xxx', 'pron', 'sex'];
  static bool isAdult(String name) {
    final n = name.toLowerCase();
    return _words.any(n.contains);
  }

  /// Returns true when the category can be opened.
  static Future<bool> check(BuildContext context, String categoryName) async {
    if (!isAdult(categoryName) || Store.parentalPin.isEmpty) return true;
    final r = await _form(
      context,
      title: S.warning_adults_only,
      fields: [S.error_password],
      submit: S.unlock,
      validate: (v) {
        if (v[0].trim().isEmpty) return S.err_cannot_empty;
        if (v[0] != Store.parentalPin) return S.err_password;
        return null;
      },
    );
    return r != null;
  }

  /// Settings > Parental control: set or change the password.
  static Future<void> setup(BuildContext context) async {
    final has = Store.parentalPin.isNotEmpty;
    final r = await _form(
      context,
      title: S.parental_control,
      fields: [if (has) S.error_old_password, S.error_password, S.error_cpassword],
      submit: S.submit,
      validate: (v) {
        var i = 0;
        if (has) {
          final old = v[i++];
          if (old.isEmpty) return S.err_cannot_empty;
          if (old.endsWith(' ')) return S.error_pass_end_space;
          if (old != Store.parentalPin) return S.error_old_pass_not_match;
        }
        final p = v[i++], c = v[i];
        if (p.isEmpty || c.isEmpty) return S.err_cannot_empty;
        if (p.endsWith(' ') || c.endsWith(' ')) return S.error_pass_end_space;
        if (p != c) return S.error_pass_not_match;
        return null;
      },
    );
    if (r != null) Store.parentalPin = r.last;
  }

  static Future<List<String>?> _form(
    BuildContext context, {
    required String title,
    required List<String> fields,
    required String submit,
    required String? Function(List<String>) validate,
  }) {
    final ctrls = [for (final _ in fields) TextEditingController()];
    String? error;
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          backgroundColor: dialogBg,
          insetPadding: EdgeInsets.all(25.sdp),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.sdp)),
          child: SizedBox(
            width: 280.sdp,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(5.sdp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Ic('ic_lock', size: 35.sdp, pad: 5.sdp),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(9.sdp),
                          child: T(title, size: 13, color: C.title),
                        ),
                      ),
                      IconTap('ic_close', size: 35, pad: 5, onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  for (var i = 0; i < fields.length; i++)
                    Padding(
                      padding: EdgeInsets.fromLTRB(10.sdp, 5.sdp, 10.sdp, 0),
                      child: TextField(
                        controller: ctrls[i],
                        obscureText: true,
                        autofocus: i == 0,
                        style: TextStyle(color: C.title, fontSize: 12.ssp),
                        decoration: InputDecoration(
                          hintText: fields[i],
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 12.ssp),
                          filled: true,
                          fillColor: const Color(0x12FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2.sdp),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  if (error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 6.sdp),
                      child: T(error!, size: 10, color: Colors.redAccent),
                    ),
                  Padding(
                    padding: EdgeInsets.all(10.sdp),
                    child: Row(
                      children: [
                        Expanded(
                          child: GradButton(text: S.cancel, textSize: 13, onTap: () => Navigator.pop(ctx)),
                        ),
                        SizedBox(width: 6.sdp),
                        Expanded(
                          child: GradButton(
                            text: submit,
                            textSize: 13,
                            gradient: G.primaryBtn,
                            onTap: () {
                              final v = [for (final c in ctrls) c.text];
                              final e = validate(v);
                              if (e != null) {
                                set(() => error = e);
                              } else {
                                Navigator.pop(ctx, v);
                              }
                            },
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
}
