library;

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// SmoothCurvedBottomBar
/// - TRUE curved geometry (actual Path)
/// - TRUE center notch for FAB (centerDocked)
/// - SAME external API (child, backgroundColor, borderColor, height)
///
/// Upgrade (supercool, still safe):
/// - Optional glass blur + translucent tint (doesn't affect layout)
/// - Softer, more premium shadow (via elevation + optional drawShadow)
/// - Dual-stroke border (outer + inner highlight) for depth
/// - Optional subtle top gloss
/// - Respects accessibility "reduce motion" (disables blur automatically)
class SmoothCurvedBottomBar extends StatelessWidget {
  const SmoothCurvedBottomBar({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.height,

    // Existing tunables (kept)
    this.cornerRadius = 28,
    this.notchRadius = 34,
    this.notchMargin = 12,
    this.notchDepth = 24,
    this.elevation = 10,
    this.borderWidth = 1.2,
    this.contentTopPadding = 10,
    this.contentHorizontalPadding = 14,

    // Supercool (optional, defaults are safe)
    this.enableGlass = true,
    this.glassBlurSigma = 18,
    this.fillOpacity = 0.92,
    this.enableTopGloss = true,
    this.glossOpacity = 0.10,
    this.enableSoftShadow = true,
    this.softShadowOpacity = 0.22,
    this.innerStrokeOpacity = 0.35,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double height;

  /// Outer rounded corners of the bar.
  final double cornerRadius;

  /// Notch radius (roughly controls notch width).
  /// For a 64x64 FAB, 32–38 is a sweet spot.
  final double notchRadius;

  /// Extra space on each side of notch.
  final double notchMargin;

  /// How deep the notch dips down from the top edge.
  final double notchDepth;

  /// Shadow / lift.
  final double elevation;

  /// Border stroke width (outer).
  final double borderWidth;

  /// Content padding inside bar.
  final double contentTopPadding;
  final double contentHorizontalPadding;

  // --- Supercool controls ---
  final bool enableGlass;
  final double glassBlurSigma;
  final double fillOpacity;

  final bool enableTopGloss;
  final double glossOpacity;

  final bool enableSoftShadow;
  final double softShadowOpacity;

  /// Inner highlight stroke (thin) opacity, derived from borderColor.
  final double innerStrokeOpacity;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = height + bottomInset;

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final sigma = (enableGlass && !reduceMotion) ? glassBlurSigma : 0.0;

    final clipper = _CurvedNotchedBarClipper(
      cornerRadius: cornerRadius,
      notchRadius: notchRadius,
      notchMargin: notchMargin,
      notchDepth: notchDepth,
    );

    // Slightly translucent fill so the blur reads as “glass”
    final fill = backgroundColor.withValues(alpha: fillOpacity.clamp(0.0, 1.0));

    return SizedBox(
      height: totalHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base: true shape + elevation
          PhysicalShape(
            clipper: clipper,
            clipBehavior: Clip.antiAlias,
            elevation: elevation,
            color: fill,
            shadowColor: Colors.black.withValues(alpha: softShadowOpacity.clamp(0.0, 1.0)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Glass blur (behind content, clipped to shape)
                if (sigma > 0)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: const SizedBox.expand(),
                  ),

                // Subtle gradient tint for premium depth (does not change layout)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        // a touch brighter top-left
                        Color.alphaBlend(Colors.white.withValues(alpha: 0.06), fill),
                        // a touch deeper bottom-right
                        Color.alphaBlend(Colors.black.withValues(alpha: 0.06), fill),
                      ],
                    ),
                  ),
                ),

                // Optional top gloss strip
                if (enableTopGloss)
                  Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: glossOpacity.clamp(0.0, 0.25)),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Optional extra soft shadow pass (more “iOS” feel)
          if (enableSoftShadow)
            IgnorePointer(
              child: CustomPaint(
                painter: _CurvedNotchedShadowPainter(
                  clipper: clipper,
                  opacity: softShadowOpacity,
                ),
              ),
            ),

          // Border stroke + inner highlight stroke on same exact path
          IgnorePointer(
            child: CustomPaint(
              painter: _CurvedNotchedBarBorderPainter(
                clipper: clipper,
                borderColor: borderColor,
                borderWidth: borderWidth,
                innerStrokeOpacity: innerStrokeOpacity,
              ),
            ),
          ),

          // Your original content row (unchanged)
          Padding(
            padding: EdgeInsets.only(
              left: contentHorizontalPadding,
              right: contentHorizontalPadding,
              top: contentTopPadding,
              bottom: bottomInset,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Draws the actual curved bar outline with a smooth center notch.
class _CurvedNotchedBarClipper extends CustomClipper<Path> {
  _CurvedNotchedBarClipper({
    required this.cornerRadius,
    required this.notchRadius,
    required this.notchMargin,
    required this.notchDepth,
  });

  final double cornerRadius;
  final double notchRadius;
  final double notchMargin;
  final double notchDepth;

  @override
  Path getClip(Size size) {
    final w = noting(size.width);
    final h = noting(size.height);

    final r = cornerRadius.clamp(0.0, 42.0);

    // Center notch geometry
    final cx = w / 2.0;
    final desiredNotchW = (notchRadius * 2.0) + (notchMargin * 2.0);

    // Keep notch away from corner curves
    final safeLeft = r + 10.0;
    final safeRight = w - r - 10.0;

    // Proposed edges
    var nl = (cx - desiredNotchW / 2.0).clamp(safeLeft, safeRight);
    var nr = (cx + desiredNotchW / 2.0).clamp(safeLeft, safeRight);

    // Ensure we always have a valid width after clamping
    final minWidth = (notchRadius * 2.0) + 8.0;
    if ((nr - nl) < minWidth) {
      final mid = (nl + nr) / 2.0;
      nl = (mid - minWidth / 2.0).clamp(safeLeft, safeRight - minWidth);
      nr = nl + minWidth;
    }

    // Depth limited for small heights
    final d = notchDepth.clamp(0.0, h * 0.60);

    // Smoothness control: larger pull -> rounder notch
    final pull = (notchRadius * 0.95).clamp(18.0, 48.0);
    final mid = (nl + nr) / 2.0;

    final p = Path();

    // Start at top-left after corner radius
    p.moveTo(r, 0);

    // Top edge to notch start
    p.lineTo(nl, 0);

    // Notch (two cubic segments, symmetric, smooth)
    p.cubicTo(
      nl + (nr - nl) * 0.12,
      0,
      mid - pull,
      d,
      mid,
      d,
    );
    p.cubicTo(
      mid + pull,
      d,
      nr - (nr - nl) * 0.12,
      0,
      nr,
      0,
    );

    // Continue top edge to right corner start
    p.lineTo(w - r, 0);

    // Top-right corner
    p.quadraticBezierTo(w, 0, w, r);

    // Right edge down to bottom-right corner start
    p.lineTo(w, h - r);

    // Bottom-right corner
    p.quadraticBezierTo(w, h, w - r, h);

    // Bottom edge to bottom-left corner start
    p.lineTo(r, h);

    // Bottom-left corner
    p.quadraticBezierTo(0, h, 0, h - r);

    // Left edge up to top-left corner start
    p.lineTo(0, r);

    // Top-left corner back to start
    p.quadraticBezierTo(0, 0, r, 0);

    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant _CurvedNotchedBarClipper old) {
    return cornerRadius != old.cornerRadius ||
        notchRadius != old.notchRadius ||
        notchMargin != old.notchMargin ||
        notchDepth != old.notchDepth;
  }

  double noting(double v) => v.isFinite ? v : 0.0;
}

class _CurvedNotchedBarBorderPainter extends CustomPainter {
  _CurvedNotchedBarBorderPainter({
    required this.clipper,
    required this.borderColor,
    required this.borderWidth,
    required this.innerStrokeOpacity,
  });

  final _CurvedNotchedBarClipper clipper;
  final Color borderColor;
  final double borderWidth;
  final double innerStrokeOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);

    // Outer border
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor
      ..isAntiAlias = true;

    // Inner “light” stroke (thin) for premium depth
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (borderWidth * 0.55).clamp(0.6, 1.2)
      ..color = borderColor.withValues(alpha: innerStrokeOpacity.clamp(0.0, 1.0))
      ..isAntiAlias = true;

    canvas.drawPath(path, outer);

    // Slightly inset inner stroke so it reads as an inner edge
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(0, 0.5);
    canvas.drawPath(path, inner);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchedBarBorderPainter old) {
    return old.borderColor != borderColor ||
        old.borderWidth != borderWidth ||
        old.innerStrokeOpacity != innerStrokeOpacity ||
        old.clipper.cornerRadius != clipper.cornerRadius ||
        old.clipper.notchRadius != clipper.notchRadius ||
        old.clipper.notchMargin != clipper.notchMargin ||
        old.clipper.notchDepth != clipper.notchDepth;
  }
}

/// Extra soft shadow pass (subtle). Completely optional.
class _CurvedNotchedShadowPainter extends CustomPainter {
  _CurvedNotchedShadowPainter({
    required this.clipper,
    required this.opacity,
  });

  final _CurvedNotchedBarClipper clipper;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);

    // A gentle shadow that feels less “Material” and more “premium”
    // (drawShadow ignores blur sigma, but looks great combined with elevation)
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: (opacity * 0.35).clamp(0.0, 0.35)),
      6.0,
      false,
    );
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchedShadowPainter old) {
    return old.opacity != opacity ||
        old.clipper.cornerRadius != clipper.cornerRadius ||
        old.clipper.notchRadius != clipper.notchRadius ||
        old.clipper.notchMargin != clipper.notchMargin ||
        old.clipper.notchDepth != clipper.notchDepth;
  }
}
