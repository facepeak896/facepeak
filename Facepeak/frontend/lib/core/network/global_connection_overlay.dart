import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/core/network/connectivity_service.dart';

class GlobalConnectionOverlay extends StatefulWidget {
  final Widget child;

  const GlobalConnectionOverlay({
    super.key,
    required this.child,
  });

  @override
  State<GlobalConnectionOverlay> createState() =>
      _GlobalConnectionOverlayState();
}

class _GlobalConnectionOverlayState extends State<GlobalConnectionOverlay> {
  late bool _offline;
  StreamSubscription<NetworkStatus>? _sub;

  @override
  void initState() {
    super.initState();

    _offline = !ConnectivityService.instance.isOnline;

    _sub = ConnectivityService.instance.statusStream.listen((status) {
      if (!mounted) return;

      final offline = status == NetworkStatus.offline;

      if (_offline == offline) return;

      setState(() {
        _offline = offline;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,

        Positioned(
          top: top + 12,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: !_offline,
            child: AnimatedSlide(
              offset: _offline ? Offset.zero : const Offset(0, -1.35),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _offline ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF171018).withOpacity(0.92),
                          border: Border.all(
                            color: const Color(0xFFFF4D5E).withOpacity(0.34),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withOpacity(0.24),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: Color(0xFFFF6B75),
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "No internet connection. Check Wi-Fi or mobile data.",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.2,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}