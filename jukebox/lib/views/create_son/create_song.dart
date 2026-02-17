import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';
import 'package:jukebox/styles/size_config.dart';

import 'widgets/instruments_widget.dart';
import 'widgets/music_style_widget.dart';
import 'widgets/section_title.dart';
import 'widgets/settings_widget.dart';

class CreateSonWidget extends StatefulWidget {
  const CreateSonWidget({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<CreateSonWidget> createState() => _CreateSonWidgetState();
}

class _CreateSonWidgetState extends State<CreateSonWidget> {
  late final ValueNotifier<List<String>> selectedInstrument;
  late final ValueNotifier<String> selectedMusicStyle;
  late final ValueNotifier<Map<String, dynamic>> settings;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _pseudoCtrl;
  late final SongCubit _songCubit;

  @override
  void initState() {
    selectedInstrument = ValueNotifier([]);
    selectedMusicStyle = ValueNotifier('');
    _titleCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _pseudoCtrl = TextEditingController();
    _songCubit = SongCubit();
    settings = ValueNotifier({
      'bpm': 120,
      'time_signature': "4/4",
      'bitrate': 320.0,
      'sample_range': 44.0,
    });

    _songCubit.stream.listen((state) {
      if (state is GetSettingsSuccess) {
        settings.value = Map.from(state.settings);
      }
    });

    super.initState();
  }

  _createSong() {
    if (selectedInstrument.value.isNotEmpty &&
        selectedMusicStyle.value.isNotEmpty &&
        _titleCtrl.text.isNotEmpty &&
        _pseudoCtrl.text.isNotEmpty) {
      _songCubit.createSongInIsolate(
        _titleCtrl.text,
        _descriptionCtrl.text,
        _pseudoCtrl.text,
        selectedMusicStyle.value,
        selectedInstrument.value,
        settings.value,
        context,
        widget.scaffoldKey.currentState!.context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      content: Container(
        height: SizeConfig.screenHeight! - 100,
        width: SizeConfig.screenWidth! - 100,
        color: const Color(0xFFEADFB1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create new song',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: Colors.black,
                        size: 25,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              ),
              const Divider(
                color: Colors.black12,
                height: 1,
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 20),
                    const SectionTitle(
                      title: 'Choose your instruments (3 maximum)',
                    ),
                    InstrumentsWidget(
                      selectedInstrument: selectedInstrument,
                    ),
                    const SizedBox(height: 40),
                    const SectionTitle(title: 'Choose your music style'),
                    MusicStyleWidget(selectedMusicStyle: selectedMusicStyle),
                    const SizedBox(height: 40),
                    Settings(settings: settings),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Describe your dream music 🤩 and add your pseudo 💃',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        minLines: 3,
                        maxLines: 5,
                        controller: _descriptionCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                          hintStyle: TextStyle(
                            color: Colors.black45,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.black12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _pseudoCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Your pseudo, eg. DJ Eric',
                          hintStyle: TextStyle(
                            color: Colors.black45,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.black12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Song title',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Eg. Gemini on the beat',
                                hintStyle: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                filled: true,
                                fillColor: Colors.black12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 15,
                              ),
                              color: const Color(0XFFAD402B),
                              child: Text(
                                'Create Song',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            onPressed: () {
                              _createSong();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
