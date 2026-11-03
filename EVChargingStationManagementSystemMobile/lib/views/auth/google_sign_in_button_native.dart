import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/google_identity.dart';
import '../../core/constants/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final GoogleIdentity identity;
  final ValueChanged<GoogleCredential> onCredential;
  final VoidCallback onPressed;
  final bool isLoading;
  const GoogleSignInButton({
    super.key,
    required this.identity,
    required this.onCredential,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google_g.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Continue with Google',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
