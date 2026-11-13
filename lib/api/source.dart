import '../models.dart';
import 'xtream_api.dart';
import 'm3u_source.dart';

/// Common interface for where content comes from (Xtream login or M3U list).
abstract class ContentSource {
  Account get account;

  Future<AccountInfo?> accountInfo();
  Future<List<Category>> categories(ContentType type);
  Future<List<StreamItem>> streams(ContentType type, {String? categoryId});
  Future<MovieInfo> movieInfo(StreamItem item);
  Future<SeriesInfo> seriesInfo(StreamItem item);
  Future<List<EpgEntry>> shortEpg(StreamItem channel);
  /// Full guide (past and future) for one channel.
  Future<List<EpgEntry>> fullEpg(StreamItem channel);
  /// URL to watch a past program again (catch-up), or '' if not possible.
  String catchupUrl(StreamItem channel, EpgEntry entry);
  String streamUrl(StreamItem item);
  String episodeUrl(Episode ep);

  static ContentSource forAccount(Account a) =>
      a.type == AccountType.xtream ? XtreamSource(a) : M3uSource(a);
}
