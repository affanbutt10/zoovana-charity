import 'package:get/get.dart';

import '../core/theme/app_motion.dart';
// Out of charity scope: adoption, shelters, pets and pet-care services. The
// screens are kept but no longer registered, so nothing can navigate to them.
// import '../modules/adoption/screens/adoption_screens.dart';
import '../modules/account/screens/account_screens.dart';
import '../modules/charity/bindings/charity_bindings.dart';
import '../modules/charity/screens/charity_campaign_screen.dart';
import '../modules/charity/screens/charity_checkout_screen.dart';
// import '../modules/charity/screens/charity_home_screen.dart';
import '../modules/charity/screens/charity_setup_screens.dart';
// import '../modules/charity/screens/shelter_screens.dart';
import '../modules/auth/screens/auth_screens.dart';
// Out of charity scope: the local profile step after sign-up.
// import '../modules/auth/screens/setup_profile_screen.dart';
import '../modules/home/screens/customer_shell_screen.dart';
import '../modules/notifications/screens/notifications_screen.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/operator_access/bindings/operator_access_bindings.dart';
import '../modules/operator_access/screens/operator_access_screens.dart';
import '../modules/provider/bindings/provider_bindings.dart';
import '../modules/provider/screens/provider_screens.dart';
// import '../modules/services/screens/service_screens.dart';
import '../modules/history/bindings/donation_history_binding.dart';
import '../modules/history/bindings/request_details_binding.dart';
import '../modules/history/screens/donation_history_screen.dart';
import '../modules/history/screens/request_details_screen.dart';
import '../modules/onboarding/screens/onboarding_screen.dart';
// import '../modules/pets/screens/pet_screens.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/screens/splash_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  // Root screens reached with offAllNamed fade through rather than sliding
  // in, since there is no previous page for them to slide over.
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashScreen.new,
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: OnboardingScreen.new,
      transition: Transition.fadeIn,
      transitionDuration: AppMotion.slow,
    ),
    GetPage(
      name: AppRoutes.auth,
      page: AuthLandingScreen.new,
      transition: Transition.fadeIn,
      transitionDuration: AppMotion.slow,
    ),
    GetPage(name: AppRoutes.login, page: LoginScreen.new),
    GetPage(name: AppRoutes.signup, page: SignupScreen.new),
    GetPage(name: AppRoutes.recoverPassword, page: RecoverPasswordScreen.new),
    // GetPage(name: AppRoutes.setupProfile, page: SetupProfileScreen.new),
    GetPage(
      name: AppRoutes.home,
      page: CustomerShellScreen.new,
      transition: Transition.fadeIn,
      transitionDuration: AppMotion.slow,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: NotificationsScreen.new,
      binding: NotificationsBinding(),
    ),
    // Out of charity scope: the hub only chose between donating and adopting,
    // and the support screen between street animals and shelters. The donate
    // flow now starts at the city choice.
    // GetPage(
    //   name: AppRoutes.charity,
    //   page: CharityHomeScreen.new,
    //   binding: CharityHomeBinding(),
    // ),
    // GetPage(name: AppRoutes.charitySupport, page: CharitySupportScreen.new),
    GetPage(name: AppRoutes.charityLocation, page: CharityLocationScreen.new),
    GetPage(name: AppRoutes.charityAnimal, page: CharityAnimalScreen.new),
    // Out of charity scope: shelter donations and ratings.
    // GetPage(name: AppRoutes.shelterHub, page: ShelterHubScreen.new),
    // GetPage(name: AppRoutes.shelters, page: SheltersScreen.new),
    // GetPage(
    //   name: AppRoutes.shelterCampaigns,
    //   page: ShelterCampaignsScreen.new,
    // ),
    // GetPage(name: AppRoutes.shelterDetails, page: ShelterDetailsScreen.new),
    // GetPage(name: AppRoutes.shelterInfo, page: ShelterInfoScreen.new),
    // GetPage(name: AppRoutes.ratings, page: RatingsScreen.new),
    GetPage(
      name: AppRoutes.campaign,
      page: CharityCampaignScreen.new,
      binding: CharityCampaignBinding(),
      transitionDuration: AppMotion.pageTransition,
    ),
    GetPage(
      name: AppRoutes.checkout,
      page: CharityCheckoutScreen.new,
      binding: CharityCheckoutBinding(),
      transitionDuration: AppMotion.pageTransition,
    ),
    GetPage(
      name: AppRoutes.history,
      page: DonationHistoryScreen.new,
      binding: DonationHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.requestDetails,
      page: RequestDetailsScreen.new,
      binding: RequestDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.unsupported,
      page: UnsupportedAccountScreen.new,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.operatorApply,
      page: OperatorApplicationScreen.new,
      binding: OperatorApplicationBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.operatorStatus,
      page: OperatorStatusScreen.new,
      binding: OperatorStatusBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.providerHome,
      page: ProviderShellScreen.new,
      binding: OperatorShellBinding(),
      transition: Transition.fadeIn,
      transitionDuration: AppMotion.slow,
    ),
    GetPage(
      name: AppRoutes.providerJobs,
      page: ProviderJobsScreen.new,
      binding: OperatorShellBinding(),
    ),
    GetPage(
      name: AppRoutes.providerJobDetails,
      page: ProviderJobDetailsScreen.new,
      binding: OperatorTaskBinding(),
    ),
    GetPage(
      name: AppRoutes.providerPayouts,
      page: OperatorPayoutsScreen.new,
      binding: OperatorPayoutsBinding(),
    ),
    // Out of charity scope: adoption and pets.
    // GetPage(name: AppRoutes.adoption, page: AdoptionBrowseScreen.new),
    // GetPage(
    //   name: AppRoutes.adoptionShelter,
    //   page: AdoptionShelterScreen.new,
    // ),
    // GetPage(
    //   name: AppRoutes.adoptionDetails,
    //   page: AdoptionPetDetailsScreen.new,
    // ),
    // GetPage(
    //   name: AppRoutes.adoptionApply,
    //   page: AdoptionApplicationScreen.new,
    // ),
    // GetPage(name: AppRoutes.addPet, page: AddPetScreen.new),
    // GetPage(name: AppRoutes.petDetails, page: PetDetailsScreen.new),
    GetPage(name: AppRoutes.profileDetails, page: ProfileDetailsScreen.new),
    GetPage(name: AppRoutes.orders, page: AccountCollectionScreen.new),
    // Out of charity scope: addresses, appointments, payments and favorites.
    // GetPage(name: AppRoutes.addresses, page: AccountCollectionScreen.new),
    // GetPage(name: AppRoutes.appointments, page: AccountCollectionScreen.new),
    // GetPage(name: AppRoutes.payments, page: AccountCollectionScreen.new),
    // GetPage(name: AppRoutes.favorites, page: AccountCollectionScreen.new),
    // Out of charity scope: pet-care services and bookings.
    // GetPage(name: AppRoutes.services, page: ServicesScreen.new),
    // GetPage(name: AppRoutes.serviceDetails, page: ServiceDetailsScreen.new),
    // GetPage(name: AppRoutes.bookService, page: BookServiceScreen.new),
  ];
}
