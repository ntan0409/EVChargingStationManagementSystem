import 'dart:io';

bool isTlsError(Object? error) => error is TlsException;
