import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;
import '../../services/google_identity.dart';

class GoogleSignInButton extends StatefulWidget {
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
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  late final StreamSubscription<GoogleCredential> _events;
  late final Future<void> _initialization;
  @override
  void initState() {
    super.initState();
    _events = widget.identity.authenticationEvents.listen(
      (credential) {
        if (mounted && !widget.isLoading) widget.onCredential(credential);
      },
      onError: (Object error) {
        if (mounted && !widget.isLoading) {
          widget.onCredential(
            GoogleCredential(failure: SdkGoogleIdentity.failureFor(error)),
          );
        }
      },
    );
    _initialization = widget.identity.initialize();
  }

  @override
  void dispose() {
    unawaited(_events.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OutlinedButton(
              onPressed: null,
              child: Text('Continue with Google'),
            ),
            const SizedBox(height: 6),
            Text(
              SdkGoogleIdentity.failureFor(snapshot.error!).message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) => Center(
          child: IgnorePointer(
            ignoring: widget.isLoading,
            child: google_web.renderButton(
              configuration: google_web.GSIButtonConfiguration(
                text: google_web.GSIButtonText.continueWith,
                size: google_web.GSIButtonSize.large,
                theme: google_web.GSIButtonTheme.outline,
                minimumWidth: constraints.maxWidth.clamp(120, 400).toDouble(),
              ),
            ),
          ),
        ),
      );
    },
  );
}
