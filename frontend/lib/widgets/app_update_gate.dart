import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_installer.dart';
import '../services/app_update_service.dart';
import '../theme/app_theme.dart';

/// Wraps the whole app. Below APP_MIN_BUILD it covers the app with a
/// blocking "Update required" screen; below APP_LATEST_BUILD it shows a
/// dismissable "Update available" card. Checks at start and on resume.
///
/// "Update" downloads the APK inside the app with a progress bar and opens
/// Android's installer; the browser is only a fallback.
class AppUpdateGate extends StatefulWidget {
  final Widget? child;

  /// Replaceable for tests; defaults to [AppUpdateService.check].
  final Future<AppUpdateInfo> Function()? checker;

  /// Replaceable for tests; defaults to [AppUpdateInstaller.downloadAndInstall].
  final Stream<UpdateDownloadEvent> Function(String url)? downloader;

  /// Replaceable for tests; defaults to opening [url] in the browser/store.
  final Future<bool> Function(Uri url)? browserOpener;

  const AppUpdateGate({
    super.key,
    this.child,
    this.checker,
    this.downloader,
    this.browserOpener,
  });

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  static const Duration _recheckAfter = Duration(minutes: 30);

  AppUpdateInfo _info = AppUpdateInfo.none;
  bool _dismissed = false;
  DateTime? _lastCheck;

  StreamSubscription<UpdateDownloadEvent>? _download;
  _Progress _progress = const _Progress();

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
    _download?.cancel();
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

  void _update() {
    final url = _info.downloadUrl;
    if (!AppUpdateInstaller.canInstallInApp(url)) {
      _openInBrowser();
      return;
    }
    _download?.cancel();
    setState(() => _progress = const _Progress(
          status: UpdateDownloadStatus.downloading,
          percent: 0,
        ));
    _download =
        (widget.downloader ?? AppUpdateInstaller.downloadAndInstall)(url)
            .listen(
      (event) {
        if (!mounted) return;
        setState(() => _progress = _Progress(
              status: event.status,
              percent: event.percent ?? _progress.percent,
              message: event.message,
            ));
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _progress = const _Progress(
              status: UpdateDownloadStatus.failed,
              message:
                  'Download failed. Check your internet connection and try again.',
            ));
      },
    );
  }

  Future<void> _openInBrowser() async {
    var opened = false;
    try {
      final url = Uri.parse(_info.downloadUrl);
      opened = await (widget.browserOpener?.call(url) ??
          launchUrl(url, mode: LaunchMode.externalApplication));
    } catch (_) {}
    if (mounted && !opened) {
      setState(() => _progress = _Progress(
            status: UpdateDownloadStatus.failed,
            message:
                'Could not open the browser. Open this link to download:\n${_info.downloadUrl}',
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child ?? const SizedBox.shrink();
    final showRequired = _info.status == AppUpdateStatus.required;
    final showOptional =
        _info.status == AppUpdateStatus.optional && !_dismissed;
    if (!showRequired && !showOptional) return child;

    final actions = _UpdateActions(
      progress: _progress,
      onUpdate: _update,
      onBrowser: _openInBrowser,
      onLater: showRequired ? null : () => setState(() => _dismissed = true),
    );

    return Stack(
      children: [
        child,
        if (showRequired)
          Positioned.fill(
            child: _RequiredUpdateScreen(
              latestBuild: _info.latestBuild,
              actions: actions,
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
                actions: actions,
              ),
            ),
          ),
      ],
    );
  }
}

class _Progress {
  final UpdateDownloadStatus? status;
  final int? percent;
  final String? message;

  const _Progress({this.status, this.percent, this.message});

  bool get busy => status == UpdateDownloadStatus.downloading;
}

/// Progress text/bar and the buttons, shared by the card and the full screen.
class _UpdateActions extends StatelessWidget {
  final _Progress progress;
  final VoidCallback onUpdate;
  final VoidCallback onBrowser;
  final VoidCallback? onLater;

  const _UpdateActions({
    required this.progress,
    required this.onUpdate,
    required this.onBrowser,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final status = progress.status;
    final failed = status == UpdateDownloadStatus.failed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == UpdateDownloadStatus.downloading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (progress.percent ?? 0) > 0 ? progress.percent! / 100 : null,
            color: AppColors.navyMid,
          ),
          const SizedBox(height: 6),
          Text(
            'Downloading update... ${progress.percent ?? 0}%',
            style: const TextStyle(fontSize: 13),
          ),
        ],
        if (status == UpdateDownloadStatus.installing) ...[
          const SizedBox(height: 12),
          const Text(
            'Opening the installer... Tap Install on the next screen. '
            'If it did not open, tap Update again.',
            style: TextStyle(fontSize: 13),
          ),
        ],
        if (failed && progress.message != null) ...[
          const SizedBox(height: 12),
          SelectableText(
            progress.message!,
            style: const TextStyle(color: AppColors.dangerRed, fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 4,
          children: [
            if (failed)
              TextButton(
                onPressed: onBrowser,
                child: const Text('Open in browser'),
              ),
            if (onLater != null)
              TextButton(
                onPressed: progress.busy ? null : onLater,
                child: const Text('Later'),
              ),
            FilledButton(
              onPressed: progress.busy ? null : onUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyMid,
              ),
              child: Text(failed ? 'Try again' : 'Update'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequiredUpdateScreen extends StatelessWidget {
  final int latestBuild;
  final Widget actions;

  const _RequiredUpdateScreen({
    required this.latestBuild,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightBg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                    'Install build $latestBuild to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalUpdateCard extends StatelessWidget {
  final int latestBuild;
  final Widget actions;

  const _OptionalUpdateCard({
    required this.latestBuild,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
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
            actions,
          ],
        ),
      ),
    );
  }
}
