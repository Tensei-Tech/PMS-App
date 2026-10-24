import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../theme/app_theme.dart';

/// Wraps the whole app. Below APP_MIN_BUILD it covers the app with a
/// blocking "Update required" screen; below APP_LATEST_BUILD it shows a
/// dismissable "Update available" card. Checks at start and on resume.
class AppUpdateGate extends StatefulWidget {
  final Widget? child;

  /// Replaceable for tests; defaults to [AppUpdateService.check].
  final Future<AppUpdateInfo> Function()? checker;

  const AppUpdateGate({super.key, this.child, this.checker});

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  static const Duration _recheckAfter = Duration(minutes: 30);

  AppUpdateInfo _info = AppUpdateInfo.none;
  bool _dismissed = false;
  bool _launchFailed = false;
  DateTime? _lastCheck;

  bool get _enabled => widget.checker != null || AppUpdateService.isSupported;

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    if (_enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastCheck;
    if (last == null || DateTime.now().difference(last) > _recheckAfter) {
      _check();
    }
  }

  Future<void> _check() async {
    _lastCheck = DateTime.now();
    final info = await (widget.checker ?? AppUpdateService.check)();
    if (!mounted) return;
    setState(() {
      if (info.latestBuild != _info.latestBuild) _dismissed = false;
      _info = info;
    });
  }

  Future<void> _download() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(_info.downloadUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (mounted) setState(() => _launchFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child ?? const SizedBox.shrink();
    final showRequired = _info.status == AppUpdateStatus.required;
    final showOptional =
        _info.status == AppUpdateStatus.optional && !_dismissed;
    if (!showRequired && !showOptional) return child;

    return Stack(
      children: [
        child,
        if (showRequired)
          Positioned.fill(
            child: _RequiredUpdateScreen(
              latestBuild: _info.latestBuild,
              launchFailed: _launchFailed,
              downloadUrl: _info.downloadUrl,
              onDownload: _download,
            ),
          ),
        if (showOptional)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: _OptionalUpdateCard(
                latestBuild: _info.latestBuild,
                launchFailed: _launchFailed,
                downloadUrl: _info.downloadUrl,
                onDownload: _download,
                onLater: () => setState(() => _dismissed = true),
              ),
            ),
          ),
      ],
    );
  }
}

class _RequiredUpdateScreen extends StatelessWidget {
  final int latestBuild;
  final bool launchFailed;
  final String downloadUrl;
  final VoidCallback onDownload;

  const _RequiredUpdateScreen({
    required this.latestBuild,
    required this.launchFailed,
    required this.downloadUrl,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightBg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update,
                  size: 64,
                  color: AppColors.navyMid,
                ),
                const SizedBox(height: 16),
                Text(
                  'Update required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This version of the app is no longer supported. '
                  'Download build $latestBuild and install it to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Download update'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                  ),
                ),
                if (launchFailed) _LaunchFailedText(downloadUrl: downloadUrl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalUpdateCard extends StatelessWidget {
  final int latestBuild;
  final bool launchFailed;
  final String downloadUrl;
  final VoidCallback onDownload;
  final VoidCallback onLater;

  const _OptionalUpdateCard({
    required this.latestBuild,
    required this.launchFailed,
    required this.downloadUrl,
    required this.onDownload,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update, color: AppColors.navyMid),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Update available: build $latestBuild',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (launchFailed) _LaunchFailedText(downloadUrl: downloadUrl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onLater, child: const Text('Later')),
                TextButton(
                  onPressed: onDownload,
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchFailedText extends StatelessWidget {
  final String downloadUrl;

  const _LaunchFailedText({required this.downloadUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SelectableText(
        'Could not open the browser. Open this link to download:\n$downloadUrl',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.dangerRed, fontSize: 13),
      ),
    );
  }
}
