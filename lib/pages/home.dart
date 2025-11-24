import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/bannerslider.dart';
import 'package:grand_battle_arena/components/homegames.dart';
import 'package:grand_battle_arena/components/homeleaderboard.dart';
import 'package:grand_battle_arena/components/mybookingscroller.dart';
import 'package:grand_battle_arena/components/home_quick_filters.dart';
// import 'package:grand_battle_arena/components/navigatorbar.dart';
import 'package:grand_battle_arena/components/tournamentcards.dart';
import 'package:grand_battle_arena/components/topbar.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(9, 11, 14, 1),
      body: Stack(
        children: [
          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100), // Add bottom padding to prevent content from being hidden behind nav bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TopBar(), // For TopBar
                    BannerSlider(),
                    Homegames(), // Games 
                    const HomeQuickFilters(), // CHANGE: add stylish quick filters bar.
                    Padding( 
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: Container(
                          height: 1,
                          width: 175,
                          decoration: BoxDecoration(
                            color: Appcolor.grey,
                          ),
                        ),
                      ),
                    ),
                    MyBookingsScroller(),
                    const SizedBox(height: 24), // CHANGE: keep layout tight when the section is hidden.
                    TournamentCards(),
                    HomeLeaderBoard(),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating Navigation Bar
          //   Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: NavigatorBar(
          //     currentIndex: currentIndex,
          //     onPageChanged: (index) {
          //       setState(() {
          //         currentIndex = index;
          //       });
          //       switch(index) {
          //         case 0: // Home - already here
          //           break;
          //         case 1: // VS/Battle page
          //           Navigator.pushNamed(context, '/tournament');
          //           break;
          //         case 2: // Wallet page
          //           Navigator.pushNamed(context, '/wallet');
          //           break;
          //       }
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}