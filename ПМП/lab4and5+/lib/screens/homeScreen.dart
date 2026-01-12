import 'package:flutter/material.dart';
import '../widgets/bottomNavigationBar.dart';
import '../widgets/collectionAvatar.dart';
import '../widgets/bookCard.dart';
import '../widgets/userAvatar.dart';
import '../widgets/searchBar.dart';
import '../widgets/sectionHeader.dart';
import '../widgets/forYouBook.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> popularBooks = [
    {
      'title': 'Timber',
      'author': 'Peter Dauvergne',
      'image': 'assets/timber.jpg',
      'color': Color(0xFFf5bc15),
    },
    {
      'title': 'Sweet Bird of Youth',
      'author': 'Tennessee Williams',
      'image': 'assets/sweetbirdofyouth.jpg',
      'color': Color(0xFF858e85),
    },
    {
      'title': 'Early Bird',
      'author': 'Rodney Rothman',
      'image': 'assets/earlybird.jpg',
      'color': Color(0xFFf3d656),
    },
    {
      'title': 'The Crow\'s Vow',
      'author': 'Susan Briscoe',
      'image': 'assets/thecrowsvow.jpg',
      'color': Color(0xFFfbcec9),
    },
    {
      'title': 'Sea of Poppies',
      'author': 'Amitav Ghosh',
      'image': 'assets/seaofpoppies.jpg',
      'color': Color(0xFFd0c9b7),
    },
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: ForYouBook(),
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
          final isFourthBook = index == 3;

          return Container(
            width: 105,
            margin: EdgeInsets.only(
              right: isLast ? 0 : 16,
            ),
            child: BookCard(
              book: popularBooks[index],
              index: index,
              onTap: isFourthBook ? () {
                Navigator.pushNamed(context, '/book_detail');
              } : null,
            ),
          );
        },
      ),
    );
  }
}