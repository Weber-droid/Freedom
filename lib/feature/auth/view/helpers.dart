class BaseValidator {
  static String? validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleanedNumber = val.replaceAll(RegExp(r'\D'), '');
    if (cleanedNumber.isEmpty) {
      return 'Please enter digits only';
    }

    if (cleanedNumber.length < 10) {
      return 'Phone number must be at least 10 digits long';
    }

    return null;
  }
}

class PhoneFormatter {
  static String formatPhoneNumber(String rawNumber, String countryCode) {
    // Remove non-digits
    String digits = rawNumber.replaceAll(RegExp(r'\D'), '');

    // If number starts with 0, remove the leading zero
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Ensure it doesn't already contain the country code
    if (digits.startsWith(countryCode.replaceAll('+', ''))) {
      return '+$digits';
    }

    return '$countryCode$digits';
  }
}
