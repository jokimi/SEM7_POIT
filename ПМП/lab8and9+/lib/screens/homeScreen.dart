import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appProvider.dart';
import '../widgets/bottomNavigationBar.dart';
import '../widgets/collectionAvatar.dart';
import '../widgets/bookCard.dart';
import '../widgets/userAvatar.dart';
import '../widgets/searchBar.dart';
import '../widgets/sectionHeader.dart';
import '../models/bookModel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF5d666f)),
            onPressed: () {
              Navigator.pushNamed(context, '/hive_stats');
            },
          ),
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              if (provider.canManageBooks) {
                return IconButton(
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
            icon: const Icon(Icons.favorite, color: Color(0xFF5d666f)),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: () {
                    _showUserMenu(context, provider);
                  },
                  child: UserAvatar(
                    imagePath: provider.currentUser?.avatarPath ?? 'assets/avatar.jpg',
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                      child: MySearchBar(
                        onChanged: (query) {
                          provider.searchBooks(query);
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
                      child: _buildAllBooksSlider(provider),
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
                      child: _buildRecommendedBooks(provider),
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
          );
        },
      ),
    );
  }



  Widget _buildUserInfo(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.currentUser?.role == 1
                    ? Icons.admin_panel_settings
                    : Icons.person,
                color: _getRoleColor(provider.currentUser?.role ?? 0),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${provider.currentUser?.name ?? "Не выбран"} • ${_getRoleName(provider.currentUser?.role ?? 0)}',
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
          if (provider.currentUser != null)
            Text(
              provider.currentUser!.email,
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



  Widget _buildAllBooksSlider(AppProvider provider) {
    final books = provider.books;

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
              onInfoPressed: () {
                _showBookDetails(context, book);
              },
              onLikePressed: () {
                provider.toggleFavorite(book.id);
              },
              isLiked: provider.isBookInFavorites(book.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedBooks(AppProvider provider) {
    final recommendedBooks = provider.books.where((book) =>
    book.categories.contains('Fiction') || book.categories.contains('Adventure')).toList();

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
                          _limitWords(recommendedBook.description, 15),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            fontFamily: 'Pretendard',
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFffae1a),
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
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: -33,
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

  void _showUserMenu(BuildContext context, AppProvider provider) {
    final users = provider.getUsers();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Switch User',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 16),
            ...users.map((user) {
              final isSelected = provider.currentUser?.id == user.id;
              return ListTile(
                leading: UserAvatar(
                  imagePath: user.avatarPath,
                  size: 50,
                ),
                title: Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Pretendard',
                  ),
                ),
                subtitle: Text(
                  '${_getRoleName(user.role)} • ${user.email}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFFffae1a))
                    : null,
                onTap: () async {
                  await provider.switchUser(user.id);
                  Navigator.pop(context);
                },
              );
            }).toList(),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 150,
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
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Author: ${book.author}'),
              const SizedBox(height: 8),
              Text('Rating: ${book.rating}'),
              Text('Reviews: ${book.reviewsCount}'),
              Text('Liked: ${book.isLiked ? "Yes" : "No"}'),
              const SizedBox(height: 8),
              Text('Categories: ${book.categories.join(", ")}'),
              const SizedBox(height: 8),
              Text('Description: ${book.description}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }



  void _showAddBookDialog(BuildContext context, AppProvider provider) {
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
                  final newBook = provider.createDemoBook(
                    title: title,
                    author: author,
                    description: description,
                    imagePath: selectedImagePath,
                    categories: selectedCategories.isEmpty ? ['Новая'] : selectedCategories,
                  );

                  provider.addBook(newBook);
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