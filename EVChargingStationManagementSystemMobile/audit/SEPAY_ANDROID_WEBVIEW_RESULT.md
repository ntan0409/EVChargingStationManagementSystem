# SePay Sandbox inside Android — 05/11/2026

- Added official webview_flutter 4.14.1 and locked dependencies.
- Android opens SePayCheckoutScreen inside the app instead of launching an external browser. Other platforms retain existing browser behavior.
- Uses the backend's short-lived form ticket. No JWT, secret key, JavaScript bridge or locally collected card fields are passed into the payment page.
- Navigation allows the exact initial backend form URL plus HTTPS pay-sandbox.sepay.vn port 443. Production, custom schemes, different local routes and lookalike hosts are blocked. Certificate verification remains enabled.
- Embedded screen polls authenticated backend every five seconds, prevents overlapping polls, pauses in background, disposes timers and closes only on server-confirmed Paid. Android Back/close returns to invoice and reconciles again. Redirects/page text do not mark payment successful.
- Network/expired initial link errors offer retry or return to invoice. Sandbox/fake-money notice stays visible.
- Regression: 260 PASS, 0 FAIL, 0 SKIP, including ten navigation policy checks.
- Analyzer: 90 pre-existing issues, no errors; no new issue count increase.
- This change does not establish new evidence of final SQL settlement. Previous payment verification limits remain in SEPAY_CARD_SANDBOX_RESULT.md. No payment was forced Paid during this change.
