import 'dart:developer';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/blocs/player_cubit/player_cubit.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';
import 'package:jukebox/models/song_model.dart';
import 'package:jukebox/styles/size_config.dart';
import 'package:jukebox/views/home/widgets/play_button.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ListenSongWidget extends StatefulWidget {
  const ListenSongWidget({
    super.key,
    required this.song,
  });

  final SongModel song;

  @override
  State<ListenSongWidget> createState() => _ListenSongWidgetState();
}

class _ListenSongWidgetState extends State<ListenSongWidget> {
  late final PlayerCubit _playerCubit;
  late TextEditingController emailCtrl;

  static const _defaultCover =
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Placeholder_view_vector.svg/1200px-Placeholder_view_vector.svg.png';

  String _getCover() {
    final song = _playerCubit.actifSong.value ?? widget.song;
    if (song.cover.isEmpty || song.cover == 'default_cover') return _defaultCover;
    return song.cover;
  }

  @override
  void initState() {
    _playerCubit = context.read<PlayerCubit>();
    emailCtrl = TextEditingController();
    super.initState();
  }

  Widget _getPlayPauseButton(PlayerState state) {
    if (state is AudioPlayerLoading) {
      return const SizedBox(
        key: ValueKey(10),
        width: 45,
        height: 40,
        child: CircularProgressIndicator.adaptive(),
      );
    } else if (state is AudioPlayerPlaying) {
      return PlayerButton(
        icon: Icons.pause_rounded,
        onPressed: () {
          _playerCubit.pause();
        },
        size: 60,
        iconSize: 40,
      );
    } else if (state is AudioPlayerPaused) {
      return PlayerButton(
        icon: Icons.play_arrow_rounded,
        onPressed: () {
          _playerCubit.resume();
        },
        size: 60,
        iconSize: 40,
      );
    }
    return PlayerButton(
      icon: Icons.play_arrow_rounded,
      onPressed: () {
        if (_playerCubit.actifSong.value != null) {
          _playerCubit.play(_playerCubit.actifSong.value!);
        }
      },
      size: 60,
      iconSize: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return AlertDialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: ValueListenableBuilder(
          valueListenable: _playerCubit.actifSong,
          builder: (context, _, __) {
            return BlocBuilder<PlayerCubit, PlayerState>(
              bloc: _playerCubit,
              builder: (context, state) {
                return Stack(
                  children: [
                    Container(
                      height: SizeConfig.screenHeight! - 100,
                      width: SizeConfig.screenWidth! - 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEADFB1),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                            _getCover(),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 10,
                            sigmaY: 10,
                          ),
                          child: SizedBox(
                            height: SizeConfig.blockSizeV! * 100,
                            width: SizeConfig.blockSizeH! * 100,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: SizeConfig.screenHeight! - 100,
                      width: SizeConfig.screenWidth! - 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black,
                            Colors.black.withOpacity(0),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      height: 260,
                                      width: 260,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(
                                            _getCover(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: 500,
                                      child: StreamBuilder(
                                        stream: _playerCubit
                                            .audioPlayer.positionStream,
                                        builder: (context, snapshot) {
                                          return ProgressBar(
                                            thumbRadius: 7,
                                            thumbGlowRadius: 9,
                                            progressBarColor:
                                                Colors.white.withOpacity(1),
                                            barHeight: 4,
                                            thumbColor:
                                                Colors.white.withOpacity(1),
                                            baseBarColor:
                                                Colors.white.withOpacity(0.5),
                                            bufferedBarColor:
                                                Colors.white.withOpacity(0.7),
                                            timeLabelLocation:
                                                TimeLabelLocation.below,
                                            timeLabelTextStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            timeLabelPadding: 7,
                                            progress:
                                                snapshot.data ?? Duration.zero,
                                            total: _playerCubit
                                                    .audioPlayer.duration ??
                                                Duration.zero,
                                            onSeek: (duration) async {
                                              await _playerCubit.audioPlayer
                                                  .seek(duration);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    Text(
                                      'By ${(_playerCubit.actifSong.value ?? widget.song).creator}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      (_playerCubit.actifSong.value ?? widget.song).title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 25,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      (_playerCubit.actifSong.value ?? widget.song).genre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        PlayerButton(
                                          icon: Icons.skip_previous,
                                          onPressed: () {
                                            _playerCubit.previous();
                                          },
                                          size: 40,
                                        ),
                                        const SizedBox(width: 30),
                                        _getPlayPauseButton(state),
                                        const SizedBox(width: 30),
                                        PlayerButton(
                                          icon: Icons.skip_next,
                                          onPressed: () {
                                            _playerCubit.next();
                                          },
                                          size: 40,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        CupertinoButton(
                                          child: const Row(
                                            children: [
                                              Text(
                                                'Share',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.share,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ],
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  ShareEmailWidget(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    // Padding(
                                    //   padding:
                                    //       const EdgeInsets.symmetric(horizontal: 150),
                                    //   child: Row(
                                    //     children: [
                                    //       Expanded(
                                    //   child: TextField(
                                    //     controller: emailCtrl,
                                    //     decoration: InputDecoration(
                                    //       hintText:
                                    //           'Enter your email address if you want to receive your song by email',
                                    //       hintStyle: const TextStyle(
                                    //           color: Colors.black),
                                    //       border: InputBorder.none,
                                    //       filled: true,
                                    //       fillColor:
                                    //           Colors.white.withOpacity(0.8),
                                    //     ),
                                    //   ),
                                    // ),
                                    //       const SizedBox(width: 20),
                                    //       BlocConsumer<SongCubit, SongState>(
                                    //         bloc: _songCubit,
                                    //         listener: (context, state) {},
                                    //         builder: (context, state) {
                                    //           return CupertinoButton(
                                    //             padding: EdgeInsets.zero,
                                    //             child: Container(
                                    //               padding: const EdgeInsets.symmetric(
                                    //                 vertical: 13,
                                    //                 horizontal: 15,
                                    //               ),
                                    //               color: const Color(0XFFAD402B),
                                    //               child: state is SendMailLoading
                                    //                   ? const Center(
                                    //                       child:
                                    //                           CircularProgressIndicator(),
                                    //                     )
                                    //                   : Text(
                                    //                       'Send me by mail',
                                    //                       style: GoogleFonts.nunito(
                                    //                         color: Colors.white,
                                    //                         fontWeight:
                                    //                             FontWeight.bold,
                                    //                         fontSize: 16,
                                    //                       ),
                                    //                     ),
                                    //             ),
                                    //             onPressed: () {
                                    //               if (state is! SendMailLoading) {
                                    //                 if (emailCtrl.text.isNotEmpty) {
                                    //                   _songCubit.sendMail(
                                    //                     widget.song.id,
                                    //                     emailCtrl.text,
                                    //                     widget.song.genre,
                                    //                   );
                                    //                 }
                                    //               }
                                    //             },
                                    //           );
                                    //         },
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }),
    );
  }
}

class ShareEmailWidget extends StatefulWidget {
  const ShareEmailWidget({super.key});

  @override
  State<ShareEmailWidget> createState() => _ShareEmailWidgetState();
}

class _ShareEmailWidgetState extends State<ShareEmailWidget> {
  late final TextEditingController emailCtrl;
  late final PlayerCubit _playerCubit;
  late final SongCubit _songCubit;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController();
    _playerCubit = context.read<PlayerCubit>();
    _songCubit = SongCubit();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SongCubit, SongState>(
      bloc: _songCubit,
      listener: (context, state) {
        if (state is SendMailSuccess) {
          Navigator.pop(context);

          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.success(
              message:
                  "Good job, an email has been sent to you Have a nice day",
            ),
          );
        } else if (state is SendMailError) {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.error(
              message:
                  "Oups. Something went wrong when sending email. Please try again.",
            ),
          );
        }
      },
      builder: (context, state) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          content: IntrinsicWidth(
            child: IntrinsicHeight(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 50,
                  horizontal: 100,
                ),
                // width: 500,
                child: Column(
                  children: [
                    const Text(
                      'Enter your email address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      autofocus: true,
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(height: 15),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        color: const Color(0xffAD402B),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: state is SendMailLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                textAlign: TextAlign.center,
                                'Share',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                      onPressed: () {
                        if (state is! SendMailLoading &&
                            emailCtrl.text.isNotEmpty) {
                          _songCubit.sendMail(
                            _playerCubit.actifSong.value!.id,
                            emailCtrl.text,
                            _playerCubit.actifSong.value!.genre,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
