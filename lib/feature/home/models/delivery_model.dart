class DeliveryModel {
  const DeliveryModel({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.deliveryType,
    required this.packageName,
    required this.packageSize,
    required this.packageDescription,
    required this.receipientName,
    required this.receipientPhone,
    required this.paymentMethod,
  });

  final String pickupLocation;
  final String destinationLocation;
  final String deliveryType;
  final String packageName;
  final String packageSize;
  final String packageDescription;
  final String receipientName;
  final String receipientPhone;
  final String paymentMethod;

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation,
      'dropoffLocation': destinationLocation,
      'packageType': deliveryType,
      'packageName': packageName,
      'packageSize': packageSize,
      'packageDescription': packageDescription,
      'recipientName': receipientName,
      'recipientPhone': receipientPhone,
      'deliveryInstructions': packageDescription,
      'paymentMethod': paymentMethod,
    };
  }

  // Factory method for creating a model with multiple destinations
  // This can be used when you need to handle multiple destinations
  factory DeliveryModel.withMultipleDestinations({
    required String pickupLocation,
    required List<String> destinationLocations,
    required String deliveryType,
    required String packageName,
    required String packageSize,
    required String packageDescription,
    required String receipientName,
    required String receipientPhone,
    required String paymentMethod,
  }) {
    // For now, just use the first destination in the standard model
    // You can extend this later if needed to handle multiple destinations in your API
    final primaryDestination =
        destinationLocations.isNotEmpty ? destinationLocations.first : '';

    return DeliveryModel(
      pickupLocation: pickupLocation,
      destinationLocation: primaryDestination,
      deliveryType: deliveryType,
      packageName: packageName,
      packageSize: packageSize,
      packageDescription: packageDescription,
      receipientName: receipientName,
      receipientPhone: receipientPhone,
      paymentMethod: paymentMethod,
    );
  }
}
