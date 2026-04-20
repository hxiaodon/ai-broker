import 'package:flutter/material.dart';

/// A slide-to-confirm widget that requires the user to drag a thumb
/// from left to right to confirm an action.
class SlideToConfirmWidget extends StatefulWidget {
  const SlideToConfirmWidget({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.backgroundColor = const Color(0xFF242638),
    this.thumbColor = const Color(0xFF1A73E8),
    this.labelColor = const Color(0xFFB0B3C8),
    this.height = 56,
  });

  final String label;
  final VoidCallback onConfirmed;
  final Color backgroundColor;
  final Color thumbColor;
  final Color labelColor;
  final double height;

  @override
  State<SlideToConfirmWidget> createState() => _SlideToConfirmWidgetState();
}

class _SlideToConfirmWidgetState extends State<SlideToConfirmWidget>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _confirmed = false;
  late AnimationController _snapBack;
  late Animation<double> _snapAnimation;

  static const _thumbSize = 48.0;
  static const _confirmThreshold = 0.85;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _snapBack, curve: Curves.easeOut),
    );
    _snapAnimation.addListener(() {
      setState(() => _dragPosition = _snapAnimation.value);
    });
  }

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_confirmed) return;
    setState(() {
      _dragPosition =
          (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(double maxDrag) {
    if (_confirmed) return;
    if (_dragPosition >= maxDrag * _confirmThreshold) {
      setState(() {
        _confirmed = true;
        _dragPosition = maxDrag;
      });
      widget.onConfirmed();
    } else {
      _snapAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0,
      ).animate(CurvedAnimation(parent: _snapBack, curve: Curves.easeOut));
      _snapBack.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - 8;
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Progress fill
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        color: widget.thumbColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
              // Label
              Center(
                child: Opacity(
                  opacity: (1 - progress * 2).clamp(0.0, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.labelColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Thumb
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (_) => _onDragEnd(maxDrag),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: _confirmed
                          ? const Color(0xFF0DC582)
                          : widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.thumbColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _confirmed ? Icons.check : Icons.chevron_right,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
