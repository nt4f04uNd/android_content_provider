part of '../android_content_provider.dart';

/// Provides the ability to cancel an operation in progress
/// https://developer.android.com/reference/android/os/CancellationSignal
class CancellationSignal extends ReceivedCancellationSignal {
  /// Creates cancellation signal.
  CancellationSignal() : super._(_uuid.v4()) {
    _methodChannel = MethodChannel('$_channelPrefix/CancellationSignal/$id');
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  late final MethodChannel _methodChannel;

  /// Cancels the operation and signals the cancellation listener.
  /// If the operation has not yet started, then it will be canceled as soon as it does.
  void cancel() {
    if (_cancelled || _disposed) {
      return;
    }
    _cancelled = true;
    _cancelListener?.call();
    _initCompleter.operation.then((_) async {
      try {
        await _methodChannel.invokeMethod<void>('cancel', {'id': id});
      } catch (e) {
        // Ignore because the signal might be already disposed on native side
      } finally {
        dispose();
      }
    });
  }
}

/// A [CancellationSignal] that was created somewhere else and received by some client,
/// typically [AndroidContentProvider].
///
/// Can only be observed, and cannot be cancelled, because when such a signal is cancelled
/// by the receiver, the creator cannot listen to this cancel, and probably doesn't even expect this.
///
/// Also, if receiver wants to end the operation, it should be able to just return (or throw) explicitly,
/// instead of cancelling the signal, making this operation essentially useless.
class ReceivedCancellationSignal extends Interoperable {
  ReceivedCancellationSignal._(this._id);

  /// Creates cancellation signal from an existing ID.
  @visibleForTesting
  ReceivedCancellationSignal.fromId(this._id)
      : __methodChannel =
            MethodChannel('$_channelPrefix/CancellationSignal/$_id') {
    _initCompleter.complete();
    _methodChannel.setMethodCallHandler(_handleMethodCall);
    _methodChannel.invokeMethod<void>('init');
  }

  @override
  String get id => _id;
  final String _id;

  MethodChannel get _methodChannel => __methodChannel;
  late final MethodChannel __methodChannel;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CancellationSignal')}($id)';
  }

  /// Whether the operation is cancalled.
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  /// Completer to wait the initialization of the native signal.
  final _initCompleter = CancelableCompleter<void>();
  bool _disposed = false;

  VoidCallback? _cancelListener;

  /// Sets the cancellation [listener] to be called when canceled.
  ///
  /// If already cancelled, the listener will be called immediately
  void setCancelListener(VoidCallback? listener) {
    if (listener == _cancelListener) {
      return;
    }
    _cancelListener = listener;
    if (_cancelled) {
      listener?.call();
    }
  }

  /// Disposes the cancellation signal.
  ///
  /// This is called automatically by [AndroidContentResolver]
  /// when the method call ends.
  @mustCallSuper
  void dispose() {
    _disposed = true;
    _methodChannel.setMethodCallHandler(null);
    _initCompleter.operation.cancel();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'init':
        _initCompleter.complete();
        break;
      case 'cancel':
        if (!_cancelled) {
          _cancelled = true;
          _cancelListener?.call();
          _methodChannel.setMethodCallHandler(null);
        }
        break;
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Method not implemented: ${call.method}',
        );
    }
  }
}
