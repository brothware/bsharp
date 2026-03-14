import 'package:flutter/painting.dart';

String formatMessageDate(DateTime date, {String yesterday = 'Yesterday'}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(date.year, date.month, date.day);

  if (messageDay == today) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  final yesterdayDate = today.subtract(const Duration(days: 1));
  if (messageDay == yesterdayDate) {
    return yesterday;
  }

  if (date.year == now.year) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}';
  }

  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}

String formatMessageDateFull(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(
        RegExp('</(?:p|div|li|tr|h[1-6])>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

List<InlineSpan> parseHtmlSpans(String html, {TextStyle? baseStyle}) {
  final spans = <InlineSpan>[];
  final tagStack = <String>[];
  var pos = 0;

  while (pos < html.length) {
    final tagStart = html.indexOf('<', pos);
    if (tagStart < 0) {
      final text = _unescapeHtml(html.substring(pos));
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(text: text, style: _styleFromTags(baseStyle, tagStack)),
        );
      }
      break;
    }

    if (tagStart > pos) {
      final text = _unescapeHtml(html.substring(pos, tagStart));
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(text: text, style: _styleFromTags(baseStyle, tagStack)),
        );
      }
    }

    final tagEnd = html.indexOf('>', tagStart);
    if (tagEnd < 0) {
      final text = _unescapeHtml(html.substring(tagStart));
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(text: text, style: _styleFromTags(baseStyle, tagStack)),
        );
      }
      break;
    }

    final tag = html.substring(tagStart + 1, tagEnd).toLowerCase().trim();
    pos = tagEnd + 1;

    if (tag == 'br' || tag == 'br/' || tag == 'br /') {
      spans.add(const TextSpan(text: '\n'));
    } else if (tag == '/p' || tag == '/div' || tag == '/li' || tag == '/tr') {
      spans.add(const TextSpan(text: '\n'));
    } else if (tag == 'b' || tag == 'strong') {
      tagStack.add('b');
    } else if (tag == '/b' || tag == '/strong') {
      _removeLastTag(tagStack, 'b');
    } else if (tag == 'i' || tag == 'em') {
      tagStack.add('i');
    } else if (tag == '/i' || tag == '/em') {
      _removeLastTag(tagStack, 'i');
    } else if (tag == 'u') {
      tagStack.add('u');
    } else if (tag == '/u') {
      _removeLastTag(tagStack, 'u');
    }
  }

  return spans;
}

void _removeLastTag(List<String> stack, String tag) {
  for (var i = stack.length - 1; i >= 0; i--) {
    if (stack[i] == tag) {
      stack.removeAt(i);
      return;
    }
  }
}

TextStyle _styleFromTags(TextStyle? base, List<String> tags) {
  var style = base ?? const TextStyle();
  for (final tag in tags) {
    style = switch (tag) {
      'b' => style.copyWith(fontWeight: FontWeight.bold),
      'i' => style.copyWith(fontStyle: FontStyle.italic),
      'u' => style.copyWith(decoration: TextDecoration.underline),
      _ => style,
    };
  }
  return style;
}

String _unescapeHtml(String text) => text
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"');

String messagePreview(String content, {int maxLength = 100}) {
  final stripped = content
      .replaceAll(RegExp(r'<br\s*/?>'), ' ')
      .replaceAll(
        RegExp('</(?:p|div|li|tr|h[1-6])>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (stripped.length <= maxLength) return stripped;
  return '${stripped.substring(0, maxLength)}...';
}
