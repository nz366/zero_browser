import 'dart:async';

import 'package:zero_browser/client/client.dart';

class CancelledException implements Exception {
  final String message;
  CancelledException([this.message = 'The operation was cancelled.']);

  @override
  String toString() => message;
}

/// A token that can be passed to async tasks to allow early exit
/// from `await` calls when cancelled.
class CancellationToken {
  final Completer<void> _completer = Completer<void>();

  /// Returns true if the token has been cancelled.
  bool get isCancelled => _completer.isCompleted;

  /// A future that completes with an error when cancelled.
  Future<DataResponse?> get whenCancelled =>
      _completer.future.then((e) => null);

  /// Cancels the execution, causing any `.run()` calls to immediately throw [CancelledException].
  void cancel() {
    if (!isCancelled) {
      _completer.completeError(CancelledException());
    }
  }

  /// Races [future] against the cancellation event.
  ///
  /// If the token is cancelled before [future] completes, this will throw a [CancelledException],
  /// effectively causing an early return from the `await`.
  ///
  /// Note: The original future will computationally continue in the background,
  /// but `run` will drop the result and exit the await immediately.
  Future<T> run<T>(Future<T> future) {
    if (isCancelled) {
      return Future.error(CancelledException());
    }

    // Future.any completes with the result or error of the first future to finish
    return Future.any([future, whenCancelled as Future<T>]);
  }
}
