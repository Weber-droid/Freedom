class AddCardResponse {
  AddCardResponse(
      {required this.data, required this.success, required this.message});

  factory AddCardResponse.fromJson(Map<String, dynamic> json) {
    return AddCardResponse(
      data: AddCardResponseData.fromJson(json['data'] as Map<String, dynamic>),
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
  final AddCardResponseData data;
  final bool success;
  final String message;
}

class AddCardResponseData {
  AddCardResponseData(
    this.id,
    this.userId,
    this.type,
    this.createdAt,
    this.updatedAt, {
    this.expiryMonth,
    this.expiryYear,
    this.token,
    this.cardType,
    this.last4,
    this.isDefault,
    this.momoNumber,
    this.momoProvider,
  });

  factory AddCardResponseData.fromJson(Map<String, dynamic> json) {
    return AddCardResponseData(
      json['id'] as String,
      json['userId'] as String,
      json['type'] as String,
      cardType: json['cardType'] as String?,
      last4: json['last4'] as String?,
      expiryMonth: json['expiryMonth'] as String?,
      expiryYear: json['expiryYear'] as String?,
      isDefault: json['isDefault'] as bool?,
      momoProvider: json['momoProvider'] as String?,
      momoNumber: json['momoNumber'] as String?,
      token: json['token'] as String?,
      DateTime.parse(json['createdAt'] as String),
      DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson(AddCardResponseData addCardResponseData) {
    return {
      'id': addCardResponseData.id,
      'userId': addCardResponseData.userId,
      'type': addCardResponseData.type,
      'cardType': addCardResponseData.cardType,
      'last4': addCardResponseData.last4,
      'expiryMonth': addCardResponseData.expiryMonth,
      'expiryYear': addCardResponseData.expiryYear,
      'token': addCardResponseData.token,
      'createdAt': addCardResponseData.createdAt,
      'updatedAt': addCardResponseData.updatedAt,
    };
  }

  String id;
  String userId;
  String type;
  String? cardType;
  String? last4;
  String? expiryMonth;
  String? expiryYear;
  String? momoProvider;
  String? momoNumber;
  String? token;
  bool? isDefault;
  DateTime createdAt;
  DateTime updatedAt;
}
