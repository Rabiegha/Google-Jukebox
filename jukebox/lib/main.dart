import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/blocs/category_cubit/category_cubit.dart';
import 'package:jukebox/blocs/player_cubit/player_cubit.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';
import 'package:jukebox/config/app_config.dart';
import 'package:jukebox/views/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app configuration (load .env file)
  // Use 'local' for development, 'prod' for production
  await AppConfig.init(env: 'local');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CategoryCubit()),
        BlocProvider(create: (context) => SongCubit()),
        BlocProvider(create: (context) => PlayerCubit()),
      ],
      child: const MaterialApp(
        title: 'Jukebox',
        home: HomeView(),
      ),
    );
  }
}
