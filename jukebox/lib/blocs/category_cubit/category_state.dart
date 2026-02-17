part of 'category_cubit.dart';

@immutable
sealed class CategoryState {}

final class CategoryInitial extends CategoryState {}

final class CategoryGetLoading extends CategoryState {}

final class CategoryGetSuccess extends CategoryState {
  final List<CategoryModel> categories;

  CategoryGetSuccess({required this.categories});
}

final class CategoryGetError extends CategoryState {}

final class CategoryGetFailed extends CategoryState {}
