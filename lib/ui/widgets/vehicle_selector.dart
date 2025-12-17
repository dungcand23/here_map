import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';

class VehicleSelector extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? current;
  final void Function(VehicleModel) onSelected;
  final void Function(VehicleModel) onAddNew;

  const VehicleSelector({
    super.key,
    required this.vehicles,
    required this.current,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in vehicles)
              ChoiceChip(
                selected: current?.id == v.id,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(v.icon, size: 18),
                    const SizedBox(width: 4),
                    Text(v.name),
                  ],
                ),
                onSelected: (_) => onSelected(v),
              ),
            ActionChip(
              label: const Text('+ Xe mới'),
              onPressed: () async {
                final newVehicle = await _showAddVehicleDialog(context);
                if (newVehicle != null) {
                  onAddNew(newVehicle);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<VehicleModel?> _showAddVehicleDialog(BuildContext context) async {
    final nameController = TextEditingController();
    String mode = 'truck';

    return showDialog<VehicleModel>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Thêm xe mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên xe',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Loại:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(
                        value: 'car',
                        child: Text('Xe con'),
                      ),
                      DropdownMenuItem(
                        value: 'scooter',
                        child: Text('Xe máy'),
                      ),
                      DropdownMenuItem(
                        value: 'truck',
                        child: Text('Xe tải'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        mode = v;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final icon = mode == 'truck'
                    ? Icons.local_shipping
                    : mode == 'scooter'
                    ? Icons.two_wheeler
                    : Icons.directions_car;

                final v = VehicleModel(
                  id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  icon: icon,
                  mode: mode,
                );
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
