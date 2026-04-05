import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:frontend/services/ads_service.dart';
import 'appeal_free_upload_screen.dart';

class AppealFreeRewardedGateScreen extends StatefulWidget {
  final String guestToken;

  const AppealFreeRewardedGateScreen({
    super.key,
    required this.guestToken,
  });

  // ===== THEME =====
  static const Color bg = Color(0xFF07090D);
  static const Color text = Color(0xFFEAF0FF);
  static const Color muted = Color(0xFF8B90A0);
  static const Color gold = Color(0xFFF5C518);
  static const double rBtn = 18;

  @override
  State<AppealFreeRewardedGateScreen> createState() =>
      _AppealFreeRewardedGateScreenState();
}

class _AppealFreeRewardedGateScreenState
    extends State<AppealFreeRewardedGateScreen> {
  bool _loading = false;

  // 🔥 KLJUČ: ad se smije pogledati samo jednom po flowu
  bool _rewardConsumedThisFlow = false;

  // ===============================
  // 🎬 WATCH AD → ONE-WAY FLOW
  // ===============================
  Future<void> _watchAd() async {
    // ❌ nema ponavljanja
    if (_loading || _rewardConsumedThisFlow) return;

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    final success = await AdsService.instance.showRewardedAd();

    if (!mounted) return;

    // ❌ ad nije dovršen → ostaješ ovdje
    if (!success) {
      setState(() => _loading = false);
      return;
    }

    // ✅ ad je potrošen u ovom flowu
    _rewardConsumedThisFlow = true;

    // 🚀 NEMA POVRATKA — IDEMO DALJE
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppealUploadScreen(
          guestToken: widget.guestToken,
        ),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 🔒 dodatna sigurnost — nema back gesture
      onWillPop: () async => !_loading,
      child: Scaffold(
        backgroundColor: AppealFreeRewardedGateScreen.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TITLE =====
                const Text(
                  'Unlock Appeal',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppealFreeRewardedGateScreen.text,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Appeal is situational.\n'
                  'Lighting. Expression. Presence.\n\n'
                  'To unlock this analysis, watch one short ad.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppealFreeRewardedGateScreen.muted,
                  ),
                ),

                const Spacer(),

                // ===== CTA =====
                SizedBox(
                  height: 58,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_loading || _rewardConsumedThisFlow)
                            ? null
                            : _watchAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppealFreeRewardedGateScreen.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppealFreeRewardedGateScreen.rBtn,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Watch ad to continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // ===== CANCEL =====
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppealFreeRewardedGateScreen.muted,
                        fontWeight: FontWeight.w700,
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