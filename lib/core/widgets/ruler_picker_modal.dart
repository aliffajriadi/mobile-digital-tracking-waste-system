import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RulerPickerModal extends StatefulWidget {
  final double initialValue;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  const RulerPickerModal({
    super.key,
    required this.initialValue,
    this.min = 0.0,
    this.max = 500.0,
    this.step = 0.1,
    this.unit = 'Kg',
    required this.onChanged,
  });

  @override
  State<RulerPickerModal> createState() => _RulerPickerModalState();
}

class _RulerPickerModalState extends State<RulerPickerModal> {
  late ScrollController _scrollController;
  late double _currentValue;
  final double _tickSpacing = 15.0;
  int _lastHapticTick = -1;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.min, widget.max);
    
    // Calculate initial offset
    final initialOffset = ((_currentValue - widget.min) / widget.step) * _tickSpacing;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final int tickIndex = (offset / _tickSpacing).round();
    final double calculatedValue = widget.min + (tickIndex * widget.step);
    final double clampedValue = calculatedValue.clamp(widget.min, widget.max);

    if (clampedValue != _currentValue) {
      setState(() {
        _currentValue = clampedValue;
      });
      widget.onChanged(_currentValue);
      
      // Haptic feedback
      if (_lastHapticTick != tickIndex) {
        HapticFeedback.selectionClick();
        _lastHapticTick = tickIndex;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    final int totalTicks = ((widget.max - widget.min) / widget.step).round() + 1;

    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
            "Geser Penggaris",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currentValue.toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: primaryColor),
              ),
              const SizedBox(width: 8),
              Text(
                widget.unit,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification) {
                      // Snap to nearest tick
                      final offset = _scrollController.offset;
                      final int tickIndex = (offset / _tickSpacing).round();
                      final double targetOffset = tickIndex * _tickSpacing;
                      
                      Future.microtask(() {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            targetOffset,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                    return true;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: totalTicks,
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2),
                    itemBuilder: (context, index) {
                      final bool isMajorTick = index % 10 == 0;
                      final bool isMidTick = index % 5 == 0 && !isMajorTick;
                      
                      final double tickHeight = isMajorTick ? 50.0 : (isMidTick ? 35.0 : 20.0);
                      final Color tickColor = isMajorTick ? primaryColor : Colors.grey.shade400;
                      
                      final double val = widget.min + (index * widget.step);

                      return SizedBox(
                        width: _tickSpacing,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isMajorTick)
                              Text(
                                val.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: tickColor,
                                ),
                              ),
                            if (isMajorTick) const SizedBox(height: 4),
                            Container(
                              width: isMajorTick ? 3 : 2,
                              height: tickHeight,
                              decoration: BoxDecoration(
                                color: tickColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Pointer (jarum jam)
              IgnorePointer(
                child: Container(
                  width: 4,
                  height: 70,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)
                    ]
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, _currentValue),
                  child: const Text("Pilih", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Future<double?> showRulerPickerModal(
  BuildContext context, {
  required double initialValue,
  double min = 0.0,
  double max = 500.0,
  String unit = 'Kg',
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RulerPickerModal(
      initialValue: initialValue,
      min: min,
      max: max,
      unit: unit,
      onChanged: (val) {},
    ),
  );
}
