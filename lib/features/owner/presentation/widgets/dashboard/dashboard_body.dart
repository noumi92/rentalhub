import 'package:flutter/material.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/widgets/app_state_views.dart';

/// The dashboard body: while the shop data is loading (or failed to
/// load) the quick actions stay reachable above the loading/error
/// state — they were a pinned strip before the showroom redesign and
/// must not vanish when the data does (offline-first: Add Car, New
/// Booking, Finance and the rest have to work with no data). Once
/// loaded, [body] renders as-is (the guide order lives in the view).
class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.quickActions,
    required this.body,
    required this.loadingMessage,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final Widget quickActions;
  final Widget body;
  final String loadingMessage;
  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && !hasError) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: AppDimensions.spaceBetweenCards),
        child: body,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: AppDimensions.spaceBetweenCards),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quickActions,
          const SizedBox(height: 16),
          if (isLoading)
            AppLoadingState(message: loadingMessage)
          else
            AppErrorState(message: errorMessage, onRetry: onRetry),
        ],
      ),
    );
  }
}
