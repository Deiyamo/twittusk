import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:twittusk/domain/models/tusk.dart';
import 'package:twittusk/domain/models/user.dart';
import 'package:twittusk/domain/repository/notification_repository.dart';
import 'package:twittusk/domain/repository/tusk_repository.dart';

part 'feed_event.dart';

part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final TuskRepository tuskRepository;
  final NotificationRepository notificationRepository;

  FeedBloc({
    required this.tuskRepository,
    required this.notificationRepository,
  }) : super(FeedState.initial()) {
      on<FeedFetchEvent>(_fetchTusks);
      on<UserFeedFetchEvent>(_fetchTusksByUser);
      on<FeedLikeEvent>(_likeTusk);
      on<FeedShareEvent>(_shareTusk);
  }

  void _fetchTusks(FeedFetchEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.loading));
    try {
      await emit.forEach(tuskRepository.getTusks(), onData: (tusks) {
        return state.copyWith(tusks: tusks, status: FeedStatus.success);
      }).catchError((error) {
        emit(state.copyWith(
          errorMessage: error.toString(),
          status: FeedStatus.error,
        ));
      });
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        status: FeedStatus.error,
      ));
    }
  }

  void _likeTusk(FeedLikeEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.actionLoading));
    try {
      final likes = await tuskRepository.getMyLikesByTusk(event.tuskId);

      if (likes.isEmpty) {
        await tuskRepository.addLike(event.tuskId, event.isLiked);
        if(event.isLiked) {
          await notificationRepository.sendMessageFromTuskId(
            event.tuskId,
            'Someone liked your tusk',
            'Your tusk has been liked',
          );
        }
      } else {
        for(var like in likes) {
          await tuskRepository.removeLike(like.id, event.tuskId);
        }
        await tuskRepository.addLike(event.tuskId, event.isLiked);
      }
      emit(state.copyWith(status: FeedStatus.actionSuccess));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        status: FeedStatus.error,
      ));
    }
  }

  void _shareTusk(FeedShareEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.actionLoading));
    try {
      final link = await tuskRepository.generateTuskDynamicLink(event.tuskId);
      emit(state.copyWith(status: FeedStatus.dynamicLinkSuccess, dynamicLink: link));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        status: FeedStatus.error,
      ));
    }
  }

  void _fetchTusksByUser(UserFeedFetchEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.loading));
    try {
      print('In IT');
      await emit.forEach(tuskRepository.getTusksByUser(event.user), onData: (tusks) {
        print('On data');
        print(tusks);
        return state.copyWith(tusks: tusks, status: FeedStatus.success);
      }).catchError((error) {
        emit(state.copyWith(
          errorMessage: error.toString(),
          status: FeedStatus.error,
        ));
      });
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
        status: FeedStatus.error,
      ));
    }
  }
}
