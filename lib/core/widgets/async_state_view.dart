import 'package:flutter/material.dart';

/// Quy tắc 3: mọi màn hình danh sách phải có 3 trạng thái loading / rỗng / lỗi.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message = 'Chưa có dữ liệu'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message = 'Đã có lỗi xảy ra', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
