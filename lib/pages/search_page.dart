// Search (SearchActivity / activity_search): search box on top, 5-column grid.
import 'package:material_ui/material_ui.dart';

import '../library.dart';
import '../models.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'list_page.dart';

class SearchPage extends StatefulWidget {
  final ContentType type;

  /// Multiscreen channel picker: a tap returns the item.
  final bool pick;
  const SearchPage({super.key, required this.type, this.pick = false});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _q = TextEditingController();
  List<StreamItem>? _res;

  void _search() {
    final text = _q.text.trim();
    if (text.isEmpty) {
      toast(context, S.err_cannot_empty, error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    final r = Library.I.search(widget.type, text);
    setState(() => _res = r);
    if (r.isEmpty) toast(context, S.err_no_data_found, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.type == ContentType.live;
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            Row(
              children: [
                IconTap('ic_player_back', size: 33, pad: 5, onTap: () => Navigator.maybePop(context)),
                SizedBox(width: 8.sdp),
                Container(
                  width: 200.sdp,
                  height: 32.sdp,
                  decoration: BoxDecoration(
                    color: C.fill,
                    borderRadius: BorderRadius.circular(50.sdp),
                    border: Border.all(color: C.border, width: 1.sdp),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _q,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          style: TextStyle(color: Colors.white, fontSize: 11.ssp),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: S.search,
                            hintStyle: TextStyle(color: Colors.white54, fontSize: 11.ssp),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.sdp),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.sdp,
                        color: C.border,
                        margin: EdgeInsets.symmetric(vertical: 5.sdp),
                      ),
                      IconTap('ic_search', size: 28, pad: 5, onTap: _search),
                    ],
                  ),
                ),
                SizedBox(width: 10.sdp),
                Expanded(child: T(typeTitle(widget.type), size: 11, color: C.titleSub, lines: 1)),
              ],
            ),
            SizedBox(height: 10.sdp),
            Expanded(
              child: _res == null
                  ? const SizedBox()
                  : _res!.isEmpty
                  ? Empty(S.err_no_data_found)
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: live ? 1 : 1 / 1.15,
                      ),
                      itemCount: _res!.length,
                      itemBuilder: (context, i) => PosterCard(
                        item: _res![i],
                        live: live,
                        onTap: () =>
                            widget.pick ? Navigator.pop(context, _res![i]) : openItem(context, _res![i], _res!),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
