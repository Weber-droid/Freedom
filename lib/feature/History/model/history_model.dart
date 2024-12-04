class HistoryModel {
  const HistoryModel({
    this.destination,
    this.pickUpLocation,
    this.rideId,
    this.rideStatus,
    this.userName,
    this.riderImage,
  });
  final String? userName;
  final String? rideId;
  final bool? rideStatus;
  final String? pickUpLocation;
  final String? destination;
  final String? riderImage;
}

List<HistoryModel> historyList = [
  const HistoryModel(
    destination: 'Destination 1',
    pickUpLocation: 'Pick Up Location 1',
    rideId: 'Ride Id 1',
    userName: 'User Name 1',
    rideStatus: false,
    riderImage: 'assets/images/rider_profile_image.png',
  ),
  const HistoryModel(
    destination: 'Destination 2',
    pickUpLocation: 'Pick Up Location 2',
    rideId: 'Ride Id 2',
    userName: 'User Name 2',
    rideStatus: true,
    riderImage: 'assets/images/rider_profile_image.png',
  ),
  const HistoryModel(
    destination: 'Destination 3',
    pickUpLocation: 'Pick Up Location 3',
    rideId: 'Ride Id 3',
    userName: 'User Name 3',
    rideStatus: false,
    riderImage: 'assets/images/rider_profile_image.png',
  ),
];
