import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jukebox/blocs/category_cubit/category_cubit.dart';

class MusicStyleWidget extends StatelessWidget {
  const MusicStyleWidget({
    super.key,
    required this.selectedMusicStyle,
  });

  final ValueNotifier<String> selectedMusicStyle;

  @override
  Widget build(BuildContext context) {
    // Use hardcoded genre names (instant, no API call)
    final genres = CategoryCubit.genreNames;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder(
        valueListenable: selectedMusicStyle,
        builder: (context, value, _) {
          return Row(
            children: [
              const SizedBox(width: 12),
              ...genres.map(
                (genre) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      selectedMusicStyle.value = genre;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(
                        minWidth: 80,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          if (value == genre)
                            const BoxShadow(
                              offset: Offset(-5, 8),
                            ),
                          BoxShadow(
                            offset: const Offset(1, 1),
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            genre,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (value == genre)
                            const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(
                                  CupertinoIcons.check_mark_circled_solid,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
