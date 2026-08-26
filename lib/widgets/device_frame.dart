import 'package:flutter/material.dart';

import '../core/theme/app_typography.dart';

/// Presents the app inside a phone mockup when it is running on a viewport far
/// larger than a phone — a desktop browser or a desktop shell.
///
/// This exists because the product is a fixed portrait experience. Stretched to
/// 1900 logical pixels a 56-high pill button becomes a 1900-wide pill, and the
/// design stops being reviewable. On an actual handset the frame never engages
/// and the widget is a pass-through, so nothing here can affect a shipped
/// mobile build.
///
/// Crucially it also *overrides* `MediaQuery`, so everything inside sees a
/// 390×844 screen with realistic notch and home-indicator insets. Without that
/// the frame would only crop the view while `SafeArea` and any size-dependent
/// layout still reasoned about the desktop window.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.child,
    this.canvas = const Size(390, 844),
    this.statusBarTime = '9:41',
    this.lightChrome = false,
  });

  final Widget child;

  /// Logical size of the simulated screen. Defaults to a 6.1" phone.
  final Size canvas;
  final String statusBarTime;

  /// Draw the simulated status bar in white. Set for screens with a dark
  /// background — the QR scanner — exactly as a real app would call
  /// `SystemUiOverlayStyle.light` for them.
  final bool lightChrome;

  /// Below this width the viewport is treated as a real phone and the frame
  /// steps out of the way entirely.
  static const double _engageAboveWidth = 620;

  /// `--dart-define=DEVICE_FRAME=off` disables the mockup, for anyone who wants
  /// the app to fill a desktop window.
  static const String _override =
      String.fromEnvironment('DEVICE_FRAME', defaultValue: 'auto');

  static const double _bezel = 13;
  static const double _outerRadius = 54;
  static const double _screenRadius = 42;

  /// Top and bottom insets a modern phone reserves for its notch and home
  /// indicator. Reported through `MediaQuery.padding` so `SafeArea` behaves
  /// exactly as it does on hardware.
  static const double _topInset = 47;
  static const double _bottomInset = 34;

  @override
  Widget build(BuildContext context) {
    if (_override == 'off') return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _engageAboveWidth;
        if (!wide) return child;

        return ColoredBox(
          color: const Color(0xFFE9EDF3),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              // Scales the whole mockup down on a short window rather than
              // clipping it. FittedBox transforms hit testing too, so the
              // scaled-down phone stays fully interactive.
              child: FittedBox(
                fit: BoxFit.contain,
                child: _Phone(
                  canvas: canvas,
                  statusBarTime: statusBarTime,
                  lightChrome: lightChrome,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({
    required this.canvas,
    required this.statusBarTime,
    required this.lightChrome,
    required this.child,
  });

  final Size canvas;
  final String statusBarTime;
  final bool lightChrome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      width: canvas.width + DeviceFrame._bezel * 2,
      height: canvas.height + DeviceFrame._bezel * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(DeviceFrame._outerRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33101722),
            blurRadius: 48,
            offset: Offset(0, 18),
            spreadRadius: -8,
          ),
        ],
        border: Border.all(color: const Color(0xFF2E333D), width: 1.5),
      ),
      padding: const EdgeInsets.all(DeviceFrame._bezel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DeviceFrame._screenRadius),
        child: SizedBox(
          width: canvas.width,
          height: canvas.height,
          child: MediaQuery(
            // The app now measures itself against a phone, not the window.
            data: media.copyWith(
              size: canvas,
              padding: const EdgeInsets.only(
                top: DeviceFrame._topInset,
                bottom: DeviceFrame._bottomInset,
              ),
              viewPadding: const EdgeInsets.only(
                top: DeviceFrame._topInset,
                bottom: DeviceFrame._bottomInset,
              ),
              viewInsets: EdgeInsets.zero,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: child),
                // Simulated system chrome, drawn over the insets the app was
                // just told to avoid.
                //
                // Wrapped in an explicit DefaultTextStyle: this chrome sits
                // above the Navigator and so has no Material ancestor, and the
                // inherited fallback there is the debug red-on-yellow-underline
                // style.
                Positioned.fill(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: AppFonts.latin,
                      fontSize: 14,
                      height: 1.2,
                      color: lightChrome ? Colors.white : _darkInk,
                      decoration: TextDecoration.none,
                    ),
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _StatusBar(
                              time: statusBarTime,
                              ink: lightChrome ? Colors.white : _darkInk,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _HomeIndicator(
                              ink: lightChrome
                                  ? Colors.white70
                                  : const Color(0x9916202E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Time on the left, a notch in the middle, signal/wi-fi/battery on the right —
/// the same chrome the reference mockups show.
const Color _darkInk = Color(0xFF16202E);

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.time, required this.ink});

  final String time;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceFrame._topInset,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              height: 26,
              width: 108,
              decoration: BoxDecoration(
                color: const Color(0xFF10131A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: AppTypography.numeric(
                    size: 14,
                    weight: FontWeight.w600,
                    color: ink,
                    spacing: 0,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_alt_rounded,
                        size: 15, color: ink),
                    const SizedBox(width: 5),
                    Icon(Icons.wifi_rounded, size: 15, color: ink),
                    const SizedBox(width: 5),
                    Icon(Icons.battery_full_rounded, size: 16, color: ink),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceFrame._bottomInset,
      child: Center(
        child: Container(
          height: 5,
          width: 134,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
