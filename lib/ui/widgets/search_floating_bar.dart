import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_notifier.dart';
import '../../services/search_service.dart';
import '../../models/stop_model.dart';
import '../../app_config.dart';

class SearchFloatingBar extends StatefulWidget {
  final void Function(StopModel) onSelectedStop;

  const SearchFloatingBar({
    super.key,
    required this.onSelectedStop,
  });

  @override
  State<SearchFloatingBar> createState() => _SearchFloatingBarState();
}

class _SearchFloatingBarState extends State<SearchFloatingBar> {
  final TextEditingController _controller = TextEditingController();
  List<StopModel> _suggestions = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    // Tạm dùng default center (HCM)
    final results = await SearchService.autosuggest(
      query: query,
      lat: AppConfig.defaultLat,
      lng: AppConfig.defaultLng,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _suggestions = results;
    });
  }

  void _selectSuggestion(StopModel s) {
    widget.onSelectedStop(s);
    _controller.text = s.name;
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Tìm địa điểm...',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      _search(value);
                    },
                    onSubmitted: (value) {
                      _search(value);
                    },
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _suggestions = [];
                      });
                    },
                  ),
              ],
            ),
          ),
          // List suggestion
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black26,
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.place, color: Colors.black54),
                    title: Text(
                      s.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      '${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => _selectSuggestion(s),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
