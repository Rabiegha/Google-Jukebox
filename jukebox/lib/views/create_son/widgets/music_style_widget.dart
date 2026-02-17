import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jukebox/blocs/category_cubit/category_cubit.dart';
import 'package:jukebox/models/category_model.dart';

class MusicStyleWidget extends StatefulWidget {
  const MusicStyleWidget({
    super.key,
    required this.selectedMusicStyle,
  });

  final ValueNotifier<String> selectedMusicStyle;

  @override
  State<MusicStyleWidget> createState() => _MusicStyleWidgetState();
}

class _MusicStyleWidgetState extends State<MusicStyleWidget> {
  late final CategoryCubit _categoryCubit;
  List<CategoryModel> categories = [];

  @override
  void initState() {
    super.initState();
    _categoryCubit = context.read<CategoryCubit>();
    categories = (_categoryCubit.state as CategoryGetSuccess).categories;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder(
        valueListenable: widget.selectedMusicStyle,
        builder: (context, value, _) {
          return Row(
            children: [
              const SizedBox(width: 12),
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () {
                      widget.selectedMusicStyle.value = category.id;
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
                          if (value == category.id)
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
                            category.id,
                            style:
                                GoogleFonts.nunito(fontWeight: FontWeight.bold),
                          ),
                          if (value == category.id)
                            const Row(
                              children: [
                                SizedBox(width: 10),
                                Icon(CupertinoIcons.check_mark_circled_solid),
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
