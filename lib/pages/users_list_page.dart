// Saved users (UsersListActivity / activity_users_list.xml).
import 'package:material_ui/material_ui.dart';
import '../api/xtream_api.dart';
import '../library.dart';
import '../models.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';
import 'select_player_page.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});
  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  Future<void> _open(Account a) async {
    final nav = Navigator.of(context);
    nav.push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => _ProfileLoading(name: a.name),
    ));
    try {
      if (a.type == AccountType.xtream) {
        await XtreamSource.login(a);
        await Store.setCurrent(a);
        Library.reset();
      } else {
        await Store.setCurrent(a);
        Library.reset();
        await Library.I.download(ContentType.live);
        try {
          await Library.I.download(ContentType.movie);
        } catch (_) {}
      }
      if (!mounted) return;
      nav.pop();
      toast(context, 'Login successfully.');
      openHome(context);
    } catch (_) {
      if (!mounted) return;
      nav.pop();
      toast(context, S.err_login_not_incorrect, error: true);
    }
  }

  Future<void> _delete(Account a) async {
    final ok = await appDialog(context, icon: 'ic_trash', title: S.delete, msg: S.sure_delete);
    if (!ok) return;
    await Store.removeAccount(a);
    if (mounted) {
      setState(() {});
      toast(context, S.delete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = Store.accounts;
    final w = MediaQuery.sizeOf(context).width / 6;
    return PageBg(
      child: Column(children: [
        SizedBox(height: 30.sdp),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Logo(size: 25.sdp),
          SizedBox(width: 10.sdp),
          T(S.app_name, size: 13),
        ]),
        SizedBox(height: 10.sdp),
        Expanded(
          child: Center(
            child: list.isEmpty
                ? Empty(S.err_no_data_found)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 10.sdp),
                    child: Row(children: [
                      for (var i = 0; i < list.length; i++) _user(list[i], i, w),
                    ]),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 30.sdp),
          child: Tap(
            onTap: () => go(context, const SelectPlayerPage(), replace: true),
            builder: (f) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 6.sdp),
              decoration: BoxDecoration(
                color: f ? Colors.white : C.save,
                borderRadius: BorderRadius.circular(50.sdp),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Ic('ic_user_add', size: 16.sdp, color: f ? Colors.black : Colors.white),
                SizedBox(width: 6.sdp),
                T(S.add_account, size: 14, color: f ? Colors.black : Colors.white),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _user(Account a, int i, double w) {
    final type = switch (a.kind) {
      'xui' => 'Xtream Codes / Xui',
      'stream' => '1-stream',
      'playlist' => 'M3U Playlist',
      _ => '',
    };
    final g = G.users[i % 7];
    return Tap(
      onTap: () => _open(a),
      onLongPress: () => _delete(a),
      builder: (f) => Padding(
        padding: EdgeInsets.all(5.sdp),
        child: SizedBox(
          width: w,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.all(2.sdp),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: f ? C.mdBackground : Colors.transparent,
              ),
              child: Container(
                width: w - 14.sdp,
                height: w - 14.sdp,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: g),
                ),
                child: T(a.name.isEmpty ? '' : a.name[0].toUpperCase(), size: 45),
              ),
            ),
            SizedBox(height: 3.sdp),
            T(a.name, size: 12, color: C.title, lines: 1, align: TextAlign.center),
            SizedBox(height: 1.sdp),
            T(type, size: 8, color: C.titleSub, lines: 1, align: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

/// LoginDialog: "Welcome NAME / Getting your profile ready…".
class _ProfileLoading extends StatelessWidget {
  final String name;
  const _ProfileLoading({required this.name});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: PageBg(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.primarySub, Colors.transparent]),
          ),
          child: Column(children: [
            SizedBox(height: 15.sdp),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Logo(size: 22.sdp),
              SizedBox(width: 10.sdp),
              T(S.app_name, size: 13),
            ]),
            Expanded(
              child: Row(children: [
                SizedBox(width: 30.sdp),
                SizedBox(
                  width: 80.sdp,
                  height: 80.sdp,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                        margin: EdgeInsets.all(7.sdp),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: C.primary)),
                    Ic('ic_profile', size: 40.sdp, color: Colors.black),
                    SizedBox.expand(child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                  ]),
                ),
                SizedBox(width: 15.sdp),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    T('${S.welcome} $name', size: 17, color: C.title, lines: 1),
                    SizedBox(height: 5.sdp),
                    T(S.getting_your_profile_ready, size: 14, color: C.titleSub),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
