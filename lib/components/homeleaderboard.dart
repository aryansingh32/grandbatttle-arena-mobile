import 'package:flutter/material.dart';
// import 'package:grand_battle_arena/items/leaderboardprofie.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class HomeLeaderBoard extends StatelessWidget {
  const HomeLeaderBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        
        crossAxisAlignment: CrossAxisAlignment.start,
        
        children: [
          Padding(
                padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                child: const Text(
                  "Leader Board",
                  style: TextStyle(
                    
                    fontWeight: FontWeight.w400,
                    fontSize: 25,
                    letterSpacing: 0.5,
                    color: Appcolor.white,
                  ),
                ),
              ),
              // LeaderBoardProfile(),
              SizedBox(height: 15,),
              // LeaderBoardProfile(),
              SizedBox(height: 15,),
              // LeaderBoardProfile(),
              SizedBox(height: 30,),
              Center(
                child: const Text(
                  "Coming Soon....",
                  style: TextStyle(
                    
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Appcolor.secondary,
                  ),
                ),
              )
      
        ],
      ),
    );
  }
}