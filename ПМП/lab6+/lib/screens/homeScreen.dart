import 'package:flutter/material.dart';
import '../widgets/bottomNavigationBar.dart';
import '../widgets/collectionAvatar.dart';
import '../widgets/bookCard.dart';
import '../widgets/userAvatar.dart';
import '../widgets/searchBar.dart';
import '../widgets/sectionHeader.dart';
import '../widgets/forYouBook.dart';
import '../models/book.dart';
import 'bookDetailScreen.dart';
import 'bookViewerScreen.dart';

class HomeScreen extends StatelessWidget {
  final List<Book> popularBooks = [
    Book(
      id: '1',
      title: 'Timber',
      author: 'Peter Dauvergne',
      rating: 8.5,
      reviewsCount: 89,
      categories: ['Nature', 'Environment'],
      coverColor: Color(0xFFf5bc15),
      coverImage: 'assets/timber.jpg',
      description: 'A comprehensive exploration of timber industry and its environmental impact. This book delves into the complex relationship between human civilization and forest resources.',
      reviews: [
        Review(
          name: 'Erico',
          review: 'Eye-opening analysis of deforestation. Every environmentalist should read this.',
          rating: 9.0,
          avatarPath: 'assets/erico.jpg',
        ),
        Review(
          name: 'Anonymous456',
          review: 'Deeply researched and beautifully written. Changed my perspective on wood consumption.',
          rating: 8.0,
          avatarPath: 'assets/anonymous456.jpg',
        ),
        Review(
          name: 'John Green',
          review: 'Important work but could use more practical solutions.',
          rating: 7.5,
          avatarPath: 'assets/johngreen.jpg',
        ),
      ],
    ),
    Book(
      id: '2',
      title: 'Sweet Bird',
      author: 'Tennessee Williams',
      rating: 9.1,
      reviewsCount: 155,
      categories: ['Drama', 'Classic'],
      coverColor: Color(0xFF858e85),
      coverImage: 'assets/sweetbirdofyouth.jpg',
      description: 'A powerful drama about aging, lost youth, and the pursuit of dreams. Tennessee Williams masterfully explores human vulnerabilities and desires.',
      reviews: [
        Review(
          name: 'justacutecat',
          review: 'Williams at his finest. The character development is absolutely brilliant.',
          rating: 9.5,
          avatarPath: 'assets/justacutecat.jpg',
        ),
        Review(
          name: 'Toyama Tokanawa',
          review: 'Timeless themes that resonate across generations. A true masterpiece.',
          rating: 8.8,
          avatarPath: 'assets/toyamatokanawa.jpg',
        ),
        Review(
          name: 'Chill Guy',
          review: 'The dialogue is sharp and meaningful. Perfect for study and analysis.',
          rating: 9.0,
          avatarPath: 'assets/chillguy.jpg',
        ),
      ],
    ),
    Book(
      id: '3',
      title: 'Early Bird',
      author: 'Rodney Rothman',
      rating: 7.8,
      reviewsCount: 67,
      categories: ['Comedy', 'Memoir'],
      coverColor: Color(0xFFf3d656),
      coverImage: 'assets/earlybird.jpg',
      description: 'A hilarious memoir about early retirement and finding new purpose in life. Full of witty observations and life lessons.',
      reviews: [
        Review(
          name: 'keikenny',
          review: 'Relatable and funny! As someone who retired early, this hit close to home.',
          rating: 8.2,
          avatarPath: 'assets/kawaii.jpg',
        ),
        Review(
          name: 'iloveducks',
          review: 'Made me rethink my career goals. Both humorous and thought-provoking.',
          rating: 7.5,
          avatarPath: 'assets/iloveducks.jpg',
        ),
        Review(
          name: 'Stargazer',
          review: 'Our book club loved this! Sparked great discussions about work-life balance.',
          rating: 7.9,
          avatarPath: 'assets/stargazer.jpg',
        ),
      ],
    ),
    Book(
      id: '4',
      title: 'The Crow\'s Vow',
      author: 'Susan Briscoe',
      rating: 9.2,
      reviewsCount: 203,
      categories: ['Travelers', 'Literature'],
      coverColor: Color(0xFFfbcec9),
      coverImage: 'assets/thecrowsvow.jpg',
      description: 'The Crow\'s Vow is an extraordinarily moving book-length sequence that follows the story of a marriage come undone. Organized into four seasons, the book traces the emotional landscape of love, loss, and the possibility of redemption.',
      reviews: [
        Review(
          name: 'Dolores',
          review: 'Beautiful graphics. Nothing else like it that I know of. Makes one focus...',
          rating: 9.2,
          avatarPath: 'assets/dolores.jpg',
        ),
        Review(
          name: 'Anna Lawrence',
          review: 'Amazing book! Truly a work of art, a true inspiration.',
          rating: 8.9,
          avatarPath: 'assets/anna.jpg',
        ),
        Review(
          name: 'Theo',
          review: 'Captivating storyline with deep character development.',
          rating: 7.0,
          avatarPath: 'assets/theo.jpg',
        ),
      ],
    ),
    Book(
      id: '5',
      title: 'Sea of Poppies',
      author: 'Amitav Ghosh',
      rating: 9.6,
      reviewsCount: 178,
      categories: ['Historical', 'Adventure'],
      coverColor: Color(0xFFd0c9b7),
      coverImage: 'assets/seaofpoppies.jpg',
      description: 'The first in an epic trilogy, Sea of Poppies is a stunningly vibrant and intensely human work that brings alive the nineteenth-century opium trade.',
      reviews: [
        Review(
          name: 'jokimi',
          review: 'Masterful historical fiction. The research behind this book is impressive.',
          rating: 10.0,
          avatarPath: 'assets/avatar.jpg',
        ),
        Review(
          name: 'iwiwi',
          review: 'Epic scope and unforgettable characters. Couldn\'t put it down!',
          rating: 8.7,
          avatarPath: 'assets/iwiwi.jpg',
        ),
        Review(
          name: 'awawa',
          review: 'Perfect start to an amazing series. The world-building is exceptional.',
          rating: 9.8,
          avatarPath: 'assets/awawa.jpg',
        ),
      ],
    ),
  ];

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

  // Метод 1 навигации: Navigator.push с MaterialPageRoute
  void _navigateWithPush(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book),
      ),
    );
  }

  // Метод 2 навигации: Navigator.pushNamed с аргументами
  void _navigateWithPushNamed(BuildContext context, Book book) {
    Navigator.pushNamed(
      context,
      '/book_detail',
      arguments: book,
    );
  }

  // Метод 3 навигации: Navigator.push с анимацией
  void _navigateWithAnimation(BuildContext context, Book book) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BookDetailScreen(book: book),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

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
          const Padding(
            padding: EdgeInsets.only(right: 25),
            child: UserAvatar(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
                  child: MySearchBar(),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: SectionHeader(title: 'Popular'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: _buildPopularBooksSlider(context),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: SectionHeader(title: 'Collection'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: _buildCollectionAvatars(),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: SectionHeader(title: 'For You'),
                ),
                const SizedBox(height: 31),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ForYouBook(
                    book: popularBooks[4], // Sea of Poppies
                    onTap: () => _navigateWithPushNamed(context, popularBooks[4]),
                  ),
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

  Widget _buildPopularBooksSlider(BuildContext context) {
    return Container(
      height: 205,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        itemCount: popularBooks.length,
        itemBuilder: (context, index) {
          final isLast = index == popularBooks.length - 1;
          final book = popularBooks[index];

          return Container(
            width: 105,
            margin: EdgeInsets.only(
              right: isLast ? 0 : 16,
            ),
            child: BookCard(
              book: book,
              index: index,
              onTap: () {
                if (index % 3 == 0) {
                  _navigateWithPush(context, book);
                } else if (index % 3 == 1) {
                  _navigateWithPushNamed(context, book);
                } else {
                  _navigateWithAnimation(context, book);
                }
              },
            ),
          );
        },
      ),
    );
  }
}