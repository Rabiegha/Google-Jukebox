import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jukebox/blocs/category_cubit/category_cubit.dart';
import 'package:jukebox/blocs/song_cubit/song_cubit.dart';
import 'dart:math' as math;

class CategoriesList extends StatefulWidget {
  const CategoriesList({
    super.key,
  });

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  late final CategoryCubit _categoryCubit;
  late final SongCubit _songCubit;
  late final ValueNotifier<String?> _selectedCategory;

  @override
  void initState() {
    super.initState();
    _categoryCubit = context.read<CategoryCubit>();
    _songCubit = context.read<SongCubit>();
    _categoryCubit.getCategories();
    _selectedCategory = ValueNotifier(null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      bloc: _categoryCubit,
      builder: (context, state) {
        if (state is CategoryGetLoading) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 118,
              width: 191,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        if (state is CategoryGetSuccess) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 5,
                  color: Colors.black26,
                ),
                bottom: BorderSide(
                  width: 5,
                  color: Colors.black26,
                ),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  ...state.categories.map(
                    (category) => GestureDetector(
                      onTap: () {
                        _selectedCategory.value = category.id;
                        _songCubit.getSongsByGenre(
                          category.id,
                          _categoryCubit,
                          context,
                        );
                      },
                      child: Transform.rotate(
                        angle: -math.pi / category.rotation,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ValueListenableBuilder(
                            valueListenable: _selectedCategory,
                            builder: (context, value, _) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 118,
                                    width: 191,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(category.url),
                                        fit: BoxFit.cover,
                                      ),
                                      border: Border.all(
                                        width: 5,
                                        color: _selectedCategory.value ==
                                                category.id
                                            ? const Color(0xFFF6AC71)
                                            : Colors.white,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(offset: Offset(-7, 10)),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    left: 10,
                                    child: Text(
                                      category.id,
                                      style: GoogleFonts.jotiOne(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }

        return const Text('error');
      },
    );
  }
}
