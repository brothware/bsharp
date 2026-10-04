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
  final _listPositions = <int>[];
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
    _listPositions.add(0);
    visit();
    _flush();
    _lists.removeLast();
    _listPositions.removeLast();
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
    final position = _listPositions.removeLast();
    _listPositions.add(position + 1);
    _visitBlock(
      element,
      ListItemKind(
        lists: List.unmodifiable(_lists),
        index: _lists.last.start + position,
      ),
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
