// Subscription info (ProfileActivity / activity_profile): person on the left,
// a purple "card" with status, connections, name and expiry on the right.
import 'package:material_ui/material_ui.dart';
import '../config.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    refreshAccountInfo().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final a = Store.currentAccount;
    final info = (Store.prefs.getString('info|${a?.id}') ?? '').split('|');
    final status = info.isNotEmpty && info[0].isNotEmpty ? info[0] : 'None';
    final max = info.length > 1 ? info[1] : '0';
    final active = info.length > 2 ? info[2] : '0';
    final exp = savedExpiry();
    final isActive = status.toLowerCase() == 'active';
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(children: [
          PageTop(title: S.subscription_info, icon: 'ic_profile'),
          SizedBox(height: 5.sdp),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15.sdp),
              decoration: cardSub(),
              child: Row(children: [
                Expanded(
                  flex: 10,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Ic('ic_person_flat', size: 100.sdp, color: null),
                    SizedBox(height: 6.sdp),
                    T(a?.name ?? '', size: 15, lines: 1),
                  ]),
                ),
                Expanded(
                  flex: 13,
                  child: Padding(
                    padding: EdgeInsets.all(15.sdp),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.7,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: G.primaryBtn,
                            borderRadius: BorderRadius.circular(5.sdp),
                            border: Border.all(color: C.title, width: 1.sdp),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5.sdp),
                            child: Stack(fit: StackFit.expand, children: [
                              Image.asset('assets/img/card_bg.webp', fit: BoxFit.cover),
                              Padding(
                                padding: EdgeInsets.all(10.sdp),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4.sdp, vertical: 1.sdp),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2.sdp),
                                        border: Border.all(
                                            color: isActive ? const Color(0xFF05B60D) : const Color(0xFFFF9800),
                                            width: 1.sdp),
                                      ),
                                      child: T(isActive ? 'Active' : status,
                                          size: 7, color: isActive ? const Color(0xFF05B60D) : const Color(0xFFFF9800)),
                                    ),
                                    SizedBox(width: 8.sdp),
                                    Expanded(child: T(AppConfig.appName, size: 18, lines: 1)),
                                  ]),
                                  const Spacer(),
                                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Expanded(
                                      child: T(Uri.tryParse(a?.server ?? '')?.host ?? '', size: 11, lines: 1),
                                    ),
                                    Image.asset('assets/img/sim_card.webp', width: 45.sdp, height: 45.sdp),
                                  ]),
                                  const Spacer(),
                                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        T(S.card_connections, size: 9),
                                        T('$active / $max', size: 9),
                                        SizedBox(height: 4.sdp),
                                        T(S.card_holder_name, size: 10),
                                        T(a?.username ?? '', size: 11, lines: 1),
                                      ]),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      T(S.expiry_date, size: 10),
                                      T(exp == null ? 'Unlimited' : longDate(exp), size: 11),
                                    ]),
                                  ]),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
