import 'dart:async';
import 'package:ev_charging_station/services/google_identity.dart';

const googleIdTokenFixture =
    'google-id-token-from-fake-provider-for-unit-tests-only';

class FakeGoogleIdentity implements GoogleIdentity {
  GoogleCredential credential = const GoogleCredential(
    idToken: googleIdTokenFixture,
  );
  Object? authenticationError;
  Object? signOutError;
  int signIns = 0;
  int signOuts = 0;
  final events = StreamController<GoogleCredential>.broadcast();
  @override
  Future<void> initialize() async {}
  @override
  Stream<GoogleCredential> get authenticationEvents => events.stream;
  @override
  Future<GoogleCredential> authenticate() async {
    signIns++;
    if (authenticationError != null) throw authenticationError!;
    return credential;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (signOutError != null) throw signOutError!;
  }
}
