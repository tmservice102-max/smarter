// Hide categories (FilterCategoriesActivity): checked = hidden from the list.
import 'package:material_ui/material_ui.dart';
import '../library.dart';
import '../models.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';

class FilterCategoriesPage extends StatefulWidget {
  final ContentType type;
  const FilterCategoriesPage({super.key, required this.type});
  @override
  State<FilterCategoriesPage> createState() => _FilterCategoriesPageState();
}

class _FilterCategoriesPageState extends State<FilterCategoriesPage> {
  late final Set<String> _hidden = Store.hiddenCategories.toSet();

  String _id(Category c) => '${widget.type.name}:${c.id}';

  Future<void> _toggle(Category c) async {
    final id = _id(c);
    final add = !_hidden.contains(id);
    setState(() => add ? _hidden.add(id) : _hidden.remove(id));
    await Store.setHiddenCategories(_hidden.toList());
    if (mounted) toast(context, add ? S.list_success : S.list_remove_success);
  }

  @override
  Widget build(BuildContext context) {
    final cats = Library.I.categories(widget.type);
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(children: [
          PageTop(title: S.categories, icon: 'list_channels'),
          SizedBox(height: 5.sdp),
          Expanded(
            child: cats.isEmpty
                ? Empty(S.err_no_data_found)
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisExtent: 46.sdp,
                    ),
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      final on = _hidden.contains(_id(c));
                      return Tap(
                        onTap: () => _toggle(c),
                        builder: (f) => Container(
                          margin: EdgeInsets.all(2.sdp),
                          decoration: BoxDecoration(
                            color: const Color(0x12FFFFFF),
                            borderRadius: BorderRadius.circular(1.sdp),
                            border: Border.all(color: f ? const Color(0xFFFFAB00) : C.border, width: 1.sdp),
                          ),
                          child: Row(children: [
                            Ic(on ? 'ic_checkbox' : 'ic_checkbox_blank', size: 40.sdp, pad: 10.sdp),
                            Expanded(child: T(c.name, size: 12, color: C.title, lines: 2)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
