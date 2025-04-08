class Endpoints {
  static const String login = 'auth/login/request';
  static const String loginVerify = 'auth/login/verify';
  static const String register = 'auth/register';
  static const String uploadImage = '/upload-profile-pictureimage';
  static const String addNewCard = 'payment-methods/addPaymentMethod';
  static const String getPaymentMethods = 'payment-methods/getPaymentMethods';
  static const String removeCard = 'payment-methods';
  static const String addGoogleUser = 'auth/mobile/social';
  static const String verify = 'auth/verify';
  static const String profile = 'getMyProfile';
  static const String preference = 'preference';
  static const String status = 'rides/request';
  static const String location = '/location';
  static const String wallet = '/wallet';
  static const String earnings = '/earnings';
  static const String earningsReport = '/earnings/report';
  static const String uploadDocs = '/upload-docs';
  static const String verifyDocs = '/verify-docs/:driverId';

}
