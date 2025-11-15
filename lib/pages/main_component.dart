import 'package:flutter/material.dart';
import 'package:grand_battle_arena/components/navigatorbar.dart';
import 'package:grand_battle_arena/pages/home.dart';
import 'package:grand_battle_arena/pages/tournament.dart';
import 'package:grand_battle_arena/pages/wallet.dart';

class MainContainer extends StatefulWidget {
 
  final int currentIndex;  
  
  const MainContainer({  
    super.key,
    this.currentIndex = 0,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    print('MainContainer initState called'); // Debug log
    _currentIndex = widget.currentIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    Home(),
    TournamentContent(),
    Wallet(),
  ];

  @override
  Widget build(BuildContext context) {
    print('MainContainer build called - currentIndex: $_currentIndex'); // Debug log
    
    return Scaffold(
      backgroundColor: const Color.fromRGBO(9, 11, 14, 1),
      body: Stack(
        children: [
          // Add a simple debug container to ensure something is visible
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color.fromRGBO(9, 11, 14, 1),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                print('Page changed to: $index'); // Debug log
                setState(() {
                  _currentIndex = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                print('Building page at index: $index'); // Debug log
                return _pages[index];
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigatorBar(
              currentIndex: _currentIndex,
              onPageChanged: _onPageChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    print('NavigatorBar triggered page change to: $index'); // Debug log
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }
}