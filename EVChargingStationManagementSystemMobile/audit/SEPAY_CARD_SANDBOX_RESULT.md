# SePay hosted card Sandbox — 05/11/2026

## Implemented

- New SePaySandbox method alongside existing Cash and SePayTest; pending invoices keep their existing method.
- Backend signs ordered checkout form fields with HMAC-SHA256. Secret stays in ignored root appsettings.Local.json; only SP-TEST/spsk_test credentials, fixed Sandbox hosts and EVCSMS_TeamDemo allowed.
- Authenticated owner receives a Data Protection ticket (15 minutes). Anonymous form redemption validates ticket, expiry and pending owner/session chain again. No-store/no-referrer headers.
- Flutter opens hosted card checkout automatically on status screen, supports reopen and polls when resumed/every 5 seconds while pending.
- Settlement reuses existing atomic DatabaseWork/Settle path, rechecks pending owner/amount/reference/session and existing ledger. Only authenticated SePay REST response with exact invoice, owner, amount, currency, CAPTURED and PAYMENT/APPROVED qualifies. No redirect or browser status is trusted.
- No schema changes, production enablement, real money or secret commits.

## Verification

- Backend build: PASS, 0 errors; 120 existing warnings.
- Flutter regression: 250 PASS, 0 FAIL, 0 SKIP.
- Contract tests: 14 PASS (including actual Sandbox response), 0 FAIL.
- Analyzer final run: 90 issues, no errors; three newly introduced brace infos corrected. Other analyzer issues remain outside scope.
- APK debug built and installed successfully on emulator-5554, preserving app data.
- Merchant REST authentication: HTTP 200.
- Hosted form actually opened CARD fields; fake card 4111111111111111, DEMO USER, 12/30, CVV 123 reached simulated result selection.
- Probe invoice EVPROBEC4F9F53A70084B9BABA66CEB43252BEF: official API reports CAPTURED, VND 12000.00, matching synthetic customer, PAYMENT/APPROVED 12000. Contract verifier accepted actual payload. This probe was separate from the application's SQL payment ledger.
- Real app API fixture driver8: Booking → Check-in → Start → Stop demo → create SePaySandbox payment, amount 110 VND; session 62a438d0-d842-4e7d-b661-b0b5af2bcbfa remains Completed/pending. Duplicate create 409; foreign owner's link 404; altered ticket 400; authorized form 200, correct fixed Sandbox host, no secret in form.

## Limits / test state

- Full new-method SQL Paid/ledger completion has NOT been established. Automatic approval review rejected final simulated-success click (financial confirmation) and rejected settling a Cash fixture on current database, citing prior no-Paid-on-current-DB restriction. No workaround used. Actual provider probe success was subsequently observed and verified read-only.
- No claim that all end-to-end payment paths have passed. A temporary isolated database integration test is still needed for new-method duplicate/concurrent settlement through final Paid/ledger state.
- driver9 has a Completed zero-energy test session from stopping immediately; online creation correctly rejected 0 VND. No payment/ledger was inserted for it. driver8 has the pending invoice above. User's account was not reset.
- Local HTTPS callback/IPN is not required by this pull-verification flow. Internet access to SePay is required; UI explicitly requires returning to the app.
- Private appsettings.Local.json now also has GatewayMerchantId/GatewaySecretKey using previously supplied Sandbox credentials. File remains ignored. Existing config edits/deletions and remote-main divergence were preserved; nothing pushed in this task.

## Official contracts

- https://developer.sepay.vn/vi/cong-thanh-toan/sandbox
- https://developer.sepay.vn/vi/cong-thanh-toan/API/don-hang/form-thanh-toan
- https://developer.sepay.vn/vi/cong-thanh-toan/API/don-hang/chi-tiet-don-hang
