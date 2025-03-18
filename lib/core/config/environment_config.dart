// ignore_for_file: sort_constructors_first

import 'dart:developer';

import 'package:freedom/core/config/api_constants.dart';

enum Environment { development, staging, production }

class EnvironmentConfig {
  EnvironmentConfig({
    required this.baseUrl,
    required this.appName,
    this.enableLogging = false,
    this.logEnvironment,
  });

  final String baseUrl;
  final String appName;
  final bool enableLogging;
  Function? logEnvironment;

  static EnvironmentConfig _instance = EnvironmentConfig(
    baseUrl: '',
    appName: '',
  );

  static void setEnvironment(Environment environment) {
    switch (environment) {
      case Environment.development:
        _instance = EnvironmentConfig(
          baseUrl: ApiConstants.baseUrl,
          appName: '[DEV] Freedom Driver',
          enableLogging: true,
          logEnvironment: _instance.logInUseEnvironment,
        );
      case Environment.staging:
        _instance = EnvironmentConfig(
          baseUrl: ApiConstants.baseUrl,
          appName: '[STG] Freedom Driver',
          enableLogging: true,
          logEnvironment: _instance.logInUseEnvironment,
        );
      case Environment.production:
        _instance = EnvironmentConfig(
          baseUrl: ApiConstants.baseUrl,
          appName: '[PROD] Freedom Driver',
          enableLogging: true,
          logEnvironment: _instance.logInUseEnvironment,
        );
        _instance.logInUseEnvironment();
    }
  }

  void logInUseEnvironment() {
    if (enableLogging && logEnvironment != null) {
      log('Environment: $appName');
    }
  }

  static EnvironmentConfig get instance {
    return _instance;
  }
}
