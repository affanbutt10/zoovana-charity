import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/errors/app_error.dart';
import 'package:zoovana_charity/app/core/errors/app_error_mapper.dart';
import 'package:zoovana_charity/app/core/services/credential_store.dart';
import 'package:zoovana_charity/app/data/datasources/auth_data_source.dart';
import 'package:zoovana_charity/app/data/models/charity_campaign.dart';
import 'package:zoovana_charity/app/data/models/charity_package.dart';
import 'package:zoovana_charity/app/data/models/charity_request_detail.dart';
import 'package:zoovana_charity/app/data/models/charity_session.dart';
import 'package:zoovana_charity/app/data/models/donation_receipt.dart';
import 'package:zoovana_charity/app/data/models/feeder_models.dart';
import 'package:zoovana_charity/app/data/repositories/session_repository.dart';
import 'package:zoovana_charity/app/routes/app_routes.dart';
import 'package:zoovana_charity/app/routes/shell_router.dart';

/// Payloads copied from the mobile integration guide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing', () {
    test('login result carries mode, profile and tokens', () {
      final result = AuthResult.fromJson(const {
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': 3600,
        'account_type': 'staff',
        'roles': ['feeder'],
        'app_mode': 'operator',
        'user': {'id': 'u1', 'email': 'p@example.com', 'full_name': 'Op'},
        'feeder_profile': {'id': 'f1', 'verification_status': 'approved'},
        'device_id': 'd1',
      });
      expect(result.accessToken, 'a');
      expect(result.session.appMode, AppMode.operator);
      expect(result.session.verificationStatus, VerificationStatus.approved);
      expect(result.session.deviceId, 'd1');
    });

    test('programme, package and money', () {
      final programme = CharityCampaign.fromApi(const {
        'id': 'p1',
        'code': 'MAKKAH-CATS',
        'city_code': 'makkah',
        'city_name_en': 'Makkah',
        'city_name_ar': 'مكة',
        'animal_type': 'cat',
        'title_en': 'Feed cats',
      });
      expect(programme.animalKind, AnimalKind.cat);
      expect(programme.city, 'Makkah');

      final unknown = CharityCampaign.fromApi(const {'animal_type': 'turtle'});
      expect(unknown.animalKind, AnimalKind.other);
      expect(unknown.animal, 'Turtle');

      final package = CharityPackage.fromApi(const {
        'id': 'k1',
        'name_en': 'Fifty meals',
        'price': '75.00',
        'currency': 'SAR',
        'meal_count': 50,
        'is_popular': true,
      });
      expect(package.price, '75.00');
      expect(package.priceLabel, '75 SAR');
      expect(package.recommended, isTrue);
      expect(formatMoney('92.50', 'SAR'), '92.5 SAR');
    });

    test('request detail with approved proof', () {
      final detail = CharityRequestDetail.fromApi(const {
        'id': 'r1',
        'reference': 'ZF-1',
        'status': 'completed',
        'status_label': 'Feeding completed',
        'status_labels': {'en': 'Feeding completed', 'ar': 'اكتمل الإطعام'},
        'program': {'id': 'p1', 'title': 'Feed cats', 'city': 'Makkah'},
        'package': {'id': 'k1', 'name': 'Fifty meals', 'meal_count': 50},
        'amount': '75.00',
        'currency': 'SAR',
        'created_at': '2026-10-27T10:00:00+03:00',
        'timeline': [
          {
            'status': 'paid',
            'label': 'Payment received',
            'occurred_at': '2026-10-27T10:01:00+03:00',
          },
        ],
        'proof': {
          'id': 'pr1',
          'approved_at': '2026-10-27T12:00:00+03:00',
          'approximate_zone': 'Al-Aziziyah',
          'meal_count': 50,
          'food_quantity_grams': 3000,
          'animals_fed_estimate': 35,
          'media': [
            {'id': 'm1', 'media_type': 'video', 'url': 'https://x/v.mp4'},
          ],
        },
      });
      expect(detail.status, DonationStatus.completed);
      expect(detail.request.label, 'Feeding completed');
      expect(detail.request.mealCount, 50);
      expect(detail.timeline.single.label, 'Payment received');
      expect(detail.proof!.media.single.isVideo, isTrue);
    });

    test('an unknown request status keeps the API label', () {
      final request = DonationReceipt.fromApi(const {
        'status': 'on_hold',
        'status_label': 'On hold',
      });
      expect(request.status, DonationStatus.unknown);
      expect(request.label, 'On hold');
    });

    test('task buttons come from allowed_actions', () {
      final task = FeederTask.fromJson(const {
        'id': 'a1',
        'status': 'proof_rejected',
        'food_budget': '60.00',
        'feeder_fee': '15.00',
        'currency': 'SAR',
        'food_quantity_grams': 3000,
        'zone': {'id': 'z', 'name_en': 'Al-Aziziyah'},
        'allowed_actions': ['upload_media', 'submit_proof', 'feeding'],
        'proof_rejection_reason': 'Clearer photo, please.',
        'can_resubmit': true,
        'feeding_location': null,
        'purchase_requirements': <Object>[],
      });
      expect(task.status, TaskStatus.proofRejected);
      expect(task.can(TaskAction.submitProof), isTrue);
      expect(task.can(TaskAction.accept), isFalse);
      expect(task.foodLabel, '3 kg');
      expect(task.feedingLocation, isNull);
      expect(task.zoneName, 'Al-Aziziyah');
    });

    test('dashboard keeps payouts per currency', () {
      final summary = FeederDashboard.fromJson(const {
        'eligible_payout_amount': null,
        'currency': null,
        'eligible_payouts_by_currency': {'SAR': '30.00', 'USD': '8.00'},
      });
      expect(summary.eligiblePayoutLabel, '30 SAR · 8 USD');
    });

    test('error envelope exposes code, details and fields', () {
      final error = AppErrorMapper.fromResponse(422, const {
        'success': false,
        'code': 'validation_error',
        'message': 'Please check the submitted fields',
        'details': {
          'fields': {'email': 'value is not a valid email address'},
        },
      });
      expect(error.code, ApiErrorCode.validationError);
      expect(error.fieldErrors['email'], 'value is not a valid email address');
      expect(error.type, AppErrorType.validation);
    });
  });

  group('shell routing (guide §3.2)', () {
    CharitySession session(AppMode mode, {VerificationStatus? status}) =>
        CharitySession(
          appMode: mode,
          user: const SessionUser(id: 'u', email: 'e'),
          feederProfileId: status == null ? null : 'f',
          verificationStatus: status,
        );

    test('maps every mode and verification status', () {
      expect(ShellRouter.routeFor(session(AppMode.donor)), AppRoutes.home);
      expect(
        ShellRouter.routeFor(session(AppMode.unsupported)),
        AppRoutes.unsupported,
      );
      expect(
        ShellRouter.routeFor(session(AppMode.operator)),
        AppRoutes.operatorApply,
      );
      for (final status in [
        VerificationStatus.pendingReview,
        VerificationStatus.rejected,
        VerificationStatus.suspended,
      ]) {
        expect(
          ShellRouter.routeFor(session(AppMode.operator, status: status)),
          AppRoutes.operatorStatus,
        );
      }
      expect(
        ShellRouter.routeFor(
          session(AppMode.operator, status: VerificationStatus.approved),
        ),
        AppRoutes.providerHome,
      );
    });
  });

  group('session restore (guide §3.3)', () {
    Future<SessionRepository> repository(AppError failure) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final credentials = DemoCredentialStore(preferences);
      await credentials.saveTokens(access: 'a', refresh: 'r');
      return SessionRepository(
        preferences,
        credentials,
        _FailingSession(SeedAuthDataSource(preferences), failure),
      );
    }

    test('403 insufficient_role opens the unsupported screen', () async {
      final session = await repository(
        const AppError(
          type: AppErrorType.server,
          statusCode: 403,
          code: ApiErrorCode.insufficientRole,
          message: 'No access',
        ),
      );
      expect(await session.restore(), isA<SessionUnsupported>());
      expect(session.hasActiveSession, isTrue);
    });

    test('503 keeps the login and asks to retry', () async {
      final session = await repository(
        const AppError(
          type: AppErrorType.server,
          statusCode: 503,
          code: ApiErrorCode.sessionContextUnavailable,
          message: 'Try again',
        ),
      );
      expect(await session.restore(), isA<SessionUnavailable>());
      expect(session.hasActiveSession, isTrue);
    });

    test('401 invalid_credentials clears the tokens', () async {
      final session = await repository(
        const AppError(
          type: AppErrorType.unauthorized,
          statusCode: 401,
          code: ApiErrorCode.invalidCredentials,
          message: 'Sign in again',
        ),
      );
      expect(await session.restore(), isA<SessionSignedOut>());
      expect(session.hasActiveSession, isFalse);
    });
  });
}

class _FailingSession implements AuthDataSource {
  _FailingSession(this._delegate, this._failure);

  final AuthDataSource _delegate;
  final AppError _failure;

  @override
  Future<CharitySession> session() => Future.error(_failure);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceId,
    required String locale,
    String? fcmToken,
  }) => _delegate.login(
    email: email,
    password: password,
    deviceId: deviceId,
    locale: locale,
  );
}
