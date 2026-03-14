import 'dart:math';

import 'package:flutter/widgets.dart';

enum FormatType { bold, italic, underline }

class FormatRange {
  FormatRange(this.start, this.end, this.type);

  int start;
  int end;
  FormatType type;
}

class RichTextEditingController extends TextEditingController {
  RichTextEditingController() {
    addListener(_onValueChanged);
  }

  final _formats = <FormatRange>[];
  final _activeFormats = <FormatType>{};
  String _previousText = '';

  Set<FormatType> get activeFormats => Set.unmodifiable(_activeFormats);

  void toggleFormat(FormatType type) {
    if (_activeFormats.contains(type)) {
      _activeFormats.remove(type);
    } else {
      _activeFormats.add(type);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() {
    final currentText = text;
    if (_previousText != currentText) {
      _updateAnnotations(_previousText, currentText);
      _previousText = currentText;
    } else {
      _syncActiveFormats(selection);
    }
  }

  void _syncActiveFormats(TextSelection sel) {
    if (!sel.isValid || sel.baseOffset < 0) return;

    final pos = sel.baseOffset;
    final next = <FormatType>{};
    for (final f in _formats) {
      final inside =
          (f.start < pos && pos <= f.end) ||
          (pos == 0 && f.start == 0 && f.end > 0);
      if (inside) next.add(f.type);
    }

    if (!_setEquals(next, _activeFormats)) {
      _activeFormats
        ..clear()
        ..addAll(next);
    }
  }

  static bool _setEquals(Set<FormatType> a, Set<FormatType> b) =>
      a.length == b.length && a.containsAll(b);

  void _mergeOverlapping(FormatType type) {
    final ofType = _formats.where((f) => f.type == type).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    for (var i = 0; i < ofType.length - 1; i++) {
      if (ofType[i].end >= ofType[i + 1].start) {
        ofType[i].end = max(ofType[i].end, ofType[i + 1].end);
        _formats.remove(ofType[i + 1]);
        ofType.removeAt(i + 1);
        i--;
      }
    }
  }

  void _updateAnnotations(String oldText, String newText) {
    var prefixLen = 0;
    final minLen = min(oldText.length, newText.length);
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    var oldSuffix = oldText.length;
    var newSuffix = newText.length;
    while (oldSuffix > prefixLen &&
        newSuffix > prefixLen &&
        oldText[oldSuffix - 1] == newText[newSuffix - 1]) {
      oldSuffix--;
      newSuffix--;
    }

    final deleteStart = prefixLen;
    final deleteEnd = oldSuffix;
    final insertLength = newSuffix - prefixLen;

    if (deleteStart < deleteEnd) {
      _applyDelete(deleteStart, deleteEnd);
    }
    if (insertLength > 0) {
      _applyInsert(deleteStart, insertLength);
    }
  }

  void _applyDelete(int start, int end) {
    final length = end - start;
    for (final f in _formats.toList()) {
      if (f.start >= end) {
        f
          ..start -= length
          ..end -= length;
      } else if (f.start >= start) {
        f.start = start;
        if (f.end <= end) {
          _formats.remove(f);
        } else {
          f.end -= length;
        }
      } else if (f.end > start) {
        if (f.end <= end) {
          f.end = start;
        } else {
          f.end -= length;
        }
      }
    }
    _formats.removeWhere((f) => f.start >= f.end);
  }

  void _applyInsert(int position, int length) {
    final insertEnd = position + length;

    for (final f in _formats.toList()) {
      if (f.start > position) {
        f
          ..start += length
          ..end += length;
      } else if (f.end > position) {
        if (_activeFormats.contains(f.type)) {
          f.end += length;
        } else {
          final newEnd = f.end + length;
          f.end = position;
          if (insertEnd < newEnd) {
            _formats.add(FormatRange(insertEnd, newEnd, f.type));
          }
        }
      } else if (f.end == position && _activeFormats.contains(f.type)) {
        f.end = insertEnd;
      }
    }

    for (final type in _activeFormats) {
      final covered = _formats.any(
        (f) => f.type == type && f.start <= position && f.end >= insertEnd,
      );
      if (!covered) {
        _formats.add(FormatRange(position, insertEnd, type));
        _mergeOverlapping(type);
      }
    }

    _formats.removeWhere((f) => f.start >= f.end);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final composing = value.composing;
    final hasComposing =
        withComposing && value.isComposingRangeValid && !composing.isCollapsed;

    if (_formats.isEmpty && !hasComposing) {
      return TextSpan(text: text, style: style);
    }

    final breakpoints = <int>{0, text.length};
    for (final f in _formats) {
      breakpoints
        ..add(f.start.clamp(0, text.length))
        ..add(f.end.clamp(0, text.length));
    }
    if (hasComposing) {
      breakpoints
        ..add(composing.start.clamp(0, text.length))
        ..add(composing.end.clamp(0, text.length));
    }
    final sorted = breakpoints.toList()..sort();

    final children = <TextSpan>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (start == end) continue;

      var spanStyle = style ?? const TextStyle();
      for (final f in _formats) {
        if (f.start <= start && f.end >= end) {
          spanStyle = switch (f.type) {
            FormatType.bold => spanStyle.copyWith(fontWeight: FontWeight.bold),
            FormatType.italic => spanStyle.copyWith(
              fontStyle: FontStyle.italic,
            ),
            FormatType.underline => spanStyle.copyWith(
              decoration: TextDecoration.underline,
            ),
          };
        }
      }
      if (hasComposing && start >= composing.start && end <= composing.end) {
        spanStyle = spanStyle.copyWith(decoration: TextDecoration.underline);
      }
      children.add(
        TextSpan(text: text.substring(start, end), style: spanStyle),
      );
    }

    if (children.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    return TextSpan(children: children);
  }

  String toHtml() {
    if (_formats.isEmpty) {
      return _escapeHtml(text).replaceAll('\n', '<br>');
    }

    final breakpoints = <int>{0, text.length};
    for (final f in _formats) {
      breakpoints
        ..add(f.start.clamp(0, text.length))
        ..add(f.end.clamp(0, text.length));
    }
    final sorted = breakpoints.toList()..sort();

    final buf = StringBuffer();
    for (var i = 0; i < sorted.length - 1; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (start == end) continue;

      final active = <FormatType>{};
      for (final f in _formats) {
        if (f.start <= start && f.end >= end) {
          active.add(f.type);
        }
      }

      var segment = _escapeHtml(text.substring(start, end));
      if (active.contains(FormatType.underline)) segment = '<u>$segment</u>';
      if (active.contains(FormatType.italic)) segment = '<i>$segment</i>';
      if (active.contains(FormatType.bold)) segment = '<b>$segment</b>';
      buf.write(segment);
    }

    return buf.toString().replaceAll('\n', '<br>');
  }

  static String _escapeHtml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
