// Shared look of the Android app: colors, sizes (sdp/ssp), backgrounds,
// icons and the small widgets every screen uses.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// The Android app uses the "sdp/ssp" size library, where 1 unit grows with
/// the shortest side of the screen (1 unit = 1 point at 300 points).
class Dim {
  static double k = 1.3;
  static void init(BuildContext context) {
    final s = MediaQuery.sizeOf(context).shortestSide;
    if (s > 0) k = (s / 300).clamp(1.0, 2.6);
  }
}

extension Sdp on num {
  double get sdp => this * Dim.k;
  double get ssp => this * Dim.k;
}

/// Colors copied from res/values/colors.xml and the theme drawables.
class C {
  // Default "Classic" theme of the Android app (ns_classic_primary).
  static const primary = Color(0xFFE62E2F);
  static const primarySub = Color(0x26E62E2F);
  static const title = Color(0xFFDBDBDB);
  static const titleSub = Color(0xE9A0A0A0);
  static const white = Colors.white;
  static const black = Colors.black;
  static const select = Color(0xFFFF9F00); // color_select
  static const load = Color(0xFF212121); // bg_color_load
  static const bgTop = Color(0xFF070923); // bg_dark
  static const bgBottom = Color(0xFF020309);
  static const mdBackground = Color(0xFFFDFDFE);
  static const border = Color(0x23FFFFFF);
  static const fill = Color(0x12FFFFFF);
  static const save = Color(0x17FFFFFF);
}

class G {
  static const danger = LinearGradient(colors: [Color(0xFFFF4B2B), Color(0xFFFF416C)]);
  static const primaryBtn = LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]);
  static const success = LinearGradient(colors: [Color(0xFF38EF7D), Color(0xFF11998E)]);
  static const tv = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFF3C56DE), Color(0xFF36D29B)],
  );
  static const movies = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFFF69D3F), Color(0xFFDB2E54)],
  );
  static const series = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFF5396DC), Color(0xFF9C3CB3)],
  );
  static const users = [
    [Color(0xFFFF4B2B), Color(0xFFFF416C)],
    [Color(0xFFBC4E9C), Color(0xFFF80759)],
    [Color(0xFF7F00FF), Color(0xFFE100FF)],
    [Color(0xFF00C6FF), Color(0xFF0072FF)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFC5E1A), Color(0xFFF7C333)],
    [Color(0xFFEB3838), Color(0xFFFF8222)],
  ];
}

/// bg_dark: the dark navy gradient behind every page.
class PageBg extends StatelessWidget {
  final Widget child;
  final bool safe;

  /// Extra side margin in sdp. Android screens use padding 5sdp plus
  /// paddingStart/End 25sdp; pages add the 5sdp themselves, so 20 here.
  /// Notches / system bars count towards it (whichever is bigger).
  final double side;
  const PageBg({super.key, required this.child, this.safe = true, this.side = 20});

  @override
  Widget build(BuildContext context) {
    Dim.init(context);
    Widget body = child;
    if (safe) {
      final p = MediaQuery.paddingOf(context);
      final s = side.sdp;
      body = MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(p.left > s ? p.left : s, p.top, p.right > s ? p.right : s, p.bottom),
          child: child,
        ),
      );
    }
    return Scaffold(
      backgroundColor: C.bgBottom,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [C.bgBottom, C.bgTop],
          ),
        ),
        child: SizedBox.expand(child: body),
      ),
    );
  }
}

/// A vector icon converted from the Android drawables (assets/icons/NAME.svg).
class Ic extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final double pad;
  const Ic(this.name, {super.key, this.size = 24, this.color = Colors.white, this.pad = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(pad),
      child: SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size - pad * 2,
        height: size - pad * 2,
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      ),
    );
  }
}

/// The square app logo with rounded corners.
class Logo extends StatelessWidget {
  final double size;
  final double radius;
  const Logo({super.key, required this.size, this.radius = 3});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius.sdp),
    child: Image.asset('assets/img/logo.jpg', width: size, height: size, fit: BoxFit.cover),
  );
}

/// Text with the Android defaults (white).
class T extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final FontWeight? weight;
  final int? lines;
  final TextAlign? align;
  const T(this.text, {super.key, this.size = 11, this.color = Colors.white, this.weight, this.lines, this.align});
  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: lines,
    overflow: lines == null ? null : TextOverflow.ellipsis,
    textAlign: align,
    style: TextStyle(color: color, fontSize: size.ssp, fontWeight: weight, height: 1.2),
  );
}

/// A tappable area that shows the Android "focused" look while pressed.
class Tap extends StatefulWidget {
  final Widget Function(bool focused) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  const Tap({super.key, required this.builder, this.onTap, this.onLongPress, this.autofocus = false});
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;
  bool _focus = false;
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: widget.builder(_down || _focus),
      ),
    );
  }
}

/// Rounded "pill" input like bg_edit_text with an icon and a divider.
class PillField extends StatefulWidget {
  final String icon;
  final String hint;
  final TextEditingController controller;
  final bool password;
  final TextInputType? keyboard;
  final double height;
  final ValueChanged<String>? onSubmitted;
  const PillField({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    this.password = false,
    this.keyboard,
    this.height = 30,
    this.onSubmitted,
  });
  @override
  State<PillField> createState() => _PillFieldState();
}

class _PillFieldState extends State<PillField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height.sdp,
      decoration: BoxDecoration(
        color: C.fill,
        borderRadius: BorderRadius.circular(50.sdp),
        border: Border.all(color: C.border, width: 1.sdp),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30.sdp,
            child: Ic(widget.icon, size: 30.sdp, pad: 8.sdp),
          ),
          Container(
            width: 1.sdp,
            color: C.border,
            margin: EdgeInsets.symmetric(vertical: 5.sdp),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: widget.password && _hidden,
              keyboardType: widget.keyboard,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(color: Colors.white, fontSize: 10.ssp),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.white54, fontSize: 10.ssp),
                contentPadding: EdgeInsets.symmetric(horizontal: 8.sdp),
              ),
            ),
          ),
          if (widget.password) ...[
            Container(width: 1.sdp, color: C.border),
            GestureDetector(
              onTap: () => setState(() => _hidden = !_hidden),
              child: SizedBox(
                width: 28.sdp,
                child: Ic(_hidden ? 'ic_login_visibility_off' : 'ic_login_visibility', size: 24.sdp, pad: 5.sdp),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Big gradient button (focused_btn_danger / focused_btn_primary).
class GradButton extends StatelessWidget {
  final String text;
  final String? icon;
  final bool loading;
  final VoidCallback? onTap;
  final Gradient gradient;
  final double textSize;
  const GradButton({
    super.key,
    required this.text,
    this.icon,
    this.loading = false,
    this.onTap,
    this.gradient = G.danger,
    this.textSize = 14,
  });
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: loading ? null : onTap,
      builder: (f) => Container(
        height: 30.sdp,
        decoration: BoxDecoration(
          gradient: f ? null : gradient,
          color: f ? const Color(0xFFFFB347) : null,
          borderRadius: BorderRadius.circular(3.sdp),
          border: f ? Border.all(color: Colors.white, width: 1.sdp) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 30.sdp,
                height: 30.sdp,
                child: Padding(
                  padding: EdgeInsets.all(7.sdp),
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            else if (icon != null)
              Ic(icon!, size: 30.sdp, pad: 7.sdp),
            T(text, size: textSize),
          ],
        ),
      ),
    );
  }
}

/// White chip button with dark text (focused_btn_ui_selector).
class UiButton extends StatelessWidget {
  final String text;
  final String? icon;
  final VoidCallback? onTap;
  const UiButton({super.key, required this.text, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        padding: EdgeInsets.symmetric(horizontal: icon == null ? 8.sdp : 5.sdp, vertical: 5.sdp),
        decoration: BoxDecoration(
          color: f ? const Color(0xFFFFB347) : const Color(0xEDFFFFFF),
          borderRadius: BorderRadius.circular(2.sdp),
          border: Border.all(color: Colors.white, width: 1.sdp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IconView: 21sdp icon, 4sdp gap.
            if (icon != null) ...[Ic(icon!, size: 21.sdp, color: Colors.black), SizedBox(width: 4.sdp)],
            T(text, size: 10, color: Colors.black, weight: FontWeight.bold),
          ],
        ),
      ),
    );
  }
}

/// bg_save_btn: thin translucent box, purple gradient when pressed.
class SaveBox extends StatelessWidget {
  final Widget child;
  final bool focused;
  final EdgeInsets? padding;
  final double radius;
  const SaveBox({super.key, required this.child, this.focused = false, this.padding, this.radius = 2});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: focused ? null : C.save,
      gradient: focused ? G.primaryBtn : null,
      borderRadius: BorderRadius.circular(radius.sdp),
      border: Border.all(color: focused ? C.title : C.border, width: 1.sdp),
    ),
    child: child,
  );
}

/// bg_card_sub: the bordered panel used for forms.
BoxDecoration cardSub() => BoxDecoration(
  color: const Color(0x05000000),
  borderRadius: BorderRadius.circular(3.sdp),
  border: Border.all(color: const Color(0x12FFFFFF), width: 1.sdp),
);

/// Round icon button used in toolbars (focused_icon_selector).
class IconTap extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double pad;
  final Color color;
  const IconTap(this.icon, {super.key, this.onTap, this.size = 35, this.pad = 8, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: f ? const Color(0x2DFFFFFF) : Colors.transparent),
      child: Ic(icon, size: size.sdp, pad: pad.sdp, color: color),
    ),
  );
}

/// Network image with the Android placeholders.
class NetImg extends StatelessWidget {
  final String url;
  final String placeholder; // placeholder_live / placeholder_vertical / placeholder_horizontal
  final BoxFit fit;
  final double? width;
  final double? height;
  const NetImg(
    this.url, {
    super.key,
    this.placeholder = 'placeholder_vertical',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });
  @override
  Widget build(BuildContext context) {
    final ph = Image.asset('assets/img/$placeholder.webp', fit: BoxFit.cover, width: width, height: height);
    if (url.isEmpty || !url.startsWith('http')) return ph;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, _) => ph,
      errorWidget: (_, _, _) => ph,
      fadeInDuration: Duration.zero,
    );
  }
}

/// The spinning loader used everywhere.
class Loader extends StatelessWidget {
  final double size;
  const Loader({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: size.sdp,
      height: size.sdp,
      child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
    ),
  );
}

/// Empty state (row_empty).
class Empty extends StatelessWidget {
  final String title;
  final String sub;
  const Empty(this.title, {super.key, this.sub = ''});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(15.sdp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Ic('ic_search_off', size: 50.sdp, color: C.title),
          T(title, size: 10, color: C.title, align: TextAlign.center),
          if (sub.isNotEmpty) ...[
            SizedBox(height: 3.sdp),
            SizedBox(
              width: 150.sdp,
              child: T(sub, size: 9, color: const Color(0xB0DBDBDB), align: TextAlign.center),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Top bar of list pages: back, page icon, title, then trailing buttons.
class PageTop extends StatelessWidget {
  final String title;
  final String icon;
  final List<Widget> trailing;
  final VoidCallback? onBack;
  const PageTop({super.key, required this.title, required this.icon, this.trailing = const [], this.onBack});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTap('ic_arrow_left', size: 33, pad: 5, onTap: onBack ?? () => Navigator.maybePop(context)),
        Ic(icon, size: 30.sdp, pad: 5.sdp, color: C.title),
        SizedBox(width: 6.sdp),
        Expanded(child: T(title, size: 11, lines: 1)),
        if (trailing.isNotEmpty)
          SaveBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < trailing.length; i++) ...[
                  if (i > 0) Container(width: 1.sdp, height: 30.sdp, color: C.border),
                  trailing[i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// A button inside the PageTop trailing box.
class TopBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final Color color;
  const TopBtn(this.icon, {super.key, this.onTap, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      width: 35.sdp,
      height: 30.sdp,
      decoration: BoxDecoration(gradient: f ? G.primaryBtn : null),
      child: Ic(icon, size: 30.sdp, pad: 5.sdp, color: color),
    ),
  );
}

/// Simple toast like Android's Toasty.
void toast(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? const Color(0xFFD32F2F) : const Color(0xFF323232),
      behavior: SnackBarBehavior.floating,
      width: 320,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Push a page with a fade, like the Android activity switch.
Future<R?> go<R>(BuildContext context, Widget page, {bool replace = false, bool clear = false}) {
  final route = PageRouteBuilder<R>(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 180),
  );
  final nav = Navigator.of(context);
  if (clear) return nav.pushAndRemoveUntil(route, (_) => false);
  if (replace) return nav.pushReplacement(route);
  return nav.push(route);
}

/// The doodle pattern drawn over the home tiles (drawable/pattern, tint #41000000).
class TilePattern extends StatelessWidget {
  final Color color;
  const TilePattern({super.key, this.color = const Color(0x41000000)});
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/pattern.svg',
    fit: BoxFit.cover,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
