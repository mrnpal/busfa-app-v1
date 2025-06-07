import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void showLottieToast({
  required BuildContext context,
  required bool success,
  required String message,
}) {
  final color = success ? Colors.green : Colors.red;
  final icon =
      success ? 'assets/lottie/success.json' : 'assets/lottie/error.json';

  final overlay = OverlayEntry(
    builder:
        (context) => Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: Lottie.asset(icon, repeat: false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  Overlay.of(context).insert(overlay);

  Future.delayed(const Duration(seconds: 3), () => overlay.remove());
}
