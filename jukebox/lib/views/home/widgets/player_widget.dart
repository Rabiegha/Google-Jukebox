import 'dart:developer';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/blocs/player_cubit/player_cubit.dart';
import 'package:jukebox/styles/size_config.dart';
import 'package:jukebox/views/create_son/widgets/listen_song_widget.dart';
import 'package:jukebox/views/home/widgets/play_button.dart';
import 'dart:math' as math;

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({super.key});

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with SingleTickerProviderStateMixin {
  double turnsCover = 0.0;
  double turnsPlayer = -1 / 16;
  late final PlayerCubit _playerCubit;
  late AnimationController _controller;

  _getCoverImage(PlayerState state) {
    if ((state is AudioPlayerPlaying ||
            state is AudioPlayerPaused ||
            state is AudioPlayerEnd) &&
        _playerCubit.actifSong.value != null) {
      final cover = _playerCubit.actifSong.value!.cover;
      if (cover != 'default_cover' && cover.isNotEmpty) {
        return cover;
      }
    }
    return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Placeholder_view_vector.svg/1200px-Placeholder_view_vector.svg.png';
  }

  _getRotation(PlayerState state) {
    if (state is AudioPlayerPlaying) {
      return 1 / 2048;
    }
    return turnsPlayer;
  }

  _getSongTitle(PlayerState state) {
    if (state is AudioPlayerPlaying ||
        state is AudioPlayerPaused ||
        state is AudioPlayerEnd) {
      return _playerCubit.actifSong.value!.title;
    }
    return "";
  }

  _getSongCreator(PlayerState state) {
    if (state is AudioPlayerPlaying ||
        state is AudioPlayerPaused ||
        state is AudioPlayerEnd) {
      return _playerCubit.actifSong.value!.creator;
    }
    return "";
  }

  _getSongGenre(PlayerState state) {
    if (state is AudioPlayerPlaying ||
        state is AudioPlayerPaused ||
        state is AudioPlayerEnd) {
      return _playerCubit.actifSong.value!.genre;
    }

    return "";
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
  void initState() {
    super.initState();
    _playerCubit = context.read<PlayerCubit>();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _playerCubit.audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index > 0) {
        _playerCubit.actifSong.value = _playerCubit.songList[index];
      }
    });

    _playerCubit.audioPlayer.processingStateStream.listen((state) {
      if (_playerCubit.audioPlayer.processingState.toString() ==
          'ProcessingState.completed') {
        _playerCubit.endAudio();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _playerCubit.actifSong,
        builder: (context, _, __) {
          return Expanded(
            child: SizedBox(
              height: SizeConfig.screenHeight,
              // color: Colors.red.withOpacity(0.5),
              child: BlocBuilder<PlayerCubit, PlayerState>(
                bloc: _playerCubit,
                builder: (context, state) {
                  return Stack(
                    children: [
                      Positioned(
                        top: SizeConfig.blockSizeV! * 30,
                        left: SizeConfig.blockSizeH! * 10.2,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            if (state is AudioPlayerPlaying) {
                              _controller.repeat();
                            } else {
                              _controller.stop();
                              _controller.reset();
                            }
                            return Transform.rotate(
                              angle: _controller.value * 2.0 * math.pi,
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              if (_playerCubit.actifSong.value != null) {
                                showDialog(
                                  context: context,
                                  builder: (homeContext) => ListenSongWidget(
                                    song: _playerCubit.actifSong.value!,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 160,
                              height: 160,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  width: 3,
                                  color: Colors.orange,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(_getCoverImage(state)),
                                ),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: SizeConfig.blockSizeH! * 6,
                        right: SizeConfig.blockSizeV! * 30,
                        child: AnimatedRotation(
                          turns: _getRotation(state),
                          alignment: Alignment.topRight,
                          duration: const Duration(milliseconds: 500),
                          child: Image.asset(
                            'assets/images/player.png',
                            height: 300,
                          ),
                        ),
                      ),
                      Positioned(
                        top: SizeConfig.blockSizeV! * 64.48,
                        left: SizeConfig.blockSizeH! * 4.65,
                        child: SizedBox(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 300,
                                height: 30,
                                child: StreamBuilder(
                                    stream:
                                        _playerCubit.audioPlayer.positionStream,
                                    builder: (context, snapshot) {
                                      return ProgressBar(
                                        thumbRadius: 7,
                                        thumbGlowRadius: 9,
                                        progressBarColor:
                                            Colors.black.withOpacity(0.6),
                                        barHeight: 4,
                                        thumbColor: Colors.black.withOpacity(1),
                                        baseBarColor:
                                            Colors.black.withOpacity(0.2),
                                        bufferedBarColor:
                                            Colors.black.withOpacity(0.2),
                                        timeLabelLocation:
                                            TimeLabelLocation.below,
                                        timeLabelTextStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                        timeLabelPadding: 7,
                                        progress:
                                            snapshot.data ?? Duration.zero,
                                        total:
                                            _playerCubit.audioPlayer.duration ??
                                                Duration.zero,
                                        onSeek: (duration) async {
                                          await _playerCubit.audioPlayer
                                              .seek(duration);
                                        },
                                      );
                                    }),
                              ),
                              Text(
                                _getSongCreator(state),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                _getSongTitle(state),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getSongGenre(state),
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  PlayerButton(
                                    icon: Icons.skip_previous,
                                    onPressed: () {
                                      _playerCubit.previous();
                                    },
                                    size: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  _getPlayPauseButton(state),
                                  const SizedBox(width: 10),
                                  PlayerButton(
                                    icon: Icons.skip_next,
                                    onPressed: () {
                                      _playerCubit.next();
                                    },
                                    size: 40,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        });
  }
}
