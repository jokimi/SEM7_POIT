import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appProvider.dart';
import '../models/bookModel.dart';

class AdminBooksScreen extends StatelessWidget {
  const AdminBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление книгами'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final books = provider.allBooks;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Dismissible(
                key: Key(book.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить книгу?'),
                      content: Text('Вы уверены, что хотите удалить "${book.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  provider.deleteBook(book.id);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Image.asset(
                      book.imagePath,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.book),
                        );
                      },
                    ),
                    title: Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.author,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        Text(
                          'Рейтинг: ${book.rating}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditBookDialog(context, provider, book);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            provider.deleteBook(book.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (!provider.canManageBooks) {
            return const SizedBox();
          }

          return FloatingActionButton(
            onPressed: () {
              _showAddBookDialog(context, provider);
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, AppProvider provider) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedImagePath = 'assets/avatar.jpg';
    List<String> selectedCategories = [];

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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить книгу'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    hintText: 'Введите название книги',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Автор',
                    hintText: 'Введите автора',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    hintText: 'Введите описание',
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
              child: const Text('Отмена'),
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
                      content: Text('Книга добавлена успешно'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Заполните название и автора'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBookDialog(BuildContext context, AppProvider provider, Book book) {
    final titleController = TextEditingController(text: book.title);
    final authorController = TextEditingController(text: book.author);
    final descriptionController = TextEditingController(text: book.description);
    String selectedImagePath = book.imagePath;
    List<String> selectedCategories = List.from(book.categories);

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

    // Если текущее изображение не в списке, добавляем его
    if (!availableImages.contains(selectedImagePath)) {
      availableImages.insert(0, selectedImagePath);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Редактировать книгу'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Автор',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
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
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final author = authorController.text;
                final description = descriptionController.text;

                if (title.isNotEmpty && author.isNotEmpty) {
                  final updatedBook = book.copyWith(
                    title: title,
                    author: author,
                    description: description,
                    imagePath: selectedImagePath,
                    categories: selectedCategories.isEmpty ? ['Новая'] : selectedCategories,
                  );

                  provider.updateBook(updatedBook);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Книга обновлена успешно'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Заполните название и автора'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}