import 'package:flutter/material.dart';
import '../../models/truck_option_model.dart';

class TruckOptionForm extends StatefulWidget {
  final TruckOptionModel truckOption;
  final void Function(TruckOptionModel) onChanged;

  const TruckOptionForm({
    super.key,
    required this.truckOption,
    required this.onChanged,
  });

  @override
  State<TruckOptionForm> createState() => _TruckOptionFormState();
}

class _TruckOptionFormState extends State<TruckOptionForm> {
  late TextEditingController _heightCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _lengthCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _axleCtrl;

  @override
  void initState() {
    super.initState();
    _heightCtrl =
        TextEditingController(text: widget.truckOption.height.toString());
    _widthCtrl =
        TextEditingController(text: widget.truckOption.width.toString());
    _lengthCtrl =
        TextEditingController(text: widget.truckOption.length.toString());
    _weightCtrl =
        TextEditingController(text: widget.truckOption.grossWeight.toString());
    _axleCtrl =
        TextEditingController(text: widget.truckOption.axleCount.toString());
  }

  void _emit() {
    final t = TruckOptionModel(
      height: double.tryParse(_heightCtrl.text) ?? widget.truckOption.height,
      width: double.tryParse(_widthCtrl.text) ?? widget.truckOption.width,
      length: double.tryParse(_lengthCtrl.text) ?? widget.truckOption.length,
      grossWeight:
      double.tryParse(_weightCtrl.text) ?? widget.truckOption.grossWeight,
      axleCount:
      int.tryParse(_axleCtrl.text) ?? widget.truckOption.axleCount,
    );
    widget.onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông số xe tải',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildField('Cao (m)', _heightCtrl),
            _buildField('Rộng (m)', _widthCtrl),
            _buildField('Dài (m)', _lengthCtrl),
            _buildField('Tải (kg)', _weightCtrl),
            _buildField('Số trục', _axleCtrl),
          ],
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: (_) => _emit(),
      ),
    );
  }
}
