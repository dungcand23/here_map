import 'package:flutter/material.dart';
import '../../models/stop_model.dart';
import 'search_stop_field.dart';

class StopListWidget extends StatelessWidget {
  final List<StopModel> stops;
  final void Function(int index, StopModel stop) onUpdateStop;
  final void Function(int index) onClearStop;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  const StopListWidget({
    super.key,
    required this.stops,
    required this.onUpdateStop,
    required this.onClearStop,
    required this.onRemove,
    required this.onReorder,
  });

  String _badge(int i) => i == 0 ? 'A' : (i == 1 ? 'B' : '+');
  String _hint(int i) => i == 0 ? 'Nhập địa điểm...' : (i == 1 ? 'Nhập địa điểm...' : 'Thêm điểm dừng');

  bool _isEmpty(StopModel s) => s.name.trim().isEmpty || (s.lat == 0 && s.lng == 0);

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      buildDefaultDragHandles: false, // ✅ tránh bị hiện 2 dấu “≡”
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        onReorder(oldIndex, newIndex);
      },
      itemBuilder: (context, i) {
        final s = stops[i];
        final canRemove = i >= 2;
        final canDrag = i >= 2; // A/B không kéo

        return Container(
          key: ValueKey('stop_${i}_${s.name}_${s.lat}_${s.lng}'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x12000000))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_badge(i), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SearchStopField(
                  hintText: _hint(i),
                  initialText: s.name,
                  onSelected: (picked) => onUpdateStop(i, picked),
                ),
              ),
              const SizedBox(width: 8),
              if (!_isEmpty(s))
                IconButton(
                  tooltip: 'Xoá nội dung',
                  icon: const Icon(Icons.close),
                  onPressed: () => onClearStop(i),
                )
              else
                const SizedBox(width: 40),

              if (canRemove)
                IconButton(
                  tooltip: 'Bỏ điểm dừng',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(i),
                )
              else
                const SizedBox(width: 40),

              if (canDrag)
                ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.drag_handle),
                  ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
        );
      },
    );
  }
}
