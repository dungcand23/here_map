import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/stop_model.dart';
import '../../services/location_service.dart';
import '../../services/analytics_service.dart';
import '../../services/api_exceptions.dart';
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

  String _lastQuery = '';

  double _toDouble(dynamic v) => v is num ? v.toDouble() : 0.0;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialText);
    _focus = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SearchStopField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        _c.text != widget.initialText) {
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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<List<StopModel>> _fetch(String query) async {
    final loc = await LocationService.getMyLocation();
    final lat = _toDouble(loc['lat']);
    final lng = _toDouble(loc['lng']);

    try {
      return await SearchService.autosuggest(
        query: query,
        lat: lat,
        lng: lng,
      );
    } on ApiException catch (e) {
      _toast(e.message);
      return [];
    } catch (_) {
      _toast('Không thể tìm kiếm lúc này');
      return [];
    }
  }

  Future<void> _query(String q) async {
    final query = q.trim();
    _lastQuery = query;

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

  Future<void> _commit() async {
    if (_committing) return;
    _committing = true;
    try {
      final query = _c.text.trim();
      if (query.isEmpty) return;

      if (!mounted) return;
      setState(() => _loading = true);

      final results = await SearchService.geocode(query: query, limit: 5);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = results;
      });

      if (results.isNotEmpty) {
        _pick(results.first, source: 'geocode_commit', rank: 1);
      } else {
        _toast('Không tìm thấy địa điểm. Hãy thử nhập chi tiết hơn.');
      }
    } finally {
      _committing = false;
    }
  }

  void _pick(StopModel s, {required String source, int? rank}) {
    _c.text = s.name;

    // best-effort analytics (không để crash luồng chọn)
    try {
      AnalyticsService.track('autosuggest_item_selected', {
        'source': source,
        'rank': rank,
        'q_len': _lastQuery.length,
        'has_location': (s.lat != 0 || s.lng != 0),
      });
    } catch (_) {}

    if (kDebugMode) {
      debugPrint('[Flutter] Pick stop: "${s.name}" (${s.lat}, ${s.lng})');
    }

    // ✅ Quan trọng: clear list trước, rồi call onSelected
    // để UI không rebuild “mất click”.
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
      subtitle: '',
    );

    _pick(stop, source: 'current_location');
  }

  void _clearField() {
    _c.clear();
    setState(() => _items = []);
    widget.onSelected(const StopModel(lat: 0, lng: 0, name: '', subtitle: ''));
  }

  @override
  Widget build(BuildContext context) {
    final showMyLocationButton = _focus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _c,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  : const Icon(Icons.my_location, size: 18),
            )
                : const Icon(Icons.search, size: 18),
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
              tooltip: 'Xoá',
              onPressed: _clearField,
            )),
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _commit(),
        ),

        // ✅ FIX: không phụ thuộc focus nữa -> click item không bị mất
        if (_items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Color(0x12000000))
              ],
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
                  leading: const Icon(Icons.place_outlined, size: 18),
                  title: Text(
                    it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: it.subtitle.trim().isEmpty
                      ? null
                      : Text(
                    it.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _pick(it, source: 'autosuggest', rank: i + 1),
                );
              },
            ),
          ),
      ],
    );
  }
}
