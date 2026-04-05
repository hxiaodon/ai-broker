import 'package:freezed_annotation/freezed_annotation.dart';

part 'news_article.freezed.dart';

/// A single news article related to a stock symbol.
///
/// [publishedAt] is always UTC (converted in mapper from ISO 8601 string).
@freezed
abstract class NewsArticle with _$NewsArticle {
  const factory NewsArticle({
    required String id,
    required String title,
    required String summary,
    required String source,
    required DateTime publishedAt,
    required String url,
  }) = _NewsArticle;
}
