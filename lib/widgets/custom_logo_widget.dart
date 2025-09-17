import 'package:flutter/material.dart';

class CustomLogoWidget extends StatelessWidget {
  final double size;
  final List<Color>? gradientColors;
  final String? logoText;

  const CustomLogoWidget({
    Key? key,
    this.size = 200,
    this.gradientColors,
    this.logoText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      const Color(0xFF4A90E2),
      const Color(0xFF357ABD),
      const Color(0xFF2E5A87),
    ];

    // التأكد من أن عدد الألوان يتطابق مع عدد stops
    final List<double> stops;
    if (colors.length == 2) {
      stops = [0.0, 1.0];
    } else if (colors.length == 3) {
      stops = [0.0, 0.6, 1.0];
    } else {
      // في حالة عدد مختلف من الألوان، نوزع stops بالتساوي
      stops = List.generate(colors.length, (index) => index / (colors.length - 1));
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: stops,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.4),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.02),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الدائرة الداخلية
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          
          // أيقونة الملاحظة الرئيسية
          Container(
            width: size * 0.4,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: size * 0.02,
                  offset: Offset(0, size * 0.01),
                ),
              ],
            ),
            child: Stack(
              children: [
                // خطوط النص
                Positioned(
                  top: size * 0.08,
                  left: size * 0.05,
                  right: size * 0.05,
                  child: Column(
                    children: List.generate(5, (index) {
                      final widths = [0.8, 0.6, 0.9, 0.7, 0.5];
                      return Container(
                        margin: EdgeInsets.only(bottom: size * 0.02),
                        width: size * 0.3 * widths[index],
                        height: size * 0.01,
                        decoration: BoxDecoration(
                          color: colors.first.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(size * 0.005),
                        ),
                      );
                    }),
                  ),
                ),
                
                // أيقونة القلم الصغيرة
                Positioned(
                  top: size * 0.05,
                  right: size * 0.03,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      width: size * 0.03,
                      height: size * 0.12,
                      decoration: BoxDecoration(
                        color: colors.last,
                        borderRadius: BorderRadius.circular(size * 0.015),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // عناصر تزيينية متناثرة
          ...List.generate(6, (index) {
            final positions = [
              {'top': 0.2, 'left': 0.15},
              {'top': 0.15, 'right': 0.25},
              {'bottom': 0.25, 'left': 0.2},
              {'bottom': 0.2, 'right': 0.15},
              {'top': 0.4, 'left': 0.1},
              {'bottom': 0.4, 'right': 0.1},
            ];
            
            final sizes = [0.08, 0.06, 0.05, 0.07, 0.04, 0.06];
            final opacities = [0.4, 0.3, 0.5, 0.2, 0.6, 0.3];
            
            return Positioned(
              top: positions[index]['top'] != null ? size * positions[index]['top']! : null,
              bottom: positions[index]['bottom'] != null ? size * positions[index]['bottom']! : null,
              left: positions[index]['left'] != null ? size * positions[index]['left']! : null,
              right: positions[index]['right'] != null ? size * positions[index]['right']! : null,
              child: Container(
                width: size * sizes[index],
                height: size * sizes[index],
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(opacities[index]),
                ),
              ),
            );
          }),
          
          // النص في الأسفل (إذا تم توفيره)
          if (logoText != null)
            Positioned(
              bottom: -size * 0.15,
              child: Text(
                logoText!,
                style: TextStyle(
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.bold,
                  color: colors.first,
                  letterSpacing: size * 0.01,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// وظيفة لحفظ الشعار كصورة (يمكن استخدامها لاحقاً)
class LogoExporter {
  static Widget createExportableLogo({
    double size = 512,
    List<Color>? colors,
    String? text,
  }) {
    return Container(
      width: size,
      height: size,
      color: Colors.transparent,
      child: CustomLogoWidget(
        size: size,
        gradientColors: colors,
        logoText: text,
      ),
    );
  }
}
