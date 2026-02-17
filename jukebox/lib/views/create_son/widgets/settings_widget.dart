import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';

import 'section_title.dart';

class Settings extends StatefulWidget {
  const Settings({
    super.key,
    required this.settings,
  });

  final ValueNotifier<Map<String, dynamic>> settings;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final TextEditingController songCtrl;
  late final SongCubit _songCubit;

  @override
  void initState() {
    super.initState();
    songCtrl = TextEditingController();
    _songCubit = SongCubit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Customize  and add music properties',
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: songCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'Chose a song to use as baseline for music properties (optionally). eg. La vie en rose de Edith Piaf',
                    hintStyle: GoogleFonts.nunito(fontSize: 14),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.black12,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              BlocConsumer<SongCubit, SongState>(
                bloc: _songCubit,
                listener: (context, state) {},
                builder: (context, state) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 150,
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 15,
                      ),
                      color: const Color(0xff7118a6),
                      child: state is GetSettingsloading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : Text(
                              'Generate Settings',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    onPressed: () {
                      if (state is GetSettingsloading) {
                        return;
                      }
                      if (songCtrl.text.isNotEmpty) {
                        _songCubit.getSettings(songCtrl.text);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: widget.settings,
          builder: (context, value, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('BPM'),
                        Expanded(
                          child: Slider(
                            inactiveColor: Colors.white,
                            value: value['bpm'].toDouble(),
                            min: 60,
                            max: 300,
                            label: value['bpm'].toString(),
                            divisions: 6,
                            onChanged: (x) {
                              widget.settings.value = Map.from({
                                'bpm': x,
                                'time_signature': value['time_signature'],
                                'bitrate': value['bitrate'],
                                'sample_range': value['sample_range'],
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: widget.settings,
          builder: (context, value, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Quality'),
                        Expanded(
                          child: Slider(
                            value: value['bitrate'].toDouble(),
                            min: 50,
                            max: 1000,
                            label: value['bitrate'].toString(),
                            divisions: 4,
                            onChanged: (x) {
                              widget.settings.value = Map.from({
                                'bpm': value['bpm'],
                                'time_signature': value['time_signature'],
                                'bitrate': x,
                                'sample_range': value['sample_range'],
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Sample range'),
                        Expanded(
                          child: Slider(
                            value: value['sample_range'].toDouble(),
                            min: 30,
                            max: 96,
                            label: value['sample_range'].toString(),
                            divisions: 4,
                            onChanged: (x) {
                              widget.settings.value = Map.from({
                                'bpm': value['bpm'],
                                'time_signature': value['time_signature'],
                                'bitrate': value['bitrate'],
                                'sample_range': x,
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
