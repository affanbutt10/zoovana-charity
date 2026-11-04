import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../apis/core/api_client.dart';
import '../../data/datasources/auth_data_source.dart';
import '../../data/datasources/charity_data_source.dart';
import '../../data/datasources/feeder_data_source.dart';
import '../../data/datasources/notification_data_source.dart';
import '../../data/models/charity_session.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/charity_repository.dart';
// Out of charity scope: pets and appointments.
// import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/feeder_repository.dart';
import '../../data/repositories/notification_repository.dart';
// import '../../data/repositories/pet_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/shell_router.dart';
import '../config/app_config.dart';
import '../services/cache_service.dart';
import '../services/credential_store.dart';
import '../services/deep_link_service.dart';

abstract final class AppBootstrap {
  /// Registers app-wide services. With [useRemoteApi] off (the default until
  /// the service URLs are configured) the seed data sources are used.
  static Future<void> initialize({bool? useRemoteApi}) async {
    final remote = useRemoteApi ?? AppConfig.useRemoteApi;
    final preferences = await SharedPreferences.getInstance();
    final cache = CacheService(preferences);
    final credentials = remote
        ? SecureCredentialStore(preferences)
        : DemoCredentialStore(preferences);
    final api = ApiClient(credentials);

    Get.put<SharedPreferences>(preferences, permanent: true);
    Get.put<CacheService>(cache, permanent: true);
    Get.put<ApiClient>(api, permanent: true);

    final seedAuth = SeedAuthDataSource(preferences);
    final session = SessionRepository(
      preferences,
      credentials,
      remote ? RemoteAuthDataSource(api) : seedAuth,
    );
    await session.initialize();
    api
      ..tokenRefresher = session.refreshAccessToken
      ..onSessionExpired = () {
        if (Get.currentRoute != AppRoutes.auth) {
          Get.offAllNamed<void>(AppRoutes.auth);
        }
      };
    // A refresh can change the account's mode, e.g. an operator approved
    // while the app was closed.
    session.onSessionChanged = (current) {
      if (Get.currentRoute != ShellRouter.routeFor(current)) {
        ShellRouter.open(current);
      }
    };
    Get.put<SessionRepository>(session, permanent: true);
    Get.put<DeepLinkService>(DeepLinkService(session), permanent: true);

    // Get.put<PetRepository>(PetRepository(preferences), permanent: true);
    Get.put<AccountRepository>(AccountRepository(preferences), permanent: true);
    Get.put<CommunityRepository>(
      CommunityRepository(preferences),
      permanent: true,
    );
    // Get.put<AppointmentRepository>(
    //   AppointmentRepository(preferences),
    //   permanent: true,
    // );

    Get.put<CharityRepository>(
      CharityRepository(
        remote ? RemoteCharityDataSource(api) : SeedCharityDataSource(cache),
        cache,
      ),
      permanent: true,
    );
    Get.put<FeederRepository>(
      FeederRepository(
        remote
            ? RemoteFeederDataSource(api)
            : SeedFeederDataSource(onApplied: seedAuth.markApplied),
      ),
      permanent: true,
    );
    Get.put<NotificationRepository>(
      NotificationRepository(
        remote
            ? RemoteNotificationDataSource(api)
            : SeedNotificationDataSource(
                operator: () => session.current?.appMode == AppMode.operator,
              ),
      ),
      permanent: true,
    );
  }
}
