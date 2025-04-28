import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/location_search/data_sources/local_location_data_source.dart';
import 'package:freedom/feature/location_search/data_sources/location_remote_data_source.dart';
import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/location_search/use_cases/get_place_detail.dart';
import 'package:freedom/feature/location_search/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/location_search/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/location_search/use_cases/get_saved_location.dart';
import 'package:freedom/feature/location_search/use_cases/remove_location.dart';
import 'package:freedom/feature/location_search/use_cases/save_location.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> locator() async {
  log('api key:${dotenv.env['GOOGLE_MAPS_API_KEY']}');
  final freedomClient =
      BaseApiClients(baseUrl: EnvironmentConfig.instance.baseUrl);
  getIt
    ..registerSingleton<BaseApiClients>(freedomClient)
    ..registerLazySingleton(RegisterLocalDataSource.new)
    ..registerFactory<HomeCubit>(() => HomeCubit(repository: getIt()))
    ..registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
      ),
    )
    ..registerLazySingleton<LocationRemoteDataSource>(
      () => LocationRemoteDataSourceImpl(
        placesApi: getIt(),
      ),
    )
    ..registerLazySingleton(() => GetPlacePredictions(getIt()))
    ..registerLazySingleton(() => GetPlaceDetails(getIt()))
    ..registerLazySingleton(() => GetSavedLocations(getIt()))
    ..registerLazySingleton(() => GetRecentLocations(getIt()))
    ..registerLazySingleton(() => SaveLocation(getIt()))
    ..registerLazySingleton(() => RemoveLocation(getIt()))
    ..registerLazySingleton(() => ClearRecentLocations(getIt()))
    ..registerLazySingleton(
      () => GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']),
    );
  final sharedPreferences = await SharedPreferences.getInstance();

  getIt
    ..registerLazySingleton(() => sharedPreferences)
    ..registerLazySingleton<LocationLocalDataSource>(
      () => LocationLocalDataSourceImpl(prefs: getIt()),
    );
}
