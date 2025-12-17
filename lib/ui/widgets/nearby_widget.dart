import 'package:flutter/material.dart';
import '../../services/nearby_service.dart';
import '../../models/stop_model.dart';
import '../../app_config.dart';

class NearbyWidget extends StatefulWidget {
  final void Function(StopModel) onSelectedStop;

  const NearbyWidget({
    super.key,
    required this.onSelectedStop,
  });

  @override
  State<NearbyWidget> createState() => _NearbyWidgetState();
}

class _NearbyWidgetState extends State<NearbyWidget> {
  bool _loading = false;

  Future<void> _search(String type) async {
    setState(() {
      _loading = true;
    });

    // Tạm dùng toạ độ default, sau có thể dùng GPS
    final results = await NearbyService.searchNearby(
      lat: AppConfig.defaultLat,
      lng: AppConfig.defaultLng,
      type: type,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
    });

    if (results.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final s = results[index];
            return ListTile(
              leading: const Icon(Icons.place),
              title: Text(s.name),
              subtitle: Text(
                '${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}',
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onSelectedStop(s);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tìm quanh đây',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _search('atm'),
              icon: const Icon(Icons.account_balance),
              label: const Text('ATM'),
            ),
            ElevatedButton.icon(
              onPressed: () => _search('gas'),
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Xăng'),
            ),
            ElevatedButton.icon(
              onPressed: () => _search('food'),
              icon: const Icon(Icons.restaurant),
              label: const Text('Ăn uống'),
            ),
          ],
        ),
      ],
    );
  }
}
