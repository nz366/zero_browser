class TimeOut {
  final Duration? maxDuration;

  TimeOut({this.maxDuration}) : startTime = DateTime.now();

  final DateTime startTime;

  bool get isExpired => maxDuration == null
      ? false
      : startTime.add(maxDuration!).isBefore(DateTime.now());
}

extension DateTimeUtils on DateTime {
  String toRelativeTime(DateTime now) {
    final difference = now.difference(this);
    if (difference.inMinutes < 60) return "${difference.inMinutes}m";
    if (difference.inHours < 24) return "${difference.inHours}h";
    return "${difference.inDays}d";
  }
}
