import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';

class CharityCampaignState {
  const CharityCampaignState({
    this.isLoading = true,
    this.campaign,
    this.packages = const [],
    this.selectedId,
    this.query = '',
    this.error,
  });

  final bool isLoading;
  final CharityCampaign? campaign;
  final List<CharityPackage> packages;

  /// A request funds exactly one package.
  final String? selectedId;
  final String query;
  final String? error;

  CharityPackage? get selected =>
      packages.where((item) => item.id == selectedId).firstOrNull;

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
    String? query,
    String? error,
    bool clearError = false,
  }) {
    return CharityCampaignState(
      isLoading: isLoading ?? this.isLoading,
      campaign: campaign ?? this.campaign,
      packages: packages ?? this.packages,
      selectedId: selectedId ?? this.selectedId,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
