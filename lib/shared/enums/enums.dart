enum FormStatus { initial, submitting, success, failure }

enum PhoneStatus { initial, submitting, success, failure }

enum VerifyOtpStatus { initial, submitting, success, failure }

enum LoginStatus { initial, submitting, success, failure }

enum VerifyLoginStatus { initial, submitting, success, failure }

enum MapSearchStatus { initial, loading, success, error }

enum RideRequestStatus {
  initial,
  loading,
  searching,
  success,
  error,
  noDriverFound,
  cancelled,
  completed,
}

enum RideCancellationStatus { initial, canceling, cancelled, error }

enum DeliveryCancellationStatus { initial, canceling, cancelled, error }

enum RequestRidesStatus { initial, loading, success, error }

enum SocketStatus { initial, connecting, connected, disconnected }

enum DeliveryStatus { initial, loading, success, failure }

enum LocationServiceStatus {
  initial,
  loading,
  located,
  permissionDenied,
  permissionGranted,
  serviceDisabled,
  error,
}

enum RideStatus {
  pending,
  searching,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled,
  error,
}

extension RideStatusExtension on RideStatus {
  static RideStatus fromJson(String? status) {
    switch (status) {
      case 'pending':
        return RideStatus.pending;
      case 'accepted':
        return RideStatus.accepted;
      case 'completed':
        return RideStatus.completed;
      case 'canceled':
        return RideStatus.cancelled;
      default:
        throw ArgumentError('Invalid RideStatus: $status');
    }
  }
}
