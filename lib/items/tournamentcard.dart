

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class TournamentCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String dateTime;
  final String prize;
  final String entry;
  final String teamSize;
  final String enrolled;
  final String map;
  final String game;
  final VoidCallback onRegister;
  final bool isLoading;
  final bool isDivider;
  final double imgHeight;
  final double dividerHeight;
  final double dividerWidth;

  const TournamentCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.dateTime,
    required this.prize,
    required this.entry,
    required this.teamSize,
    required this.enrolled,
    required this.map,
    required this.game,
    required this.onRegister,
    this.isLoading = false,
    this.isDivider = false,
    this.dividerHeight = 25,
    this.dividerWidth = 0.5,
    this.imgHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmerCard();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Appcolor.cardsColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Image.asset(
                imageUrl,
                width: double.infinity,
                height: imgHeight,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                        style: TextStyle(
                        
                          fontWeight: FontWeight.w400,
                          fontSize: 14.5,
                          color: const Color.fromARGB(226, 224, 224, 224),
                        ),
                      ),
                      Text("Prize Pool",
                        style: TextStyle(
                        
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Appcolor.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateTime,
                        style: TextStyle(
                        
                          fontSize: 13,
                          color: Appcolor.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Image.asset("assets/icons/dollar.png", width: 16),
                          const SizedBox(width: 5),
                          Text(prize,
                            style: TextStyle(
                            
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Appcolor.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoColumn("Entry/Player", entry, "assets/icons/dollar.png"),
                      if(isDivider)Container(height: dividerHeight, width: dividerWidth,  decoration:  BoxDecoration(color: Appcolor.grey),) ,
                      _infoColumn("Team Size", teamSize, "assets/icons/swords.png"),
                      if(isDivider)Container(height: dividerHeight, width: dividerWidth,  decoration:  BoxDecoration(color: Appcolor.grey),),
                      _infoColumn("Enrolled", enrolled, "assets/icons/people.png"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text("Map: ", style: TextStyle(fontSize: 12, color: Appcolor.grey,)),
                            Text(map, style: TextStyle(fontSize: 12, color: const Color.fromARGB(226, 224, 224, 224),)),
                          ]),
                          Row(children: [
                            Text("Game: ", style: TextStyle(fontSize: 12, color: Appcolor.grey,)),
                            Text(game, style: TextStyle(fontSize: 12, color: const Color.fromARGB(226, 224, 224, 224),)),
                          ]),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: onRegister,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Appcolor.secondary,
                          ),
                          child: Text("Register",
                            style: TextStyle(
                             
                              fontSize: 14,
                              letterSpacing: 1,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String title, String value, String iconPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: TextStyle(
          
            fontSize: 12,
            color: Appcolor.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Image.asset(iconPath, width: 16, height: 16),
            const SizedBox(width: 5),
            Text(value,
              style: TextStyle(
              
                fontSize: 12,
                color: Appcolor.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[900],
          ),
        ),
      ),
    );
  }
}
