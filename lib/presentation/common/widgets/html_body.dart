import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

final linkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class HtmlBody extends ConsumerWidget {
  const HtmlBody(this.html, {super.key});

  final String html;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectionArea(
      child: HtmlWidget(
        html,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        onTapUrl: (url) => _openLink(context, ref, url),
      ),
    );
  }

  Future<bool> _openLink(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final isOpened = uri != null && await _launch(ref, uri);
    if (!isOpened) {
      messenger.showSnackBar(SnackBar(content: Text(t.common.linkOpenFailed)));
    }
    return true;
  }

  Future<bool> _launch(WidgetRef ref, Uri uri) async {
    try {
      return await ref.read(linkLauncherProvider)(uri);
    } on PlatformException catch (error, stackTrace) {
      debugPrint('HtmlBody: opening $uri failed: $error\n$stackTrace');
      return false;
    }
  }
}
