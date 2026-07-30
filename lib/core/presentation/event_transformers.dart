import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Waits for a pause of [duration] before handling an event, discarding
/// everything that arrived during the pause.
///
/// The case this exists for is search-as-you-type: without it, "camera" is
/// six requests, five of them already stale by the time they return, and
/// whichever lands last wins regardless of what the user actually typed.
///
/// Built on `StreamTransformer` rather than pulling in rxdart — a debounce is
/// a timer and a cancel, which is not worth a dependency.
///
/// There is deliberately no `droppable` companion here: the base blocs
/// already refuse to start a fetch while `state.isBusy`, and expressing that
/// rule once, where the state lives, beats expressing it again in a
/// transformer that has to be remembered at every registration site.
EventTransformer<E> debounce<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) =>
      events.transform(_debounceTransformer<E>(duration)).asyncExpand(mapper);
}

StreamTransformer<E, E> _debounceTransformer<E>(Duration duration) {
  Timer? timer;
  return StreamTransformer<E, E>.fromHandlers(
    handleData: (E data, EventSink<E> sink) {
      timer?.cancel();
      timer = Timer(duration, () => sink.add(data));
    },
    handleDone: (EventSink<E> sink) {
      timer?.cancel();
      sink.close();
    },
  );
}
