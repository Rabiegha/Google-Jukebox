import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jukebox/blocs/player_cubit/player_cubit.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';
import 'package:jukebox/styles/size_config.dart';
import 'package:jukebox/views/create_son/create_song.dart';
import 'package:mini_music_visualizer/mini_music_visualizer.dart';

class SongsList extends StatefulWidget {
  const SongsList({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  late final PlayerCubit _playerCubit;

  @override
  void initState() {
    super.initState();
    _playerCubit = context.read<PlayerCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _playerCubit.actifSong,
        builder: (context, _, __) {
          return BlocBuilder<SongCubit, SongState>(
            builder: (context, state) {
              return Container(
                height: SizeConfig.screenHeight,
                width: 300,
                decoration: const BoxDecoration(
                  // color: Colors.red,
                  image: DecorationImage(
                    image: AssetImage('assets/images/playlist.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 50,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    if (state is SongGetByGenreLoading)
                      const CircularProgressIndicator(strokeWidth: 2),
                    if (state is SongGetByGenreSuccess)
                      Row(
                        children: [
                          Text(
                            state.genre,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    Expanded(
                      child: state is SongGetByGenreSuccess
                          ? ListView.builder(
                              itemCount: state.songs.length,
                              itemBuilder: (context, index) {
                                final song = state.songs[index];
                                return BlocBuilder<PlayerCubit, PlayerState>(
                                  bloc: context.read<PlayerCubit>(),
                                  builder: (context, state) {
                                    return ListTile(
                                      onTap: () {
                                        context.read<PlayerCubit>().play(song);
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          image: DecorationImage(
                                            image: NetworkImage(song.cover),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'By ${song.creator}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: state is AudioPlayerPlaying &&
                                              context
                                                      .read<PlayerCubit>()
                                                      .actifSong
                                                      .value!
                                                      .id ==
                                                  song.id
                                          ? const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 30),
                                              child: SizedBox(
                                                width: 20,
                                                child: MiniMusicVisualizer(
                                                  color: Color(0xffAD402B),
                                                  radius: 10,
                                                  width: 4,
                                                  height: 15,
                                                  animate: true,
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    );
                                  },
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 35),
                      child: Divider(
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: 200,
                        height: 35,
                        color: const Color(0xffAD402B),
                        alignment: Alignment.center,
                        child: Text(
                          'Create new song',
                          style: GoogleFonts.jotiOne(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onPressed: () {
                        // showDialog(
                        //   context: context,
                        //   builder: (context) => const ListenSongWidget(
                        //     data: {
                        //       'cover': {
                        //         'cover':
                        //             'https://storage.googleapis.com/prompts_results/OkSCEMeYJhEeDSteEFND/1727776634568/sample_0.png',
                        //       },
                        //       'song': {
                        //         'id': 'OkSCEMeYJhEeDSteEFND',
                        //         'duration': 30,
                        //         'prompt': 'sdsdsd',
                        //         'title': 'Relax the cafe',
                        //         'audio':
                        //             'https://storage.googleapis.com/prompts_results/OkSCEMeYJhEeDSteEFND/output.wav',
                        //         'creator': 'Valdo',
                        //         'genre': 'Ambieinte',
                        //       },
                        //     },
                        //   ),
                        // );
                        showDialog(
                          context: context,
                          builder: (context) => CreateSonWidget(
                            scaffoldKey: widget.scaffoldKey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        });
  }
}
