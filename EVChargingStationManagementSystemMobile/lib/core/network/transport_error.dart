// Browsers expose certificate/CORS failures as network errors without details.
bool isTlsError(Object? error) => false;
