import 'package:flutter/widgets.dart';
import 'package:zero_browser/client/client.dart';

class ClientEventPhase {
  final ConnectionState type;
  final DateTime time;
  const ClientEventPhase(this.type, this.time);
}

class ClientEvent {
  final String id;
  final String url;
  final List<ClientEventPhase> phases;

  bool failed = false;
  int? statusCode;
  int? size;
  String? contentEncoding;

  ClientEvent({required this.id, required this.url})
    : phases = [ClientEventPhase(ConnectionState.waiting, DateTime.now())];

  void _addPhase(ConnectionState type, DateTime time) {
    if (phases.isNotEmpty && !time.isAfter(phases.last.time)) return;
    phases.add(ClientEventPhase(type, time));
  }

  Duration get totalDuration =>
      phases.lastOrNull?.time.difference(
        phases.firstOrNull?.time ?? phases.last.time,
      ) ??
      Duration.zero;
}

class EventStore {
  final Map<String, ClientEvent> events = {};
  DateTime? pageStart;

  void start(String url) {
    final id = '$url#${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    pageStart ??= now;
    events[id] = ClientEvent(id: id, url: url);
  }

  void end(String url) {
    events[url]?._addPhase(ConnectionState.done, DateTime.now());
  }
}

class EventRecordingClient extends Client {
  EventStore events = EventStore();

  Future<ResponseDetails> _trackRequest(
    String key,
    Future<ResponseDetails> Function() requestFn,
  ) async {
    events.start(key);
    final res = requestFn();
    final v = await res;
    events.end(key);
    return v;
  }

  @override
  Future<ResponseDetails> httpRequest(String url, {bool throwError = false}) {
    return _trackRequest(
      url,
      () => super.httpRequest(url, throwError: throwError),
    );
  }

  @override
  Future<ResponseDetails> httpUriRequest(Uri url, {bool throwError = false}) {
    return _trackRequest(
      url.toString(),
      () => super.httpUriRequest(url, throwError: throwError),
    );
  }

  @override
  Future<ResponseDetails> localRequest(String path) {
    return _trackRequest(path, () => super.localRequest(path));
  }

  @override
  Future<ResponseDetails> markdownRequest(String url) {
    return _trackRequest(url, () => super.markdownRequest(url));
  }
}
