import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../providers/courses_provider.dart';
import '../../../models/course_model.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_theme.dart';
import '../../widgets/common/star_bar.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesProvider>().loadCourses();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cours')),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                      child: Text(
                        'Parcourir les cours',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Trouvez un cours par catégorie ou par mot-clé.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 150),
                      child: TextField(
                        controller: _search,
                        onChanged: provider.search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un cours...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              provider.search('');
                            },
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Catégories',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.categories.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = provider.categories[i];
                          final selected =
                              provider.selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (s) {
                              if (s) provider.filterByCategory(cat);
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${provider.courses.length} cours trouvés',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.favorite,
                                color: Colors.pinkAccent, size: 18),
                            const SizedBox(width: 6),
                            Text('Favoris',
                                style:
                                Theme.of(context).textTheme.bodyMedium),
                            Switch(
                              value: provider.showOnlyFavorites,
                              activeColor: Colors.pinkAccent,
                              onChanged: (_) =>
                                  provider.toggleShowOnlyFavorites(),
                            ),
                            if (provider.selectedCategory != 'All' ||
                                provider.searchQuery.isNotEmpty ||
                                provider.showOnlyFavorites)
                              TextButton(
                                onPressed: provider.clearFilters,
                                child: const Text('Réinitialiser'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child:
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              )
            else if (provider.courses.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 64,
                          color:
                          Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(height: 12),
                      Text('Aucun cours',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Essayez une autre recherche ou catégorie',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (_, i) {
                      final course = provider.courses[i];
                      final avg = provider.avgFor(course.id!);
                      final count = provider.countFor(course.id!);
                      return _CourseCard(
                        course: course,
                        avg: avg,
                        count: count,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoute.courseDetails,
                          arguments: course.id,
                        ),
                      );
                    },
                    childCount: provider.courses.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final double avg;
  final int count;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.avg,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      course.imageUrl != null
                          ? CachedNetworkImage(
                        imageUrl: course.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color:
                          AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.menu_book,
                              size: 40,
                              color: AppTheme.primaryColor),
                        ),
                      )
                          : Container(
                        color:
                        AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.menu_book,
                            size: 40,
                            color: AppTheme.primaryColor),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _FavoriteButton(courseId: course.id!),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.category,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      StarBar(value: avg, count: count, size: 16),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.play_lesson, size: 16),
                          const SizedBox(width: 6),
                          Text('${course.lessonsCount} leçon(s)',
                              style:
                              Theme.of(context).textTheme.bodySmall),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final int courseId;
  const _FavoriteButton({required this.courseId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    final isFav = provider.favoriteIds.contains(courseId);

    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.read<CoursesProvider>().toggleFavorite(courseId),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.pinkAccent : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
