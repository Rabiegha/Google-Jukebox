import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/blocs/category_cubit/category_cubit.dart';
import 'package:jukebox/blocs/player_cubit/player_cubit.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';
import 'package:jukebox/models/song_model.dart';
import 'package:lottie/lottie.dart';

import 'listen_song_widget.dart';

OverlayEntry listenMusicPopup(SongModel song) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (homeContext) => Positioned(
      bottom: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: Container(
            width: 310,
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(50, 50, 93, 0.4),
                  offset: Offset(0, 50),
                  blurRadius: 100,
                  spreadRadius: -20,
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                  offset: Offset(0, 30),
                  blurRadius: 60,
                  spreadRadius: -30,
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Lottie.asset(
                      'assets/images/dance.json',
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your creation is ready 🤩',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await homeContext.read<SongCubit>().getSongsByGenre(
                                    song.genre,
                                    homeContext.read<CategoryCubit>(),
                                    homeContext,
                                    activeSong: false,
                                  );

                              await homeContext.read<PlayerCubit>().play(song);

                              Navigator.of(homeContext)
                                  .popUntil((route) => route.isFirst);

                              showDialog(
                                context: homeContext,
                                builder: (homeContext) => ListenSongWidget(
                                  song: song,
                                ),
                              );

                              entry.remove();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Listen',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => entry.remove(),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return entry;
}
