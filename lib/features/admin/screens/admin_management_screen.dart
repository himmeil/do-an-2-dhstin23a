import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../dia_diem/du_lieu/models/place.dart';
import '../../dia_diem/du_lieu/repositories/place_repository.dart';
import '../../gps/services/location_service.dart';
import '../../nap_du_lieu/screens/import_screen.dart';
import '../../tim_kiem/services/admin_error_log_service.dart';
import '../../tim_kiem/services/nearby_places_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({
    required this.isAdmin,
    required this.placeService,
    required this.draftService,
    required this.locationService,
    required this.adminErrorLogService,
    this.nearbyPlacesService,
    super.key,
  });

  final bool isAdmin;
  final PlaceService placeService;
  final PlaceService draftService;
  final LocationService locationService;
  final AdminErrorLogService adminErrorLogService;
  final NearbyPlacesService? nearbyPlacesService;

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  bool _publishing = false;
  bool _updatingMap = false;
  bool _selectingMap = false;

  Future<void> _createDraft() async {
    final count = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ImportScreen(
          service: widget.draftService,
          locationService: widget.locationService,
          isDraft: true,
        ),
      ),
    );
    if (count != null && count > 0 && mounted) {
      _showMessage('Đã lưu $count địa điểm vào bản nháp.');
    }
  }

  Future<void> _publishDrafts() async {
    if (_publishing) return;
    late final List<Place> drafts;
    try {
      drafts = await widget.draftService.watchAll().first;
    } catch (error) {
      await _recordError(AdminErrorCode.draftReadFailed, error);
      if (mounted) _showMessage('Không đọc được bản nháp: $error');
      return;
    }
    if (!mounted) return;
    if (drafts.isEmpty) {
      _showMessage('Chưa có bản nháp để đăng.');
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt và đăng bản nháp'),
        content: SizedBox(
          width: 480,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kiểm tra ${drafts.length} địa điểm trước khi đăng. '
                'Bản nháp trên thiết bị vẫn được giữ lại.',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: drafts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = drafts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(place.name),
                      subtitle: Text('${place.category} • ${place.address}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Xem lại sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng lên'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _publishing = true);
    try {
      final count = await widget.placeService.importAll(drafts);
      if (mounted) _showMessage('Đã đăng $count địa điểm lên Firestore.');
    } catch (error) {
      await _recordError(AdminErrorCode.draftPublishFailed, error);
      if (mounted) _showMessage('Chưa đăng được bản nháp: $error');
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _updateMap() async {
    final service = widget.nearbyPlacesService;
    if (service is! OverpassNearbyPlacesService ||
        !service.canManageMapData ||
        _updatingMap) {
      return;
    }
    setState(() => _updatingMap = true);
    try {
      final count = await service.updateMapFromOverpass();
      if (mounted) _showMessage('Đã cập nhật $count địa điểm từ Overpass.');
    } catch (error) {
      await _recordError(AdminErrorCode.mapRefreshFailed, error);
      if (mounted) _showMessage('Cập nhật bản đồ thất bại: $error');
    } finally {
      if (mounted) setState(() => _updatingMap = false);
    }
  }

  Future<void> _selectMapSource() async {
    final service = widget.nearbyPlacesService;
    if (service is! OverpassNearbyPlacesService ||
        !service.canManageMapData ||
        _selectingMap) {
      return;
    }
    setState(() => _selectingMap = true);
    var applying = false;
    try {
      final sources = await service.listMapDataSources();
      if (!mounted) return;
      if (sources.isEmpty) {
        _showMessage('Backend chưa có snapshot bản đồ nào.');
        return;
      }
      final selected = await showDialog<MapDataSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn dữ liệu bản đồ Cao Lãnh'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final source in sources)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      source.active ? Icons.radio_button_checked : Icons.map,
                    ),
                    title: Text(source.label),
                    subtitle: Text(
                      '${source.file} • ${source.count} địa điểm'
                      '${source.updatedAt == null ? '' : '\nCập nhật: ${_formatDate(source.updatedAt!)}'}'
                      '${source.active ? '\nĐang sử dụng' : ''}',
                    ),
                    isThreeLine: source.updatedAt != null || source.active,
                    onTap: () => Navigator.pop(context, source),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (selected == null || selected.active || !mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Dùng ${selected.label.toLowerCase()}?'),
          content: Text(
            'Backend sẽ dùng ${selected.file} '
            '(${selected.count} địa điểm). Các file snapshot được giữ nguyên.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      applying = true;
      final count = await service.selectMapDataSource(selected.source);
      if (mounted) {
        _showMessage('Đã dùng ${selected.file}: $count địa điểm.');
      }
    } catch (error) {
      await _recordError(
        applying
            ? AdminErrorCode.mapSourceApplyFailed
            : AdminErrorCode.mapSourceReadFailed,
        error,
      );
      if (mounted) _showMessage('Không chọn được dữ liệu bản đồ: $error');
    } finally {
      if (mounted) setState(() => _selectingMap = false);
    }
  }

  Future<void> _showErrors() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã lỗi hệ thống'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: StreamBuilder<List<AdminErrorEntry>>(
            stream: widget.adminErrorLogService.watchRecent(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Không đọc được mã lỗi. Kiểm tra kết nối và Firestore Rules.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return const Center(child: Text('Chưa ghi nhận mã lỗi.'));
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(entry.code.value),
                      subtitle: Text(
                        '${entry.code.description}'
                        '${entry.lastSeenAt == null ? '' : '\nGần nhất: ${_formatDate(entry.lastSeenAt!)}'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordError(AdminErrorCode code, Object error) async {
    try {
      await widget.adminErrorLogService.record(code);
    } catch (logError) {
      debugPrint(
        'Could not record admin error ${code.value} '
        'after $error: $logError',
      );
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Bạn không có quyền truy cập trang quản lý.')),
      );
    }

    final service = widget.nearbyPlacesService;
    final canManageMap =
        !AppEnvironment.isFirebaseHosted &&
        service is OverpassNearbyPlacesService &&
        service.canManageMapData;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hệ thống'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Người xem'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const ListTile(
              leading: Icon(Icons.admin_panel_settings, size: 32),
              title: Text('Khu vực quản trị'),
              subtitle: Text(
                'Chỉ tài khoản có quyền admin mới truy cập được. '
                'Dùng “Trang người xem” để quay lại ứng dụng địa điểm.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AdminSection(
            title: 'Quản lý địa điểm',
            children: [
              _AdminActionTile(
                icon: Icons.add_location_alt_outlined,
                title: 'Tạo bản nháp',
                subtitle: 'Nhập dữ liệu và lưu nháp trên thiết bị.',
                onTap: _createDraft,
              ),
              _AdminActionTile(
                icon: _publishing ? null : Icons.cloud_upload_outlined,
                title: _publishing ? 'Đang đăng bản nháp...' : 'Duyệt và đăng',
                subtitle: 'Kiểm tra các bản nháp trước khi đăng lên Firestore.',
                onTap: _publishing ? null : _publishDrafts,
                loading: _publishing,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AdminSection(
            title: 'Dữ liệu bản đồ',
            children: [
              if (!canManageMap)
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(
                    'Quản lý snapshot chỉ khả dụng trên backend local.',
                  ),
                )
              else ...[
                _AdminActionTile(
                  icon: _updatingMap ? null : Icons.sync,
                  title: _updatingMap
                      ? 'Đang cập nhật dữ liệu...'
                      : 'Cập nhật từ OpenStreetMap',
                  subtitle: 'Tải snapshot mới cho khu vực Cao Lãnh.',
                  onTap: _updatingMap ? null : _updateMap,
                  loading: _updatingMap,
                ),
                _AdminActionTile(
                  icon: _selectingMap ? null : Icons.layers_outlined,
                  title: _selectingMap
                      ? 'Đang tải snapshot...'
                      : 'Chọn snapshot đang sử dụng',
                  subtitle:
                      'Chuyển giữa dữ liệu bản đồ hiện tại và bản sao lưu.',
                  onTap: _selectingMap ? null : _selectMapSource,
                  loading: _selectingMap,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _AdminSection(
            title: 'Giám sát',
            children: [
              _AdminActionTile(
                icon: Icons.error_outline,
                title: 'Mã lỗi hệ thống',
                subtitle: 'Xem các mã lỗi gần đây đã được ghi nhận.',
                onTap: _showErrors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...children,
        ],
      ),
    ),
  );
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData? icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: loading
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
