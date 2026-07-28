class TimeOut {
  final Duration? maxDuration;

  TimeOut({this.maxDuration}) : startTime = DateTime.now();

  final DateTime startTime;

  bool get isExpired => maxDuration == null
      ? false
      : startTime.add(maxDuration!).isBefore(DateTime.now());
}
