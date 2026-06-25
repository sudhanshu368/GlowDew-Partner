import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RazorLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showText;
  final String heroTag;

  const RazorLogo({
    super.key,
    this.iconSize = 28.0,
    this.fontSize = 24.0,
    this.showText = true,
    this.heroTag = 'razor_logo_hero',
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: iconSize + 6,
                  height: iconSize + 6,
                  fit: BoxFit.cover,
                ),
              ),
              if (showText) ...[
                const SizedBox(width: 10),
                Text(
                  'GlowDew Partner',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
