import '../../../data/models/charity_campaign.dart';

class CharityHomeState {
  const CharityHomeState({
    this.isLoading = true,
    this.campaigns = const [],
    this.error,
  });

  final bool isLoading;
  final List<CharityCampaign> campaigns;
  final String? error;

  CharityHomeState copyWith({
    bool? isLoading,
    List<CharityCampaign>? campaigns,
    String? error,
    bool clearError = false,
  }) {
    return CharityHomeState(
      isLoading: isLoading ?? this.isLoading,
      campaigns: campaigns ?? this.campaigns,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
