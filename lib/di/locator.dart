import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void>locator()async{
  final freedomClient = BaseApiClients(
      baseUrl: EnvironmentConfig.instance.baseUrl);
  getIt.registerSingleton<BaseApiClients>(freedomClient);
}

