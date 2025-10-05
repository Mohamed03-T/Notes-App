import 'package:flutter/material.dart';
import 'dart:math' as math;

/// زر FAB عائم مع قائمة خيارات منبثقة
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialChild> children;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData icon;
  final IconData? activeIcon;

  const SpeedDialFAB({
    super.key,
    required this.children,
    this.backgroundColor,
    this.foregroundColor,
    this.icon = Icons.add,
    this.activeIcon,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 400,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // خلفية شفافة عند الفتح (داخل حدود الـ SizedBox فقط)
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

          // الأزرار المنبثقة
          ...List.generate(widget.children.length, (index) {
            final child = widget.children[index];
            return _buildChildButton(child, index);
          }),

          // الزر الرئيسي
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              onPressed: () {
                print('FAB الرئيسي تم الضغط عليه');
                _toggle();
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * math.pi / 4,
                    child: Icon(
                      _isOpen ? (widget.activeIcon ?? Icons.close) : widget.icon,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildButton(SpeedDialChild child, int index) {
    final double baseDistance = 70.0;
    final double distance = baseDistance * (index + 1);

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, widget) {
        if (_expandAnimation.value == 0) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          bottom: distance * _expandAnimation.value,
          right: 0,
          child: Opacity(
            opacity: _expandAnimation.value,
            child: Transform.scale(
              scale: _expandAnimation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // التسمية
                  if (child.label != null)
                    GestureDetector(
                      onTap: () {
                        print('Label تم الضغط على $index');
                        _close();
                        child.onPressed();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          child.label!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                  // الزر
                  FloatingActionButton(
                    mini: true,
                    elevation: 4,
                    backgroundColor: child.backgroundColor ?? Colors.white,
                    foregroundColor: child.foregroundColor ?? Colors.black87,
                    onPressed: () {
                      print('SpeedDialFAB: تم الضغط على الزر $index - ${child.label}');
                      _close();
                      print('SpeedDialFAB: جاري استدعاء onPressed');
                      child.onPressed();
                      print('SpeedDialFAB: تم استدعاء onPressed');
                    },
                    heroTag: 'speed_dial_$index',
                    child: Icon(child.icon),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// عنصر فرعي في قائمة SpeedDial
class SpeedDialChild {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialChild({
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });
}
