// Login with device id (SignInDeviceActivity / activity_sign_in_device.xml).
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../api/panel_api.dart';
import '../models.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'panel_login.dart';
import 'sign_in_page.dart';
import 'users_list_page.dart';

class SignInDevicePage extends StatefulWidget {
  const SignInDevicePage({super.key});
  @override
  State<SignInDevicePage> createState() => _SignInDevicePageState();
}

class _SignInDevicePageState extends State<SignInDevicePage> {
  List<PanelUser>? _users;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final u = await PanelApi.deviceUsers(Store.deviceId);
      if (mounted) setState(() => _users = u);
    } catch (_) {
      if (mounted) setState(() => _users = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = Store.deviceId;
    return LoginLayout(
      formWeight: 1.3,
      side: LoginSide(
        top: Container(
          color: Colors.white,
          padding: EdgeInsets.all(5.sdp),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            QrImageView(data: id, size: 100.sdp, padding: EdgeInsets.zero),
            SizedBox(height: 4.sdp),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.sdp, vertical: 3.sdp),
              color: const Color(0xEDFFFFFF),
              child: T(id, size: 9, color: Colors.black),
            ),
          ]),
        ),
        buttons: [
          UiButton(text: S.list_users, onTap: () => go(context, const UsersListPage(), replace: true)),
        ],
      ),
      form: Container(
        margin: EdgeInsets.only(top: 20.sdp),
        padding: EdgeInsets.all(15.sdp),
        constraints: BoxConstraints(minHeight: 150.sdp),
        decoration: cardSub(),
        child: _users == null
            ? const Loader(size: 50)
            : _users!.isEmpty
                ? Empty(S.err_no_data_found, sub: S.login_with_device_id)
                : Column(children: [
                    for (final u in _users!)
                      Padding(
                        padding: EdgeInsets.only(bottom: 5.sdp),
                        child: Tap(
                          onTap: () => loginPanelUser(context, u),
                          builder: (f) => Container(
                            height: 50.sdp,
                            padding: EdgeInsets.all(5.sdp),
                            decoration: BoxDecoration(
                              color: C.mdBackground,
                              borderRadius: BorderRadius.circular(4.sdp),
                              border: Border.all(
                                  color: f ? const Color(0xFFE62E2F) : const Color(0x1A0C1318),
                                  width: f ? 2.sdp : 1.sdp),
                            ),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3.sdp),
                                child: Image.asset('assets/img/user_photo.webp', width: 40.sdp, fit: BoxFit.cover),
                              ),
                              SizedBox(width: 7.sdp),
                              Expanded(child: T(u.userName, size: 11, color: const Color(0xFF161616), lines: 1)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
      ),
    );
  }
}
