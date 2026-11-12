import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';

class CharityCampaignState {
  const CharityCampaignState({
    this.isLoading = true,
    this.campaign,
    this.packages = const [],
    this.selectedId,
    this.quantities = const {},
    this.query = '',
    this.error,
  });

  final bool isLoading;
  final CharityCampaign? campaign;
  final List<CharityPackage> packages;

  final String? selectedId;
  final Map<String, int> quantities;
  final String query;
  final String? error;

  List<DonationLine> get lines => [
    for (final item in packages)
      if ((quantities[item.id] ??
              (item.id == selectedId && quantities.isEmpty ? 1 : 0)) >
          0)
        DonationLine(item: item, quantity: quantities[item.id] ?? 1),
  ];
  CharityPackage? get selected => lines.firstOrNull?.item;
  int quantityFor(String id) =>
      lines.where((l) => l.item.id == id).firstOrNull?.quantity ?? 0;

  List<CharityPackage> get visiblePackages => packages
      .where(
        (item) => item.name.toLowerCase().contains(query.trim().toLowerCase()),
      )
      .toList(growable: false);

  CharityCampaignState copyWith({
    bool? isLoading,
    CharityCampaign? campaign,
    List<CharityPackage>? packages,
    String? selectedId,
    Map<String, int>? quantities,
    bool clearSelection = false,
    String? query,
    String? error,
    bool clearError = false,
  }) {
    return CharityCampaignState(
      isLoading: isLoading ?? this.isLoading,
      campaign: campaign ?? this.campaign,
      packages: packages ?? this.packages,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      quantities: quantities ?? this.quantities,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
