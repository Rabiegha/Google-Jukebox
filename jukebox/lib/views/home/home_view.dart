import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jukebox/models/song_model.dart';
import 'package:jukebox/styles/size_config.dart';
import 'package:jukebox/views/home/widgets/player_widget.dart';

import 'widgets/categories_list.dart';
import 'widgets/songs_list.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<SongModel> songs = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            width: SizeConfig.screenWidth,
            height: SizeConfig.screenHeight,
            padding: const EdgeInsets.all(50),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/bg.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Row(
              children: [
                const CategoriesList(),
                SongsList(scaffoldKey: _scaffoldKey),
                const PlayerWidget(),
              ],
            ),
          ),
          Positioned(
            top: 180,
            right: -300,
            child: Image.asset(
              'assets/images/people.png',
            ),
          ),
          Positioned(
            right: 20,
            top: 55,
            child: Image.asset(
              'assets/images/gemini_logo.png',
              width: 90,
            ),
          ),
          Positioned(
            right: 130,
            top: 50,
            child: Image.asset(
              'assets/images/digital_lab.png',
              width: 150,
            ),
          ),
        ],
      ),
    );
  }
}
