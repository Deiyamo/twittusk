import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:twittusk/data/data_source/firebase/firebase_notification_data_source.dart';
import 'package:twittusk/data/repository/firebase/firebase_notification_repository.dart';
import 'package:twittusk/data/repository/firebase/firebase_tusk_repository.dart';
import 'package:twittusk/presentation/screens/logic/current_user_bloc/current_user_bloc.dart';
import 'package:twittusk/presentation/screens/logic/edit_profile_bloc/edit_profile_bloc.dart';
import 'package:twittusk/presentation/screens/logic/feed_bloc/feed_bloc.dart';
import 'package:twittusk/presentation/screens/logic/login_bloc/login_bloc.dart';
import 'package:twittusk/presentation/screens/ui/add_tusk_screen/add_tusk_screen.dart';
import 'package:twittusk/presentation/screens/logic/profile_feed_bloc/profile_feed_bloc.dart';
import 'package:twittusk/presentation/screens/logic/tusk_bloc/tusk_bloc.dart';
import 'package:twittusk/presentation/screens/ui/edit_profile/edit_profile_screen.dart';
import 'package:twittusk/presentation/screens/ui/login_screen/login_screen.dart';
import 'package:twittusk/presentation/screens/ui/nav_screen/nav_screen.dart';
import 'package:twittusk/presentation/screens/ui/profile_feed_screen/profile_feed_screen.dart';
import 'package:twittusk/presentation/screens/ui/tusk_screen/tusk_screen.dart';
import 'package:twittusk/theme/theme.dart';
import 'data/data_source/firebase/firebase_tusk_data_source.dart';
import 'package:twittusk/domain/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");
  await Firebase.initializeApp();
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  final homeScreen = FirebaseAuth.instance.currentUser == null
      ? const LoginScreen()
      : const NavScreen();
  runApp(MyApp(homeScreen: homeScreen));
}

class MyApp extends StatelessWidget {
  final Widget homeScreen;

  const MyApp({super.key, this.homeScreen = const LoginScreen()});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FeedBloc>(
          create: (context) => FeedBloc(
            tuskRepository: FirebaseTuskRepository(
              FirebaseTuskDataSource(),
            ),
            notificationRepository: FirebaseNotificationRepository(
              FirebaseNotificationDataSource(),
            ),
          ),
        ),
        BlocProvider<ProfileFeedBloc>(
          create: (context) => ProfileFeedBloc(
            FirebaseTuskRepository(
              FirebaseTuskDataSource(),
            ),
          ),
        ),
        BlocProvider<TuskBloc>(
          create: (context) => TuskBloc(
            tuskRepository: FirebaseTuskRepository(
              FirebaseTuskDataSource(),
            ),
            notificationRepository: FirebaseNotificationRepository(
              FirebaseNotificationDataSource(),
            ),
          ),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(
            repository: FirebaseTuskRepository(
              FirebaseTuskDataSource(),
            ),
            notificationRepository: FirebaseNotificationRepository(
              FirebaseNotificationDataSource(),
            ),
          ),
        ),
        BlocProvider<CurrentUserBloc>(
          create: (context) => CurrentUserBloc(
            tuskRepository: FirebaseTuskRepository(
              FirebaseTuskDataSource(),
            ),
            notificationRepository: FirebaseNotificationRepository(
              FirebaseNotificationDataSource(),
            ),
          ),
        ),
        BlocProvider<EditProfileBloc>(
          create: (context) => EditProfileBloc(
            FirebaseTuskRepository(
              FirebaseTuskDataSource(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Twittusk',
        theme: AppTheme.darkThemeData,
        debugShowCheckedModeBanner: false,
        // home: ProfileFeedScreen(user: User(uid: 'uid', username: 'Elon Musk', arobase: 'ElonMusk', email: 'email', profilePicUri: 'https://www.thestreet.com/.image/ar_1:1%2Cc_fill%2Ccs_srgb%2Cfl_progressive%2Cq_auto:good%2Cw_1200/MTg4NzYwNTI4NjE5ODQxMDU2/elon-musk_4.jpg', bannerPicUri: 'https://img.phonandroid.com/2021/08/spacex-starship.jpg', bio: 'bio'),),
        routes: {
          '/': (context) => homeScreen,
          NavScreen.routeName: (context) => const NavScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          AddTuskScreen.routeName: (context) => const AddTuskScreen(),
          EditProfileScreen.routeName: (context) => EditProfileScreen(),
          // FeedScreen.routeName: (context) => const FeedScreen(),
        },
        onGenerateRoute: (settings) {
          Widget content = const SizedBox.shrink();

          switch (settings.name) {
            case ProfileFeedScreen.routeName:
              final arguments = settings.arguments;
              if (arguments != null && arguments is User) {
                content = ProfileFeedScreen(user: arguments);
              }
            case TuskScreen.routeName:
              final arguments = settings.arguments;
              if (arguments != null && arguments is String) {
                content = TuskScreen(idTusk: arguments);
              }
          }
          return MaterialPageRoute(builder: (context) => content);
        },
      ),
    );
  }



}
