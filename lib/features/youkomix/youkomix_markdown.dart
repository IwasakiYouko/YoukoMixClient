import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class YoukoMixMarkdownBody extends StatefulWidget {
  final String source;
  final ValueChanged<String>? onTapLink;

  const YoukoMixMarkdownBody({super.key, required this.source, this.onTapLink});

  @override
  State<YoukoMixMarkdownBody> createState() => _YoukoMixMarkdownBodyState();
}

class _YoukoMixMarkdownBodyState extends State<YoukoMixMarkdownBody> {
  final List<TapGestureRecognizer> _recognizers = [];

  static final _headingPattern = RegExp(r'^(#{1,4})\s+(.+?)\s*#*\s*$');
  static final _hrPattern = RegExp(r'^\s*(?:[-*_]\s*){3,}$');
  static final _unorderedListPattern = RegExp(r'^\s*[-*+]\s+(.+)$');
  static final _orderedListPattern = RegExp(r'^\s*(\d+)[.)]\s+(.+)$');
  static final _blockquotePattern = RegExp(r'^\s*>\s?(.*)$');
  static final _inlinePattern = RegExp(
    r'`([^`]+)`|\[([^\]]+)\]\((https?://[^\s)]+)\)|\*\*\*([^*]+)\*\*\*|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*\n]+)\*',
  );

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  List<_MdBlock> _parseBlocks(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final lines = normalized.split('\n');
    final blocks = <_MdBlock>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index];
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        index++;
        continue;
      }

      if (trimmed.startsWith('```')) {
        index++;
        final codeLines = <String>[];
        while (index < lines.length && !lines[index].trim().startsWith('```')) {
          codeLines.add(lines[index]);
          index++;
        }
        if (index < lines.length) {
          index++;
        }
        blocks.add(_MdCodeBlock(codeLines.join('\n').trimRight()));
        continue;
      }

      if (_hrPattern.hasMatch(trimmed)) {
        blocks.add(const _MdDivider());
        index++;
        continue;
      }

      final headingMatch = _headingPattern.firstMatch(trimmed);
      if (headingMatch != null) {
        blocks.add(
          _MdHeading(
            level: headingMatch.group(1)!.length,
            text: headingMatch.group(2)!.trim(),
          ),
        );
        index++;
        continue;
      }

      final quoteMatch = _blockquotePattern.firstMatch(line);
      if (quoteMatch != null) {
        final quoteLines = <String>[];
        while (index < lines.length) {
          final currentQuote = _blockquotePattern.firstMatch(lines[index]);
          if (currentQuote == null) {
            break;
          }
          quoteLines.add(currentQuote.group(1)!.trim());
          index++;
        }
        final joined = quoteLines.where((item) => item.isNotEmpty).join('\n');
        if (joined.isNotEmpty) {
          blocks.add(_MdQuote(joined));
        }
        continue;
      }

      final ulMatch = _unorderedListPattern.firstMatch(line);
      if (ulMatch != null) {
        final items = <({String marker, String text})>[];
        while (index < lines.length) {
          final currentUl = _unorderedListPattern.firstMatch(lines[index]);
          if (currentUl == null) {
            break;
          }
          items.add((marker: '•', text: currentUl.group(1)!.trim()));
          index++;
        }
        blocks.add(_MdList(items));
        continue;
      }

      final olMatch = _orderedListPattern.firstMatch(line);
      if (olMatch != null) {
        final items = <({String marker, String text})>[];
        while (index < lines.length) {
          final currentOl = _orderedListPattern.firstMatch(lines[index]);
          if (currentOl == null) {
            break;
          }
          items.add((
            marker: '${currentOl.group(1)!}.',
            text: currentOl.group(2)!.trim(),
          ));
          index++;
        }
        blocks.add(_MdList(items));
        continue;
      }

      final paragraphLines = <String>[];
      while (index < lines.length) {
        final candidate = lines[index];
        final candidateTrim = candidate.trim();
        if (candidateTrim.isEmpty ||
            candidateTrim.startsWith('```') ||
            _hrPattern.hasMatch(candidateTrim) ||
            _headingPattern.hasMatch(candidateTrim) ||
            _blockquotePattern.hasMatch(candidate) ||
            _unorderedListPattern.hasMatch(candidate) ||
            _orderedListPattern.hasMatch(candidate)) {
          break;
        }
        paragraphLines.add(candidateTrim);
        index++;
      }
      if (paragraphLines.isNotEmpty) {
        blocks.add(_MdParagraph(paragraphLines.join('\n')));
      }
    }

    return blocks;
  }

  List<InlineSpan> _buildInlineSpans(
    BuildContext context,
    String text, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    final colorScheme = context.colorScheme;
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _inlinePattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
        );
      }
      final code = match.group(1);
      final linkLabel = match.group(2);
      final linkUrl = match.group(3);
      final boldItalic = match.group(4);
      final boldA = match.group(5);
      final boldB = match.group(6);
      final italic = match.group(7);

      if (code != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.65),
                shape: AppShape.all(AppCorner.xs),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                  code,
                  style: AppTextStyle.caption1
                      .of(context, emphasized: true)
                      .copyWith(
                        fontFamily: FontFamily.jetBrainsMono.value,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ),
          ),
        );
      } else if (linkLabel != null && linkUrl != null) {
        TapGestureRecognizer? recognizer;
        final handler = widget.onTapLink;
        if (handler != null) {
          recognizer = TapGestureRecognizer()..onTap = () => handler(linkUrl);
          _recognizers.add(recognizer);
        }
        spans.add(
          TextSpan(
            text: linkLabel,
            recognizer: recognizer,
            style: boldStyle.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      } else if (boldItalic != null) {
        spans.add(
          TextSpan(
            text: boldItalic,
            style: boldStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (boldA != null || boldB != null) {
        spans.add(TextSpan(text: boldA ?? boldB, style: boldStyle));
      } else if (italic != null) {
        spans.add(
          TextSpan(
            text: italic,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    return spans;
  }

  Widget _buildRichText(
    BuildContext context,
    String text, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    return SelectableText.rich(
      TextSpan(
        style: baseStyle,
        children: _buildInlineSpans(
          context,
          text,
          baseStyle: baseStyle,
          boldStyle: boldStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final colorScheme = context.colorScheme;
    final blocks = _parseBlocks(widget.source);
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    final bodyRegular = AppTextStyle.subheadline
        .of(context)
        .copyWith(color: colorScheme.onSurface, height: 1.5);
    final bodyBold = AppTextStyle.subheadline
        .of(context, emphasized: true)
        .copyWith(color: colorScheme.onSurface, height: 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final block in blocks)
          switch (block) {
            _MdHeading(:final level, :final text) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _buildRichText(
                context,
                text,
                baseStyle: switch (level) {
                  1 => AppTextStyle.title3.of(context, emphasized: true),
                  2 => AppTextStyle.headline.of(context, emphasized: true),
                  _ => AppTextStyle.subheadline.of(context, emphasized: true),
                }.copyWith(color: colorScheme.onSurface),
                boldStyle: switch (level) {
                  1 => AppTextStyle.title3.of(context, emphasized: true),
                  2 => AppTextStyle.headline.of(context, emphasized: true),
                  _ => AppTextStyle.subheadline.of(context, emphasized: true),
                }.copyWith(color: colorScheme.onSurface),
              ),
            ),
            _MdParagraph(:final text) => _buildRichText(
              context,
              text,
              baseStyle: bodyRegular,
              boldStyle: bodyBold,
            ),
            _MdQuote(:final text) => DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.surfaceContainerLow,
                shape: AppShape.all(AppCorner.md).copyWith(
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: _buildRichText(
                  context,
                  text,
                  baseStyle: bodyRegular.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  boldStyle: bodyBold.copyWith(color: colorScheme.onSurface),
                ),
              ),
            ),
            _MdList(:final items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                for (final item in items)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          item.marker,
                          textAlign: TextAlign.end,
                          style: bodyBold.copyWith(color: colorScheme.primary),
                        ),
                      ),
                      Expanded(
                        child: _buildRichText(
                          context,
                          item.text,
                          baseStyle: bodyRegular,
                          boldStyle: bodyBold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            _MdCodeBlock(:final code) => DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.surfaceContainerLow,
                shape: AppShape.all(AppCorner.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  code,
                  style: AppTextStyle.footnote
                      .of(context)
                      .copyWith(
                        fontFamily: FontFamily.jetBrainsMono.value,
                        color: colorScheme.onSurface,
                        height: 1.45,
                      ),
                ),
              ),
            ),
            _MdDivider() => Container(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          },
      ],
    );
  }
}

sealed class _MdBlock {
  const _MdBlock();
}

final class _MdHeading extends _MdBlock {
  final int level;
  final String text;

  const _MdHeading({required this.level, required this.text});
}

final class _MdParagraph extends _MdBlock {
  final String text;

  const _MdParagraph(this.text);
}

final class _MdQuote extends _MdBlock {
  final String text;

  const _MdQuote(this.text);
}

final class _MdList extends _MdBlock {
  final List<({String marker, String text})> items;

  const _MdList(this.items);
}

final class _MdCodeBlock extends _MdBlock {
  final String code;

  const _MdCodeBlock(this.code);
}

final class _MdDivider extends _MdBlock {
  const _MdDivider();
}
