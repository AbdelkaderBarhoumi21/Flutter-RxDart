import 'package:rxdart/rxdart.dart';

/// Extension to manage loading state for any Stream.
///
/// This extension adds a [setLoadingTo] method to all Streams that allows you to
/// automatically update a loading state sink whenever the stream emits a value.
///
/// **How it works:**
/// - Uses [doOnEach] to trigger a side-effect for each value emitted by the stream
/// - Sends the [isLoading] boolean to the provided [onSink]
/// - The original stream values pass through unchanged
///
/// **Typical Usage Pattern:**
/// ```dart
///  1. Set loading to true at the start
/// _isLoading.add(true);
///
///  2. Make the API call and automatically set loading to false when data arrives
/// apiCall()
///   .setLoadingTo(false, onSink: _isLoading.sink)
///   .listen((data) {
///     Handle the data
///   });
/// ```
///
/// **Example:**
/// ```dart
/// class AuthBloc {
///   final _isLoading = BehaviorSubject<bool>.seeded(false);
///   Stream<bool> get isLoading => _isLoading.stream;
///
///   void login(String email, String password) {
///     _isLoading.add(true); // Show loading spinner
///
///     Stream.fromFuture(
///       FirebaseAuth.instance.signInWithEmailAndPassword(
///         email: email,
///         password: password,
///       )
///     )
///     .setLoadingTo(false, onSink: _isLoading.sink) // Hide loading when done
///     .listen(
///       (credential) => print('Logged in!'),
///       onError: (error) => _isLoading.add(false), // Also hide on error
///     );
///   }
/// }
/// ```
extension Loading<E> on Stream<E> {
  /// Sends a loading state to the provided [onSink] whenever this stream emits a value.
  ///
  /// **Parameters:**
  /// - [isLoading]: The boolean value to send to the sink (typically `false` to indicate loading is complete)
  /// - [onSink]: The sink where the loading state will be sent
  ///
  /// **Returns:** The original stream with the side-effect applied (values unchanged)
  Stream<E> setLoadingTo(bool isLoading, {required Sink<bool> onSink}) =>
      doOnEach((_) {
        onSink.add(isLoading);
      });
}
