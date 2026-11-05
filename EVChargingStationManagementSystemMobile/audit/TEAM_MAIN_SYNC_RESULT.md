# Team main synchronization — 05/11/2026

## What was merged

- Pulled origin/main (901c9be, including the team's Tan branch), preserving the team's web frontend, booking polling, profile/vehicle UX and backend changes.
- Kept local cached Android launcher and SePay hosted card Sandbox inside Android WebView.
- Resolved .gitignore conflict by retaining both groups' exclusions. Appsettings, local artifacts, backups, SQL data files and node_modules are not published.
- Regenerated pubspec.lock after automatic merge produced a lock inconsistent with pubspec.yaml; verified enforce-lockfile afterwards.
- Launcher reads public Google Client ID from the privately supplied root settings and includes it in APK cache fingerprint. No backend secret goes to Flutter or Vite. New optional run_web_admin.ps1 reads the same public ID and uses API HTTP 5058.
- Restored the existing authenticated transaction-history link removed from profile completion during the remote redesign. Backend JWT/owner filtering unchanged. New two-step vehicle UX retained, with explicit confirmation label.
- Adapted existing test harnesses to two-step UI, its one atomic profile save, silent booking polling, added provider dependencies and mocked GPS. Negative checks still verify incomplete profiles cannot enter Home, inactive/invalid vehicles cannot save and unauthorized data remains inaccessible. No tests deleted/skipped.

## Documentation for teammates

- DEMO_GUIDE.md: dependencies, clone/config placement, RUN_DEMO, OAuth SHA requirement, driver/staff accounts, Booking/Check-in/charging, fake card fields, Cash staff confirmation, optional web admin and troubleshooting.
- team-settings.example.json contains no secrets and leaves payment disabled. Team members receive the real latest appsettings.Local.json privately from the owner; the real file is ignored.
- Correct Google's Android OAuth registration still depends on the developer's signing certificate. A different debug keystore must be registered by the project owner once. SDK/LocalDB installation remains required; source configuration cannot install or register those automatically.
- VNPay stays disabled in TeamDemo. SePay Sandbox credentials and Internet are required for the hosted card test.

## Validation after merge

- Backend build: PASS, 0 errors, 116 warnings.
- SePay pure contract checks: 13 PASS, 0 FAIL (no external provider call in this run).
- Real Backend API + SQL fixture: 167 PASS, 0 FAIL; fresh temporary database migrations, backend-issued JWT, booking/charging prerequisites, Cash ownership/operator/amount, rollback, duplicate/concurrent settlement, transaction history. Fixture database removed; TeamDemo data not cleaned or used for this suite.
- Flutter: 260 PASS, 0 FAIL, 0 SKIP.
- Analyzer: 82 existing issues, no compilation errors.
- Flutter APK debug and web builds: PASS.
- React FE npm ci/build: PASS; existing large-bundle warning remains. FE business flows are not certified merely by its build.
- PowerShell launcher/backend/web helper syntax: PASS.
- Staged source checked against actual private payment tokens/secrets: no matches; no tracked appsettings file remains.

## Limits

No new real-money transaction, production deployment or live Google login on a teammate's machine was performed. The new SePay method's full SQL Paid/ledger proof remains subject to the limits documented in SEPAY_CARD_SANDBOX_RESULT.md; this merge does not claim that a successful build proves every live payment scenario. Test logs, private configurations and database backups remain local and untracked.
