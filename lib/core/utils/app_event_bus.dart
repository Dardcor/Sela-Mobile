import 'dart:async';

/// Global event bus for broadcasting application-wide events.
/// This is a Singleton that lives for the entire application lifecycle.
class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void fire(String event) {
    _controller.sink.add(event);
  }
}


