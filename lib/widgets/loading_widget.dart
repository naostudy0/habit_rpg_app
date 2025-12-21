import 'package:flutter/material.dart';
import '../services/loading_service.dart';

/// 共通ローディングウィジェット
class LoadingWidget extends StatelessWidget {
  final String? operation;
  final bool showGlobalLoading;
  final Widget child;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingWidget({
    super.key,
    this.operation,
    this.showGlobalLoading = true,
    required this.child,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final loadingService = LoadingService();

    return ListenableBuilder(
      listenable: loadingService,
      builder: (context, _) {
        final isLoading = operation != null
            ? loadingService.isLoading(operation!)
            : (showGlobalLoading && loadingService.isAnyLoading);

        if (!isLoading) {
          return child;
        }

        return Stack(
          children: [
            child,
            Container(
              color: backgroundColor ?? Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            indicatorColor ?? Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '読み込み中...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ローディングオーバーレイウィジェット
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          indicatorColor ?? Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ローディングインジケーター（シンプル版）
class SimpleLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const SimpleLoadingIndicator({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}
