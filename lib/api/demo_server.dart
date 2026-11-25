import 'dart:convert';
import 'dart:typed_data';

import '../models.dart';

/// Built-in demo account for App Store review.
///
/// Server http://test.test, username test, password test logs in without
/// any network server and shows a few free, openly licensed sample videos
/// (Blender open movies, Creative Commons, and public HLS test streams), so
/// a reviewer can try live TV, movies, series and the player.
/// Nothing here is shown unless exactly these details are typed in.
class DemoServer {
  static const host = 'test.test';
  static const user = 'test';
  static const pass = 'test';

  static bool isDemo(Account a) {
    final h = Uri.tryParse(a.server)?.host.toLowerCase() ?? '';
    return h == host && a.username == user && a.password == pass;
  }

  static const _gtv = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample';

  static const _live = [
    {
      'id': '1',
      'name': 'Demo Live 1 (Apple test stream)',
      'cat': '1',
      'url': 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
      'icon': '$_gtv/images/BigBuckBunny.jpg',
    },
    {
      'id': '2',
      'name': 'Demo Live 2 (Akamai test stream)',
      'cat': '1',
      'url': 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      'icon': '$_gtv/images/ElephantsDream.jpg',
    },
    {
      'id': '3',
      'name': 'Demo Live 3 (Big Buck Bunny HLS)',
      'cat': '2',
      'url': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      'icon': '$_gtv/images/BigBuckBunny.jpg',
    },
  ];

  static const _movies = [
    {
      'id': '101',
      'name': 'Big Buck Bunny',
      'file': 'BigBuckBunny',
      'year': '2008',
      'plot': 'A large rabbit deals with three bullying rodents. Blender Foundation open movie (CC BY 3.0).',
      'secs': 596,
    },
    {
      'id': '102',
      'name': 'Elephants Dream',
      'file': 'ElephantsDream',
      'year': '2006',
      'plot': 'Two men explore a strange mechanical world. Blender Foundation open movie (CC BY 2.5).',
      'secs': 653,
    },
    {
      'id': '103',
      'name': 'Sintel',
      'file': 'Sintel',
      'year': '2010',
      'plot': 'A girl searches for her lost baby dragon. Blender Foundation open movie (CC BY 3.0).',
      'secs': 888,
    },
    {
      'id': '104',
      'name': 'Tears of Steel',
      'file': 'TearsOfSteel',
      'year': '2012',
      'plot': 'Scientists try to save the world from robots. Blender Foundation open movie (CC BY 3.0).',
      'secs': 734,
    },
  ];

  static Map<String, dynamic> _movie(String id) =>
      _movies.firstWhere((m) => m['id'] == id, orElse: () => _movies.first);

  static String _cover(Map m) => '$_gtv/images/${m['file']}.jpg';

  /// Answer to a player_api.php request, as the real server would send it.
  static Uint8List respond(Map<String, String> params) {
    final action = params['action'] ?? '';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    dynamic out;
    switch (action) {
      case '':
        out = {
          'user_info': {
            'username': user,
            'auth': 1,
            'status': 'Active',
            'exp_date': '${now + 365 * 24 * 3600}',
            'max_connections': '1',
            'active_cons': '0',
            'allowed_output_formats': ['m3u8'],
            'message': 'Demo account with free sample videos',
          },
          'server_info': {'url': host, 'server_protocol': 'http'},
        };
      case 'get_live_categories':
        out = [
          {'category_id': '1', 'category_name': 'Demo Live'},
          {'category_id': '2', 'category_name': 'Demo Test Streams'},
        ];
      case 'get_vod_categories':
        out = [
          {'category_id': '10', 'category_name': 'Open Movies'},
        ];
      case 'get_series_categories':
        out = [
          {'category_id': '20', 'category_name': 'Demo Series'},
        ];
      case 'get_live_streams':
        out = [
          for (final c in _live)
            if (params['category_id'] == null || params['category_id'] == c['cat'])
              {
                'stream_id': c['id'],
                'name': c['name'],
                'stream_icon': c['icon'],
                'category_id': c['cat'],
                'epg_channel_id': '',
                'stream_type': 'live',
                'tv_archive': 0,
                'added': '$now',
              },
        ];
      case 'get_vod_streams':
        out = [
          for (final m in _movies)
            {
              'stream_id': m['id'],
              'name': m['name'],
              'stream_icon': _cover(m),
              'category_id': '10',
              'container_extension': 'mp4',
              'rating': '7',
              'added': '$now',
            },
        ];
      case 'get_vod_info':
        final m = _movie(params['vod_id'] ?? '');
        out = {
          'info': {
            'plot': m['plot'],
            'director': 'Blender Foundation',
            'genre': 'Animation',
            'releasedate': m['year'],
            'duration_secs': m['secs'],
            'rating': '7',
            'movie_image': _cover(m),
          },
        };
      case 'get_series':
        out = [
          {
            'series_id': '201',
            'name': 'Blender Open Movies',
            'cover': '$_gtv/images/Sintel.jpg',
            'category_id': '20',
            'rating': '7',
            'last_modified': '$now',
          },
        ];
      case 'get_series_info':
        out = {
          'info': {
            'plot': 'Short open movies by the Blender Foundation, shared under Creative Commons licenses.',
            'genre': 'Animation',
            'cover': '$_gtv/images/Sintel.jpg',
            'rating': '7',
          },
          'episodes': {
            '1': [
              for (var i = 0; i < _movies.length; i++)
                {
                  'id': _movies[i]['id'],
                  'title': _movies[i]['name'],
                  'season': 1,
                  'episode_num': i + 1,
                  'container_extension': 'mp4',
                  'info': {'plot': _movies[i]['plot'], 'movie_image': _cover(_movies[i])},
                },
            ],
          },
        };
      case 'get_short_epg':
      case 'get_simple_data_table':
        out = {'epg_listings': []};
      default:
        out = [];
    }
    return Uint8List.fromList(utf8.encode(jsonEncode(out)));
  }

  /// Real video address for a demo item.
  static String streamUrl(StreamItem item) {
    switch (item.type) {
      case ContentType.live:
        return _live.firstWhere((c) => c['id'] == item.id, orElse: () => _live.first)['url']!;
      case ContentType.movie:
        return '$_gtv/${_movie(item.id)['file']}.mp4';
      case ContentType.series:
        return '';
    }
  }

  static String episodeUrl(Episode ep) => '$_gtv/${_movie(ep.id)['file']}.mp4';
}
