import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// Network image with a quiet placeholder.
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData fallback;
  const NetImage(this.url,
      {super.key, this.fit = BoxFit.cover, this.fallback = Icons.tv});

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      color: const Color(0xFF232937),
      alignment: Alignment.center,
      child: Icon(fallback, color: Colors.white24),
    );
    if (url.isEmpty || !url.startsWith('http')) return ph;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => ph,
      errorWidget: (_, _, _) => ph,
    );
  }
}

/// Shows loading, error with retry, or content for a Future.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  const AsyncView({super.key, required this.load, required this.builder});

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ErrorRetry(
            message: friendlyError(snap.error),
            onRetry: () => setState(() => _f = widget.load()),
          );
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}

String friendlyError(Object? e) {
  final s = e.toString().replaceFirst('Exception: ', '');
  if (s.contains('TimeoutException')) return 'The server took too long to reply.';
  if (s.contains('SocketException') || s.contains('ClientException')) {
    return 'Could not reach the server. Check your internet or server address.';
  }
  return s;
}

void toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(msg)));

class EmptyView extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyView(this.text, {super.key, this.icon = Icons.inbox});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.white54)),
        ]),
      );
}

String fmtTime(DateTime t, bool use24h) {
  final m = t.minute.toString().padLeft(2, '0');
  if (use24h) return '${t.hour.toString().padLeft(2, '0')}:$m';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}
