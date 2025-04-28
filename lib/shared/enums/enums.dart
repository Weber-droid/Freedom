enum FormStatus { initial, submitting, success, failure }

enum PhoneStatus { initial, submitting, success, failure }

enum VerifyOtpStatus { initial, submitting, success, failure }

enum LoginStatus { initial, submitting, success, failure }

enum VerifyLoginStatus { initial, submitting, success, failure }

enum MapSearchStatus { initial, loading, success, error }

enum LocationServiceStatus {
  initial,
  loading,
  located,
  permissionDenied,
  permissionGranted,
  serviceDisabled,
  error
}
