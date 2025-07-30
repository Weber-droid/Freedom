import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/config/environment_config.dart';
import 'package:freedom/core/services/app_restoration_manager.dart';
import 'package:freedom/core/services/life_cycle_manager.dart';
import 'package:freedom/core/services/real_time_driver_tracking.dart';
import 'package:freedom/core/services/map_services.dart';
import 'package:freedom/core/services/push_notification_service/push_nofication_service.dart';
import 'package:freedom/core/services/ride_persistence_service.dart';
import 'package:freedom/core/services/route_animation_services.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/core/services/socket_service.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/data_sources/delivery_data_source.dart';
import 'package:freedom/feature/home/data_sources/local_location_data_source.dart';
import 'package:freedom/feature/home/data_sources/location_remote_data_source.dart';
import 'package:freedom/feature/home/data_sources/ride_data_source.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/repository/delivery_repository.dart';
import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/ride_request_repository.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/home/use_cases/clear_recent_location.dart';
import 'package:freedom/feature/home/use_cases/get_place_detail.dart';
import 'package:freedom/feature/home/use_cases/get_place_prediction.dart';
import 'package:freedom/feature/home/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/home/use_cases/get_saved_location.dart';
import 'package:freedom/feature/home/use_cases/remove_location.dart';
import 'package:freedom/feature/home/use_cases/save_location.dart';
import 'package:freedom/feature/message_driver/cubit/in_app_message_cubit.dart';
import 'package:freedom/feature/message_driver/remote_data_source/message_remote_data_source.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> locator() async {
  log('api key:${dotenv.env['GOOGLE_MAPS_API_KEY']}');
  final freedomClient = BaseApiClients(
    baseUrl: EnvironmentConfig.instance.baseUrl,
  );
  getIt
    ..registerSingleton<BaseApiClients>(freedomClient)
    ..registerLazySingleton(RegisterLocalDataSource.new)
    ..registerFactory<HomeCubit>(
      () => HomeCubit(
        repository: getIt(),
        rideRequestRepository: getIt(),
        animationService: getIt(),
        routeService: getIt(),
      ),
    )
    ..registerFactory(
      () => RideCubit(
        rideRequestRepository: getIt(),
        animationService: getIt(),
        routeService: getIt(),
      ),
    )
    ..registerFactory<DeliveryCubit>(() => DeliveryCubit(getIt(), getIt()))
    ..registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
      ),
    )
    ..registerFactory(
      () => InAppMessageCubit(
        messageRemoteDataSource: getIt(),
        socketService: getIt(),
      ),
    )
    ..registerLazySingleton(
      () => DeliveryRepositoryImpl(remoteDataSource: getIt()),
    )
    ..registerLazySingleton<MessageRemoteDataSource>(
      () => MessageRemoteDataSource(client: getIt()),
    )
    ..registerLazySingleton<RideRequestRepository>(
      () => RideRequestRepositoryImpl(remoteDataSource: getIt()),
    )
    ..registerLazySingleton<LocationRemoteDataSource>(
      () => LocationRemoteDataSourceImpl(placesApi: getIt()),
    )
    ..registerLazySingleton<RideRemoteDataSource>(
      () => RideRemoteDataSourceImpl(client: getIt()),
    )
    ..registerLazySingleton<IDeliveryRemoteDataSource>(
      DeliveryDataSourceImpl.new,
    )
    ..registerLazySingleton<RealTimeDriverTrackingService>(
      () => RealTimeDriverTrackingService(),
    )
    ..registerLazySingleton<RidePersistenceService>(
      () => RidePersistenceService(getIt()),
    )
    ..registerLazySingleton(() => GetPlacePredictions(getIt()))
    ..registerLazySingleton(() => GetPlaceDetails(getIt()))
    ..registerLazySingleton(() => GetSavedLocations(getIt()))
    ..registerLazySingleton(() => GetRecentLocations(getIt()))
    ..registerLazySingleton(() => SaveLocation(getIt()))
    ..registerLazySingleton(() => RemoveLocation(getIt()))
    ..registerLazySingleton(() => ClearRecentLocations(getIt()))
    ..registerLazySingleton(MapService.new)
    ..registerLazySingleton<SocketService>(SocketService.new)
    ..registerLazySingleton<PushNotificationService>(
      () => PushNotificationService.instance,
    )
    ..registerLazySingleton<RideRestorationManager>(
      () => RideRestorationManager(
        persistenceService: getIt(),
        rideRepository: getIt(),
      ),
    )
    ..registerLazySingleton<AppLifecycleManager>(
      () => AppLifecycleManager(
        persistenceService: getIt(),
        restorationManager: getIt(),
      ),
    )
    ..registerLazySingleton(
      () => GoogleMapsPlaces(apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']),
    )
    ..registerLazySingleton<RouteService>(RouteService.new)
    ..registerLazySingleton<RouteAnimationService>(RouteAnimationService.new);
  final sharedPreferences = await SharedPreferences.getInstance();

  getIt
    ..registerLazySingleton(() => sharedPreferences)
    ..registerLazySingleton<LocationLocalDataSource>(
      () => LocationLocalDataSourceImpl(prefs: getIt()),
    );
}
