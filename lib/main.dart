import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'app/core/bootstrap/app_bootstrap.dart';
import 'app/core/config/app_config.dart';
import 'app/core/services/app_locale.dart';
import 'app/core/services/deep_link_service.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/translations/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await AppBootstrap.initialize();
  Get.find<DeepLinkService>().listen();
  runApp(const ZoovanaCharityApp());
}

class ZoovanaCharityApp extends StatelessWidget {
  const ZoovanaCharityApp({super.key, this.initialRoute = AppRoutes.splash});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      translations: AppTranslations(),
      locale: AppLocale.initial,
      fallbackLocale: const Locale('en'),
      supportedLocales: AppLocale.supported,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        // Text never renders below the design size (some phones are set to
        // smaller fonts), and very large system sizes are capped so layouts
        // don't break.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1.3,
            ),
          ),
          child: ColoredBox(
            color: AppColors.shell,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
