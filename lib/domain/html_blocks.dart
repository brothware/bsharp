import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

enum HtmlTextStyle { bold, italic, underline }

final class HtmlList {
  const HtmlList({
    required this.id,
    required this.isOrdered,
    required this.start,
  });

  final int id;
  final bool isOrdered;
  final int start;
}

sealed class HtmlBlockKind {
  const HtmlBlockKind();
}

final class ParagraphKind extends HtmlBlockKind {
  const ParagraphKind();
}

final class HeadingKind extends HtmlBlockKind {
  const HeadingKind(this.level);

  final int level;
}

final class ListItemKind extends HtmlBlockKind {
  const ListItemKind({required this.lists, required this.index});

  final List<HtmlList> lists;
  final int index;

  HtmlList get list => lists.last;
}

final class CellKind extends HtmlBlockKind {
  const CellKind({
    required this.table,
    required this.row,
    required this.isHeader,
  });

  final int table;
  final int row;
  final bool isHeader;
}

final class HtmlLine {
  const HtmlLine({
    required this.text,
    this.styles = const {},
    this.link,
    this.links = const [],
  });

  final String text;
  final Set<HtmlTextStyle> styles;
  final String? link;
  final List<String> links;

  bool get isBlank => text.isEmpty;
}

final class HtmlBlock {
  const HtmlBlock({required this.kind, required this.lines});

  final HtmlBlockKind kind;
  final List<HtmlLine> lines;
}

List<HtmlBlock> parseHtmlBlocks(String html) {
  final collector = _BlockCollector()
    ..visitAll(html_parser.parseFragment(html).nodes);
  return collector.finish();
}

String htmlBlocksToPlainText(List<HtmlBlock> blocks) {
  return blocks
      .map((block) {
        final lines = block.lines.map((line) => line.text).toList();
        return '${_plainPrefix(block.kind)}${lines.join('\n')}';
      })
      .join('\n')
      .trim();
}

List<String> translationUnits(List<HtmlBlock> blocks) {
  return [
    for (final block in blocks)
      for (final line in block.lines)
        if (!line.isBlank) line.text,
  ];
}

String rebuildTranslatedHtml(List<HtmlBlock> blocks, String translated) {
  final pieces = translated.split('\n').map((piece) => piece.trim()).toList();
  if (pieces.length != translationUnits(blocks).length) {
    return _plainTextAsHtml(translated);
  }
  final writer = _HtmlWriter(pieces.iterator);
  blocks.forEach(writer.write);
  return writer.finish();
}

String _plainTextAsHtml(String text) {
  final lines = text.trim().split('\n').map(_escapeText);
  return '<p>${lines.join('<br>')}</p>';
}

String _escapeText(String text) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(text);

String _escapeAttribute(String text) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(text);

const Map<HtmlTextStyle, String> _styleTagNames = {
  HtmlTextStyle.bold: 'b',
  HtmlTextStyle.italic: 'i',
  HtmlTextStyle.underline: 'u',
};

class _HtmlWriter {
  _HtmlWriter(this._pieces);

  final Iterator<String> _pieces;
  final _out = StringBuffer();
  final _openLists = <HtmlList>[];
  final _openIndexes = <int>[];
  int? _openTable;
  int? _openRow;

  String finish() {
    _closeLists(0);
    _closeTable();
    return _out.toString();
  }

  void write(HtmlBlock block) {
    switch (block.kind) {
      case ParagraphKind():
        _closeLists(0);
        _closeTable();
        _out.write('<p>${_contentOf(block)}</p>');
      case HeadingKind(:final level):
        _closeLists(0);
        _closeTable();
        _out.write('<h$level>${_contentOf(block)}</h$level>');
      case ListItemKind(:final lists, :final index):
        _closeTable();
        _openItem(lists, index);
        _out.write(_contentOf(block));
      case CellKind(:final table, :final row, :final isHeader):
        _closeLists(0);
        _openCell(table, row);
        final tag = isHeader ? 'th' : 'td';
        _out.write('<$tag>${_contentOf(block)}</$tag>');
    }
  }

  void _openItem(List<HtmlList> lists, int index) {
    var common = 0;
    while (common < _openLists.length &&
        common < lists.length &&
        _openLists[common].id == lists[common].id) {
      common++;
    }
    _closeLists(common);
    if (_openLists.length == lists.length) {
      final previousIndex = _openIndexes.last;
      if (index == previousIndex) {
        _out.write('<br>');
        return;
      }
      if (!lists.last.isOrdered || index == previousIndex + 1) {
        _out.write('</li><li>');
        _openIndexes.last = index;
        return;
      }
      _closeLists(_openLists.length - 1);
    }
    while (_openLists.length < lists.length) {
      final list = lists[_openLists.length];
      final isInnermost = _openLists.length == lists.length - 1;
      final start = isInnermost ? index : list.start;
      _out
        ..write(list.isOrdered ? '<ol start="$start">' : '<ul>')
        ..write('<li>');
      _openLists.add(list);
      _openIndexes.add(start);
    }
  }

  void _closeLists(int keep) {
    while (_openLists.length > keep) {
      final list = _openLists.removeLast();
      _openIndexes.removeLast();
      _out.write(list.isOrdered ? '</li></ol>' : '</li></ul>');
    }
  }

  void _openCell(int table, int row) {
    if (_openTable != table) {
      _closeTable();
      _out.write('<table><tr>');
      _openTable = table;
      _openRow = row;
    } else if (_openRow != row) {
      _out.write('</tr><tr>');
      _openRow = row;
    }
  }

  void _closeTable() {
    if (_openTable != null) {
      _out.write('</tr></table>');
      _openTable = null;
      _openRow = null;
    }
  }

  String _contentOf(HtmlBlock block) {
    final lines = [
      for (final line in block.lines)
        if (line.isBlank) '' else _translatedLine(line),
    ];
    final links = {for (final line in block.lines) ...line.links};
    return [...lines, ...links.map(_linkTo)].join('<br>');
  }

  String _translatedLine(HtmlLine line) {
    _pieces.moveNext();
    var html = _escapeText(_pieces.current);
    for (final style in line.styles) {
      final tag = _styleTagNames[style];
      html = '<$tag>$html</$tag>';
    }
    final link = line.link;
    return link == null ? html : _linkTo(link, label: html);
  }

  String _linkTo(String href, {String? label}) {
    return '<a href="${_escapeAttribute(href)}">'
        '${label ?? _escapeText(href)}</a>';
  }
}

String _plainPrefix(HtmlBlockKind kind) {
  return switch (kind) {
    ListItemKind(:final list, :final index) when list.isOrdered => '$index. ',
    ListItemKind() => '• ',
    ParagraphKind() || HeadingKind() || CellKind() => '',
  };
}

const _skippedTags = {'script', 'style', 'head', 'title', 'template'};
const _paragraphTags = {
  'p',
  'div',
  'blockquote',
  'section',
  'article',
  'header',
  'footer',
  'pre',
  'address',
  'center',
};
const Map<String, HtmlTextStyle> _styleTags = {
  'b': HtmlTextStyle.bold,
  'strong': HtmlTextStyle.bold,
  'i': HtmlTextStyle.italic,
  'em': HtmlTextStyle.italic,
  'u': HtmlTextStyle.underline,
};
final _headingTag = RegExp(r'^h([1-6])$');
final _whitespace = RegExp(r'\s+');

final class _Segment {
  const _Segment(this.text, this.styles, this.href);

  final String text;
  final Set<HtmlTextStyle> styles;
  final String? href;

  bool get isMeaningful => text.trim().isNotEmpty;
}

class _BlockCollector {
  final _blocks = <HtmlBlock>[];
  var _lines = <List<_Segment>>[[]];
  HtmlBlockKind _kind = const ParagraphKind();
  var _isInsideItem = false;
  final _styles = <HtmlTextStyle>[];
  final _hrefs = <String?>[];
  final _lists = <HtmlList>[];
  final _nextIndexes = <int>[];
  var _nextListId = 0;
  var _table = -1;
  var _row = -1;

  List<HtmlBlock> finish() {
    _flush();
    return List.unmodifiable(_blocks);
  }

  void visitAll(Iterable<Node> nodes) {
    for (final node in nodes) {
      if (node is Text) {
        _lines.last.add(
          _Segment(node.text, Set.unmodifiable(_styles), _hrefs.lastOrNull),
        );
      } else if (node is Element) {
        _visitElement(node);
      }
    }
  }

  void _visitElement(Element element) {
    final tag = element.localName ?? '';
    final heading = _headingTag.firstMatch(tag);
    final style = _styleTags[tag];
    if (_skippedTags.contains(tag)) {
      return;
    }
    if (tag == 'br') {
      _lines.add([]);
    } else if (tag == 'ul' || tag == 'ol') {
      _visitList(element, isOrdered: tag == 'ol');
    } else if (tag == 'li') {
      _visitItem(element);
    } else if (tag == 'table') {
      _table++;
      visitAll(element.nodes);
    } else if (tag == 'tr') {
      _row++;
      visitAll(element.nodes);
    } else if (tag == 'td' || tag == 'th') {
      _visitBlock(
        element,
        CellKind(table: _table, row: _row, isHeader: tag == 'th'),
        isItem: true,
      );
    } else if (heading != null) {
      _visitParagraph(element, HeadingKind(int.parse(heading.group(1)!)));
    } else if (_paragraphTags.contains(tag)) {
      _visitParagraph(element, const ParagraphKind());
    } else if (style != null) {
      _styles.add(style);
      visitAll(element.nodes);
      _styles.removeLast();
    } else if (tag == 'a') {
      final href = element.attributes['href']?.trim();
      _hrefs.add(href == null || href.isEmpty ? null : href);
      visitAll(element.nodes);
      _hrefs.removeLast();
    } else {
      visitAll(element.nodes);
    }
  }

  void _visitParagraph(Element element, HtmlBlockKind kind) {
    if (!_isInsideItem) {
      _visitBlock(element, kind, isItem: false);
      return;
    }
    _breakSoftly();
    visitAll(element.nodes);
    _breakSoftly();
  }

  void _visitList(Element element, {required bool isOrdered}) {
    _insideList(
      isOrdered: isOrdered,
      start: int.tryParse(element.attributes['start'] ?? '') ?? 1,
      visit: () => visitAll(element.nodes),
    );
  }

  void _insideList({
    required bool isOrdered,
    required int start,
    required void Function() visit,
  }) {
    _flush();
    _lists.add(HtmlList(id: _nextListId++, isOrdered: isOrdered, start: start));
    _nextIndexes.add(start);
    visit();
    _flush();
    _lists.removeLast();
    _nextIndexes.removeLast();
  }

  void _visitItem(Element element) {
    if (_lists.isEmpty) {
      _insideList(
        isOrdered: false,
        start: 1,
        visit: () => _visitItem(element),
      );
      return;
    }
    final nextIndex = _nextIndexes.removeLast();
    final index = int.tryParse(element.attributes['value'] ?? '') ?? nextIndex;
    _nextIndexes.add(index + 1);
    _visitBlock(
      element,
      ListItemKind(lists: List.unmodifiable(_lists), index: index),
      isItem: true,
    );
  }

  void _visitBlock(
    Element element,
    HtmlBlockKind kind, {
    required bool isItem,
  }) {
    _flush();
    final parentKind = _kind;
    final parentIsInsideItem = _isInsideItem;
    _kind = kind;
    _isInsideItem = isItem;
    visitAll(element.nodes);
    _flush();
    _kind = parentKind;
    _isInsideItem = parentIsInsideItem;
  }

  void _breakSoftly() {
    if (_lines.last.any((segment) => segment.isMeaningful)) {
      _lines.add([]);
    }
  }

  void _flush() {
    final lines = _collapseBlankLines(_lines.map(_lineOf).toList());
    _lines = [[]];
    if (lines.isNotEmpty) {
      _blocks.add(HtmlBlock(kind: _kind, lines: List.unmodifiable(lines)));
    }
  }
}

HtmlLine _lineOf(List<_Segment> segments) {
  final text = segments
      .map((segment) => segment.text)
      .join()
      .replaceAll(_whitespace, ' ')
      .trim();
  final meaningful = segments.where((segment) => segment.isMeaningful);
  if (meaningful.isEmpty) {
    return const HtmlLine(text: '');
  }
  final styles = meaningful
      .map((segment) => segment.styles)
      .reduce((common, styles) => common.intersection(styles));
  final hrefs = meaningful.map((segment) => segment.href).toSet();
  final wholeLink = hrefs.length == 1 ? hrefs.single : null;
  return HtmlLine(
    text: text,
    styles: Set.unmodifiable(styles),
    link: wholeLink,
    links: wholeLink != null
        ? const []
        : List.unmodifiable(hrefs.whereType<String>()),
  );
}

List<HtmlLine> _collapseBlankLines(List<HtmlLine> lines) {
  final collapsed = <HtmlLine>[];
  for (final line in lines) {
    final previousIsBlank = collapsed.isEmpty || collapsed.last.isBlank;
    if (!line.isBlank || !previousIsBlank) {
      collapsed.add(line);
    }
  }
  while (collapsed.isNotEmpty && collapsed.last.isBlank) {
    collapsed.removeLast();
  }
  return collapsed;
}
