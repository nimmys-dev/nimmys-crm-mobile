import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Where the brand artwork lives.
class AppLogoAssets {
  const AppLogoAssets._();

  static const String wordmark = 'assets/images/nimmys_logo.png';
}

/// Tone of the surface the logo is sitting on.
enum AppLogoTone {
  /// Dark backdrop — the artwork's black plate is blended away so only the
  /// white "nimmys" and red "camera centre" remain.
  onDark,

  /// Light backdrop — the artwork is shown on its own black plate, which is
  /// how the brand presents itself anyway.
  onLight,
}

/// Full NIMMYS wordmark.
///
/// The supplied PNG has an opaque black background rather than an alpha
/// channel, so on dark surfaces it is composited with [BlendMode.screen]:
/// black pixels become invisible and the letterforms sit directly on the
/// gradient with no visible rectangle.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 46,
    this.tone = AppLogoTone.onDark,
    this.showTagline = true,
  });

  final double height;
  final AppLogoTone tone;

  /// Only used by the painted fallback; the artwork always includes its
  /// "camera centre" line.
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      AppLogoAssets.wordmark,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return AppLogoFallback(
          height: height,
          tone: tone,
          showTagline: showTagline,
        );
      },
    );

    if (tone == AppLogoTone.onDark) {
      return BlendMaskLayer(blendMode: BlendMode.screen, child: image);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.22,
        vertical: height * 0.18,
      ),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: image,
    );
  }
}

/// Composites its child against the existing backdrop using [blendMode].
///
/// Used to drop the opaque black plate out of the logo artwork.
class BlendMaskLayer extends SingleChildRenderObjectWidget {
  const BlendMaskLayer({
    super.key,
    required this.blendMode,
    this.opacity = 1.0,
    super.child,
  });

  final BlendMode blendMode;
  final double opacity;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderBlendMask(blendMode: blendMode, opacity: opacity);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderBlendMask renderObject,
  ) {
    renderObject
      ..blendMode = blendMode
      ..opacity = opacity;
  }
}

/// Render object backing [BlendMaskLayer].
class RenderBlendMask extends RenderProxyBox {
  RenderBlendMask({required BlendMode blendMode, required double opacity})
    : _blendMode = blendMode,
      _opacity = opacity;

  BlendMode _blendMode;
  double _opacity;

  set blendMode(BlendMode value) {
    if (_blendMode == value) {
      return;
    }
    _blendMode = value;
    markNeedsPaint();
  }

  set opacity(double value) {
    if (_opacity == value) {
      return;
    }
    _opacity = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.saveLayer(
      offset & size,
      Paint()
        ..blendMode = _blendMode
        ..color = Color.fromARGB((_opacity * 255).round(), 0, 0, 0),
    );
    super.paint(context, offset);
    context.canvas.restore();
  }
}

/// Hand-built lockup used if the logo asset cannot be loaded.
class AppLogoFallback extends StatelessWidget {
  const AppLogoFallback({
    super.key,
    this.height = 46,
    this.tone = AppLogoTone.onDark,
    this.showTagline = true,
  });

  final double height;
  final AppLogoTone tone;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final Color wordColor = tone == AppLogoTone.onDark
        ? AppColors.white
        : context.palette.ink;

    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AppLogoMark(size: height * 0.86),
          SizedBox(width: height * 0.2),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'nimmys',
                style: TextStyle(
                  fontSize: height * 0.52,
                  fontWeight: FontWeight.w800,
                  color: wordColor,
                  letterSpacing: height * 0.02,
                  height: 1.05,
                ),
              ),
              if (showTagline)
                Text(
                  'camera centre',
                  style: TextStyle(
                    fontSize: height * 0.21,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                    letterSpacing: height * 0.055,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The standalone red "n" mark — used in compact spots such as the splash
/// badge, list avatars and app bars.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.actionGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.42),
          topRight: Radius.circular(size * 0.14),
          bottomLeft: Radius.circular(size * 0.14),
          bottomRight: Radius.circular(size * 0.14),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'n',
        style: TextStyle(
          fontSize: size * 0.66,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
