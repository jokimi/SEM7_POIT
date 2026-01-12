import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../bloc/appBLoC.dart';
import '../bloc/appEvent.dart';
import '../bloc/appState.dart';
import 'bookDetailScreen.dart';
import '../widgets/bottomNavigationBar.dart';
import '../widgets/collectionAvatar.dart';
import '../widgets/bookCard.dart';
import '../widgets/userAvatar.dart';
import '../widgets/searchBar.dart';
import '../widgets/sectionHeader.dart';
import '../widgets/forYouBook.dart';
import '../models/userModel.dart';
import '../models/bookModel.dart';
import '../services/connectivityService.dart';

class HomeScreen extends StatefulWidget {
  final ConnectivityService connectivityService;

  HomeScreen({
    Key? key,
    ConnectivityService? connectivityService,
  })  : connectivityService = connectivityService ?? ConnectivityService(),
        super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivityService = widget.connectivityService;
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        setState(() {
          _isOnline = isConnected;
        });
      },
    );
    // Проверяем начальное состояние
    _connectivityService.isConnected().then((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> collections = [
    {
      'name': 'Art',
      'image': 'assets/art.jpg',
    },
    {
      'name': 'Health',
      'image': 'assets/health.jpg',
    },
    {
      'name': 'Mystery',
      'image': 'assets/mystery.jpg',
    },
    {
      'name': 'Fiction',
      'image': 'assets/fiction.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 7),
          child: Text(
            'Daily Reading',
            style: TextStyle(
              color: Color(0xFF5d666f),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        actions: [
          BlocBuilder<AppBloc, AppState>(
            builder: (context, state) {
              if (state is AppLoaded && state.canManageBooks) {
                return IconButton(
                  key: const Key('home_admin_button'),
                  icon: const Icon(Icons.settings, color: Color(0xFF5d666f)),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin_books');
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            key: const Key('home_favorites_button'),
            icon: const Icon(Icons.favorite, color: Color(0xFF5d666f)),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: BlocBuilder<AppBloc, AppState>(
              builder: (context, state) {
                final avatarPath = state is AppLoaded
                    ? (state.currentUser?.avatarPath ?? 'assets/avatar.jpg')
                    : 'assets/avatar.jpg';
                return GestureDetector(
                  key: const Key('home_profile_avatar'),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: UserAvatar(
                    imagePath: avatarPath,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          if (state is AppLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is! AppLoaded) {
            return const Center(
              child: Text('Ошибка загрузки данных'),
            );
          }

          return Column(
            children: [
              // Индикатор офлайн-режима
              if (!_isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orange,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Офлайн режим. Изменения будут синхронизированы при подключении.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                      child: MySearchBar(
                        key: const Key('home_search_bar'),
                        textFieldKey: const Key('home_search_field'),
                        onChanged: (query) {
                          context.read<AppBloc>().add(BooksSearched(query));
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Все книги в разделе Popular Books
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: SectionHeader(title: 'Popular'),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: _buildAllBooksSlider(state),
                    ),
                    const SizedBox(height: 16),

                    // Коллекции
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: SectionHeader(title: 'Collection'),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: _buildCollectionAvatars(),
                    ),
                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: SectionHeader(title: 'For You'),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: _buildRecommendedBooks(state),
                    ),

                    const SizedBox(height: 125),
                  ],
                ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomBottomNavigationBar(activeIndex: 1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildUserInfo(AppLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.currentUser?.role == 1
                    ? Icons.admin_panel_settings
                    : Icons.person,
                color: _getRoleColor(state.currentUser?.role ?? 0),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${state.currentUser?.name ?? "Не выбран"} • ${_getRoleName(state.currentUser?.role ?? 0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5d666f),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),

            ],
          ),
          const SizedBox(height: 8),
          if (state.currentUser != null)
            Text(
              state.currentUser!.email,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontFamily: 'Pretendard',
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildAllBooksSlider(AppLoaded state) {
    final books = state.filteredBooks;

    if (books.isEmpty) {
      return const SizedBox(
        height: 225,
        child: Center(
          child: Text('Нет книг'),
        ),
      );
    }

    return Container(
      height: 220,
      child: ListView.builder(
        key: const Key('home_popular_list'),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          final isLast = index == books.length - 1;

          return Container(
            width: 105,
            margin: EdgeInsets.only(
              right: isLast ? 0 : 16,
            ),
            child: BookCard(
              book: book,
              index: index,
              onTap: () => _showBookDetails(context, book),
              onInfoPressed: () {
                context.read<AppBloc>().analyticsService.logBookView(book.id, book.title);
                _showBookInfoModal(context, book);
              },
              onLikePressed: context.read<AppBloc>().remoteConfigService.isLikeButtonEnabled()
                  ? () {
                      context.read<AppBloc>().add(FavoriteToggled(book.id));
                    }
                  : null,
              isLiked: context.read<AppBloc>().isBookInFavorites(book.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedBooks(AppLoaded state) {
    final recommendedBooks = state.books.where((book) =>
    book.categories.contains('Literature')).toList();

    if (recommendedBooks.isEmpty) {
      return const SizedBox();
    }

    final recommendedBook = recommendedBooks.isNotEmpty ? recommendedBooks.first : null;

    if (recommendedBook == null) return const SizedBox();

    return GestureDetector(
            onTap: () {
              _showBookDetails(context, recommendedBook);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 1),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 155),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${recommendedBook.title}: ${recommendedBook.categories.isNotEmpty ? recommendedBook.categories.first : ""}',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                            color: Color(0xFF5d666f),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _limitWords(recommendedBook.description, 10),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            fontFamily: 'Pretendard',
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final blockColor = context.read<AppBloc>().remoteConfigService.getBlockColor();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: blockColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Read More',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.east_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: -31,
                    child: Container(
                      width: 130,
                      height: 190,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          recommendedBook.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _getColorFromString(recommendedBook.title),
                                    _getColorFromString(recommendedBook.title).withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.book,
                                color: Colors.white,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }




  Widget _buildCollectionAvatars() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const avatarSize = 73.0;
        final totalAvatarsWidth = collections.length * avatarSize;
        final availableSpace = totalWidth - totalAvatarsWidth;
        final spacing = availableSpace / (collections.length - 1);

        return Container(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: collections.asMap().entries.map((entry) {
              final index = entry.key;
              final collection = entry.value;
              final isLast = index == collections.length - 1;

              return Container(
                margin: EdgeInsets.only(right: isLast ? 0 : spacing),
                child: CollectionAvatar(
                  collection: collection,
                  index: index,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Вспомогательные методы
  Color _getRoleColor(int role) {
    switch (role) {
      case 1: // admin
        return Colors.red;
      default: // user
        return Colors.blue;
    }
  }

  String _getRoleName(int role) {
    switch (role) {
      case 1:
        return 'Admin';
      default:
        return 'User';
    }
  }

  String _limitWords(String text, int wordLimit) {
    final words = text.split(' ');
    if (words.length <= wordLimit) {
      return text;
    }
    return words.take(wordLimit).join(' ') + '...';
  }

  Color _getColorFromString(String text) {
    final colors = [
      Color(0xFFf5bc15),
      Color(0xFF858e85),
      Color(0xFFf3d656),
      Color(0xFFfbcec9),
      Color(0xFFd0c9b7),
      Color(0xFF6fbdbf),
      Color(0xFF25b4c4),
    ];

    final index = text.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  void _showBookDetails(BuildContext context, Book book) {
    context.read<AppBloc>().analyticsService.logBookView(book.id, book.title);
    Navigator.pushNamed(
      context,
      '/book_detail',
      arguments: book,
    );
  }

  void _showBookInfoModal(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Информация о книге',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                        color: Color(0xFF5d666f),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: const Color(0xFF5d666f),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Обложка книги
                Center(
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        book.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getColorFromString(book.title),
                                  _getColorFromString(book.title).withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.book,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('ID', book.id),
                _buildInfoRow('Название', book.title),
                _buildInfoRow('Автор', book.author),
                _buildInfoRow('Описание', book.description.isEmpty ? 'Нет описания' : book.description),
                _buildInfoRow('Рейтинг', book.rating.toStringAsFixed(1)),
                _buildInfoRow('Количество отзывов', book.reviewsCount.toString()),
                _buildInfoRow('Отзывы в БД', '${book.reviews.length}'),
                _buildInfoRow('Категории', book.categories.isEmpty ? 'Нет категорий' : book.categories.join(', ')),
                _buildInfoRow('В избранном', book.isLiked ? 'Да' : 'Нет'),
                _buildInfoRow('Дата создания', _formatDate(book.createdAt)),
                if (book.createdBy != null)
                  _buildInfoRow('Создано пользователем', book.createdBy!),
                if (book.imagePath.isNotEmpty)
                  _buildInfoRow('Путь к изображению', book.imagePath),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5d666f),
              fontFamily: 'Pretendard',
            ),
            maxLines: label == 'Описание' ? 5 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }



  void _showAddBookDialog(BuildContext context, AppBloc bloc) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedImagePath = 'assets/avatar.jpg';
    List<String> selectedCategories = [];

    final availableImages = [
      'assets/avatar.jpg',
      'assets/art.jpg',
      'assets/health.jpg',
      'assets/mystery.jpg',
      'assets/fiction.jpg',
      'assets/earlybird.jpg',
      'assets/thecrowsvow.jpg',
      'assets/sweetbirdofyouth.jpg',
      'assets/timber.jpg',
      'assets/seaofpoppies.jpg',
      'assets/anna.jpg',
      'assets/dolores.jpg',
      'assets/theo.jpg',
    ];

    final availableCategories = [
      'Fiction',
      'Adventure',
      'Drama',
      'Classic',
      'Humor',
      'Biography',
      'Travelers',
      'Literature',
      'Programming',
      'Technology',
      'Health',
      'Wellness',
      'Mystery',
      'Thriller',
      'Nature',
      'Science',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter book title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    hintText: 'Enter author name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedImagePath,
                  decoration: const InputDecoration(
                    labelText: 'Изображение',
                    border: OutlineInputBorder(),
                  ),
                  items: availableImages.map((path) {
                    return DropdownMenuItem<String>(
                      value: path,
                      child: Text(path.replaceAll('assets/', '')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedImagePath = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (selectedImagePath.isNotEmpty)
                  Container(
                    height: 100,
                    width: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        selectedImagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.image_not_supported));
                        },
                      ),
                    ),
                  ),
                if (selectedImagePath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedImagePath = '';
                          });
                        },
                        child: const Text('Удалить обложку'),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Категории:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCategories.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final author = authorController.text;
                final description = descriptionController.text;

                if (title.isNotEmpty && author.isNotEmpty) {
                  final newBook = bloc.createDemoBook(
                    title: title,
                    author: author,
                    description: description,
                    imagePath: selectedImagePath,
                    categories: selectedCategories.isEmpty ? ['Новая'] : selectedCategories,
                  );

                  bloc.add(BookAdded(newBook));
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book added successfully'),
                      backgroundColor: Color(0xFF5d666f),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill title and author'),
                      backgroundColor: Color(0xFF5d666f),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}