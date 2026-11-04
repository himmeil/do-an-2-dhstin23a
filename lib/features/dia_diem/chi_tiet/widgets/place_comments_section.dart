import 'package:flutter/material.dart';

import '../../du_lieu/models/place_comment.dart';
import '../../du_lieu/repositories/place_comment_repository.dart';

class PlaceCommentsSection extends StatefulWidget {
  const PlaceCommentsSection({
    required this.placeId,
    required this.service,
    required this.isSignedIn,
    required this.accountName,
    this.onRequireSignIn,
    super.key,
  });

  final String placeId;
  final PlaceCommentService service;
  final bool isSignedIn;
  final String accountName;
  final VoidCallback? onRequireSignIn;

  @override
  State<PlaceCommentsSection> createState() => _PlaceCommentsSectionState();
}

class _PlaceCommentsSectionState extends State<PlaceCommentsSection> {
  final _controller = TextEditingController();
  late Stream<List<PlaceComment>> _comments;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _comments = widget.service.watchForPlace(widget.placeId);
  }

  @override
  void didUpdateWidget(covariant PlaceCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId ||
        oldWidget.service != widget.service) {
      _comments = widget.service.watchForPlace(widget.placeId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.isSignedIn) {
      widget.onRequireSignIn?.call();
      return;
    }
    final content = _controller.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.service.add(
        placeId: widget.placeId,
        accountName: widget.accountName,
        content: content,
      );
      if (!mounted) return;
      setState(() {
        _controller.clear();
        _comments = widget.service.watchForPlace(widget.placeId);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Chưa gửi được bình luận: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Bình luận', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      StreamBuilder(
        stream: _comments,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Không tải được bình luận: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final comments = snapshot.data!;
          if (comments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Chưa có bình luận.'),
            );
          }
          return Column(
            children: [
              for (final comment in comments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(comment.accountName),
                  subtitle: Text(comment.content),
                  trailing: comment.createdAt == null
                      ? null
                      : Text(_formatDate(comment.createdAt!)),
                  isThreeLine: true,
                ),
            ],
          );
        },
      ),
      if (widget.isSignedIn) ...[
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Viết bình luận',
            border: OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Gửi bình luận'),
          ),
        ),
      ] else
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đăng nhập để bình luận'),
            trailing: TextButton(
              onPressed: widget.onRequireSignIn,
              child: const Text('Đăng nhập'),
            ),
          ),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
