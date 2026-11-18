import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/apis/core/api_client.dart';
import 'package:zoovana_charity/app/core/errors/app_error.dart';
import 'package:zoovana_charity/app/core/services/cache_service.dart';
import 'package:zoovana_charity/app/core/services/credential_store.dart';
import 'package:zoovana_charity/app/data/datasources/charity_data_source.dart';
import 'package:zoovana_charity/app/data/models/charity_campaign.dart';
import 'package:zoovana_charity/app/data/models/charity_package.dart';
import 'package:zoovana_charity/app/data/models/charity_request_detail.dart';
import 'package:zoovana_charity/app/data/repositories/charity_repository.dart';
import 'package:zoovana_charity/app/modules/charity/controllers/charity_checkout_controller.dart';
import 'package:zoovana_charity/app/modules/charity/controllers/charity_campaign_controller.dart';
import 'package:zoovana_charity/app/modules/charity/models/charity_campaign_state.dart';
import 'package:zoovana_charity/app/modules/charity/models/charity_checkout_state.dart';

const campaign = CharityCampaign(
  id: 'p',
  title: 'Cats',
  city: 'Makkah',
  animal: 'Cats',
  animalKind: AnimalKind.cat,
  description: '',
);
const small = CharityPackage(
  id: 's',
  name: 'Small',
  price: '30',
  impact: '',
  food: '',
);
const medium = CharityPackage(
  id: 'm',
  name: 'Medium',
  price: '75',
  impact: '',
  food: '',
);
const lines = [
  DonationLine(item: small, quantity: 2),
  DonationLine(item: medium, quantity: 1),
];
Map<String, dynamic> quoteData(List<Map<String, dynamic>> items) => {
  'items': [
    for (final i in items)
      {
        ...i,
        'name': i['package_id'],
        'unit_amount_minor': 3000,
        'currency': 'SAR',
      },
  ],
  'amount_minor': 13500,
  'currency': 'SAR',
  'limits': {'max_item_quantity': 7, 'max_line_items': 3},
};
Map<String, dynamic> requestData({String payment = 'unpaid'}) => {
  'id': 'r1',
  'reference': 'FR-1',
  'status': payment == 'paid' ? 'paid' : 'draft',
  'payment_status': payment,
  'amount': '135.00',
  'amount_minor': 13500,
  'currency': 'SAR',
  'program': {'id': 'p', 'title': 'Cats', 'city': 'Makkah'},
  'created_at': '2026-11-14T10:00:00Z',
  'total_quantity': 3,
  'items': [
    {
      'package_id': 's',
      'name': 'Small',
      'quantity': 2,
      'unit_amount': '30.00',
      'currency': 'SAR',
    },
  ],
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CharityRepository repo;
  late ApiClient client;
  late List<RequestOptions> calls;
  late FutureOr<Map<String, dynamic>> Function(RequestOptions) respond;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    client = ApiClient(DemoCredentialStore(prefs));
    calls = [];
    client.feeding.interceptors.clear();
    respond = (o) {
      if (o.path.endsWith('/quote')) {
        return quoteData(
          List<Map<String, dynamic>>.from(o.data['items'] as List),
        );
      }
      if (o.path.endsWith('/checkout-contact')) {
        return {
          'full_name': 'Sara Ahmed',
          'email': 'sara@example.com',
          'phone_number': '',
          'missing': [],
        };
      }
      if (o.path.endsWith('/payment-methods')) {
        return {
          'provider': 'moyasar',
          'currencies': ['SAR'],
          'methods': [
            {
              'id': 'card',
              'provider_method': 'creditcard',
              'platforms': ['android', 'ios'],
            },
            {
              'id': 'apple_pay',
              'provider_method': 'applepay',
              'platforms': ['ios'],
            },
            {
              'id': 'google_pay',
              'platforms': ['android'],
            },
            {
              'id': 'stc_pay',
              'provider_method': 'stcpay',
              'platforms': ['android', 'ios'],
            },
          ],
          'saved_cards': {'supported': false},
        };
      }
      if (o.path.endsWith('/payment-intent')) {
        return {
          'provider': 'mock',
          'client_payload': {'checkout_url': 'https://example.test/pay'},
        };
      }
      return requestData(
        payment:
            o.method == 'GET' &&
                calls.any((r) => r.path.endsWith('/payment-intent'))
            ? 'paid'
            : 'unpaid',
      );
    };
    client.feeding.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          calls.add(o);
          try {
            final data = await respond(o);
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {'success': true, 'data': data},
              ),
            );
          } catch (e) {
            h.reject(
              DioException(
                requestOptions: o,
                error: e,
                type: DioExceptionType.connectionError,
              ),
            );
          }
        },
      ),
    );
    repo = CharityRepository(
      RemoteCharityDataSource(client),
      CacheService(prefs),
    );
  });
  CharityCheckoutController controller() {
    final c = CharityCheckoutController(
      repository: repo,
      paymentLauncher: (_, _) async {},
      pollInterval: Duration.zero,
    );
    c.state = const CharityCheckoutState(
      campaign: campaign,
      package: small,
      lines: lines,
    );
    return c;
  }

  test(
    'quotes basket wire body and consumes server totals and limits',
    () async {
      final q = await repo.quoteBasket(lines);
      expect(calls.single.path, '/requests/quote');
      expect(calls.single.data, {
        'items': [
          {'package_id': 's', 'quantity': 2},
          {'package_id': 'm', 'quantity': 1},
        ],
      });
      expect(q.label, '135.00 SAR');
      expect(q.maxQuantity, 7);
      expect(q.maxLines, 3);
      expect(q.matches(lines), isTrue);
    },
  );
  test(
    'basket creates one request, launches intent and only accepts server-paid state',
    () async {
      final c = controller();
      await c.loadCheckout();
      expect(c.ready, isTrue);
      expect(c.phoneController.text, isEmpty);
      c.feedingNotesController.text = 'Near the park';
      await c.submit();
      final creates = calls.where((o) => o.path == '/requests').toList();
      expect(creates.length, 1);
      expect(creates.single.data['items'], hasLength(2));
      expect(creates.single.data.containsKey('package_id'), isFalse);
      expect(creates.single.data['feeding_notes'], 'Near the park');
      expect(creates.single.headers['Idempotency-Key'], isNotEmpty);
      expect(calls.any((o) => o.path.endsWith('/payment-intent')), isTrue);
      expect(c.state!.receipt!.paymentStatus, 'paid');
      c.onClose();
    },
  );
  test(
    'network retry reuses UUID and changed details get a fresh key',
    () async {
      final original = respond;
      respond = (o) {
        if (o.path == '/requests') {
          throw const AppError(type: AppErrorType.network, message: 'timeout');
        }
        return original(o);
      };
      final c = controller();
      await c.loadCheckout();
      await c.submit();
      final first = c.attemptKey;
      await c.submit();
      expect(c.attemptKey, first);
      c.feedingNotesController.text = 'Changed';
      await c.submit();
      expect(c.attemptKey, isNot(first));
      final keys = calls
          .where((o) => o.path == '/requests')
          .map((o) => o.headers['Idempotency-Key'])
          .toList();
      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[0]));
      c.onClose();
    },
  );
  test(
    'provider return without verified funding stays unpaid and retries reuse draft',
    () async {
      final original = respond;
      respond = (o) {
        if (o.path == '/requests/r1') return requestData();
        return original(o);
      };
      final c = controller();
      await c.loadCheckout();
      await c.submit();
      expect(c.state!.receipt!.paymentStatus, 'unpaid');
      expect(c.state!.receipt!.status.isUnpaid, isTrue);
      await c.submit();
      expect(calls.where((o) => o.path == '/requests'), hasLength(1));
      expect(
        calls.where((o) => o.path.endsWith('/payment-intent')),
        hasLength(2),
      );
      c.onClose();
    },
  );
  test(
    'payment retry checks webhook state before opening another intent',
    () async {
      final original = respond;
      respond = (o) {
        if (o.path == '/requests/r1') return requestData(payment: 'paid');
        return original(o);
      };
      final c = controller();
      await c.loadCheckout();
      await c.submit();
      expect(c.state!.receipt!.paymentStatus, 'paid');
      expect(calls.where((o) => o.path.endsWith('/payment-intent')), isEmpty);
      c.onClose();
    },
  );
  test(
    'live PKR quote with SAR-only payment methods blocks request submission',
    () async {
      final original = respond;
      respond = (o) async {
        final data = await original(o);
        if (o.path.endsWith('/quote')) return {...data, 'currency': 'PKR'};
        return data;
      };
      final c = controller();
      await c.loadCheckout();
      expect(c.state!.quote!.currency, 'PKR');
      expect(c.ready, isFalse);
      await c.submit();
      expect(calls.where((o) => o.path == '/requests'), isEmpty);
      c.onClose();
    },
  );
  test(
    'method filtering hides Apple Pay on Android and Google Pay everywhere',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final c = controller();
      await c.loadCheckout();
      expect(c.availableMethods.map((m) => m.id), ['card', 'stc_pay']);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(c.availableMethods.map((m) => m.id), [
        'card',
        'apple_pay',
        'stc_pay',
      ]);
      debugDefaultTargetPlatformOverride = null;
      c.onClose();
    },
  );
  test(
    'late quote never replaces latest basket and limits cap stepper',
    () async {
      final waiting = Completer<Map<String, dynamic>>();
      final original = respond;
      var quotes = 0;
      respond = (o) {
        if (o.path.endsWith('/quote') && quotes++ == 0) return waiting.future;
        return original(o);
      };
      final c = CharityCampaignController(repository: repo);
      c.state = const CharityCampaignState(
        isLoading: false,
        campaign: campaign,
        packages: [small, medium],
        quantities: {'s': 1},
      );
      final first = c.refreshQuote();
      await Future<void>.delayed(Duration.zero);
      c.setQuantity(small, 2);
      await c.refreshQuote();
      waiting.complete(
        quoteData([
          {'package_id': 's', 'quantity': 1},
        ]),
      );
      await first;
      expect(c.quote!.items.single['quantity'], 2);
      expect(c.maxQuantity, 7);
      c.setQuantity(small, 999);
      expect(c.state.quantityFor('s'), 7);
      c.onClose();
    },
  );
  test(
    'detail uses unit amount, nullable metrics, actual time, zone and server stage states',
    () {
      final d = CharityRequestDetail.fromApi({
        ...requestData(),
        'fed_at': '2026-11-14T10:05:00Z',
        'approved_at': '2026-11-14T11:00:00Z',
        'zone': {'name': 'Aziziyah'},
        'feeding_notes': 'Park',
        'progress': {
          'stages': [
            {
              'key': 'created',
              'label': 'Created',
              'state': 'done',
              'occurred_at': null,
            },
            {
              'key': 'feeding',
              'label': 'Feeding',
              'state': 'current',
              'occurred_at': '2026-11-14T11:00:00Z',
            },
          ],
        },
        'proof': {
          'meal_count': null,
          'food_quantity_grams': null,
          'animals_fed_estimate': null,
          'media': [
            {
              'media_type': 'video',
              'url': 'https://example.test/v.mp4',
              'thumbnail_url': 'https://example.test/poster.jpg',
            },
          ],
        },
      });
      expect(d.items.single.unitAmount, '30.00');
      expect(d.items.single.quantity, 2);
      expect(d.zoneName, 'Aziziyah');
      expect(d.feedingAt!.toUtc().hour, 10);
      expect(d.proof!.mealCount, isNull);
      expect(d.progress!.stages.last.occurredAt, isNull);
      expect(d.proof!.media.single.isVideo, isTrue);
      expect(d.proof!.media.single.thumbnailUrl, endsWith('poster.jpg'));
    },
  );
}
