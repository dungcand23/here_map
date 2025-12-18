import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/stop_model.dart';
import '../../services/location_service.dart';
import '../../services/search_service.dart';

class SearchStopField extends StatefulWidget {
  final String hintText;
  final String initialText;
  final void Function(StopModel) onSelected;

  const SearchStopField({
    super.key,
    required this.hintText,
    required this.initialText,
    required this.onSelected,
  });

  @override
  State<SearchStopField> createState() => _SearchStopFieldState();
}

class _SearchStopFieldState extends State<SearchStopField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  Timer? _debounce;
  List<StopModel> _items = [];
  bool _loading = false;
  bool _locating = false;
  bool _committing = false;

  double _toDouble(dynamic v) => v is num ? v.toDouble() : 0.0;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialText);
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant SearchStopField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText && _c.text != widget.initialText) {
      _c.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<List<StopModel>> _fetch(String query) async {
    final loc = await LocationService.getMyLocation();
    final lat = _toDouble(loc['lat']);
    final lng = _toDouble(loc['lng']);

    return SearchService.autosuggest(
      query: query,
      lat: lat,
      lng: lng,
    );
  }

  Future<void> _query(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() => _items = []);
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    final results = await _fetch(query);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = results;
    });
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _query(v));
  }

  /// ✅ Gõ xong nhấn Enter/Done => tự pick kết quả đầu tiên (đảm bảo có lat/lng để ghim marker)
  Future<void> _commit() async {
    if (_committing) return;
    _committing = true;
    try {
      final query = _c.text.trim();
      if (query.isEmpty) return;

      // Nếu list gợi ý đang có sẵn => pick luôn item đầu
      if (_items.isNotEmpty) {
        _pick(_items.first);
        return;
      }

      if (!mounted) return;
      setState(() => _loading = true);

      final results = await _fetch(query);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = results;
      });

      if (results.isNotEmpty) {
        _pick(results.first);
      }
    } finally {
      _committing = false;
    }
  }

  void _pick(StopModel s) {
    _c.text = s.name;
    setState(() => _items = []);
    widget.onSelected(s);
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    final loc = await LocationService.getMyLocation();
    final lat = _toDouble(loc['lat']);
    final lng = _toDouble(loc['lng']);

    if (!mounted) return;
    setState(() => _locating = false);

    if (lat == 0 && lng == 0) return;

    final stop = StopModel(
      name: 'Vị trí hiện tại',
      lat: lat,
      lng: lng,
    );

    _pick(stop);
  }

  @override
  Widget build(BuildContext context) {
    final showMyLocationButton = _focus.hasFocus;

    return Column(
      children: [
        TextField(
          controller: _c,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: showMyLocationButton
                ? IconButton(
              tooltip: 'Vị trí hiện tại',
              onPressed: _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.my_location),
            )
                : null,
            suffixIcon: _loading
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : (_c.text.isEmpty
                ? null
                : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // ✅ clear text + clear luôn Stop trong state (để map/marker sync đúng)
                _c.clear();
                setState(() => _items = []);
                widget.onSelected(const StopModel(lat: 0, lng: 0, name: ''));
              },
            )),
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _commit(),
          onEditingComplete: () => _commit(),
        ),
        if (_items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x12000000))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final it = _items[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _pick(it),
                );
              },
            ),
          ),
      ],
    );
  }
}
