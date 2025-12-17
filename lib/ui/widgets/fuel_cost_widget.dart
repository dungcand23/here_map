import 'package:flutter/material.dart';
import '../../models/fuel_model.dart';

class FuelCostWidget extends StatefulWidget {
  final FuelModel fuel;
  final void Function(FuelModel) onChanged;

  const FuelCostWidget({
    super.key,
    required this.fuel,
    required this.onChanged,
  });

  @override
  State<FuelCostWidget> createState() => _FuelCostWidgetState();
}

class _FuelCostWidgetState extends State<FuelCostWidget> {
  late TextEditingController _consCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _consCtrl = TextEditingController(
        text: widget.fuel.consumptionPer100km.toString());
    _priceCtrl =
        TextEditingController(text: widget.fuel.pricePerLiter.toString());
  }

  void _emit() {
    final f = FuelModel(
      consumptionPer100km:
      double.tryParse(_consCtrl.text) ?? widget.fuel.consumptionPer100km,
      pricePerLiter:
      double.tryParse(_priceCtrl.text) ?? widget.fuel.pricePerLiter,
    );
    widget.onChanged(f);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiêu hao nhiên liệu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _consCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'L/100km',
                ),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá (đ/lít)',
                ),
                onChanged: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
