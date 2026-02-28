import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/features/views/presentation/bloc/current_view.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class ViewsBloc {
  final Sink<CurrentView> goToView;
  final Stream<CurrentView> currentView;



  factory ViewsBloc() {
    // BehaviorSubject impl Sink that's why it can write without .sink =>controller.add(10);
    // Like => StreamController which can't write without using .sink => controller.sink.add(10);
    // .seeded mean that add value that can access it // stream.value = CurrentView.login without this stream.value Error
    // is not the value that been startWith the stream like startWith with the values emitted once stream start (default value )
    final goToViewSubject = BehaviorSubject<CurrentView>.seeded(
      CurrentView.login,
    );
    return ViewsBloc._(
      goToView: goToViewSubject.sink,
      currentView: goToViewSubject.startWith(CurrentView.login),
    );
  }

  const ViewsBloc._({required this.goToView, required this.currentView});
  void dispose() {
    goToView.close();
  }
}
