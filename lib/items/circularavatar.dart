import 'package:flutter/material.dart';
import 'package:grand_battle_arena/theme/appcolor.dart';

class CircularProfile extends StatelessWidget{
  final String navigationLocation;
  final String imageLink;
  final double  radiusCircle; 
  final String iconText;
  final double fontsize;
  final bool isNetwork;
  const CircularProfile({super.key,
  required this.navigationLocation,
  required this.imageLink,
  this.radiusCircle = 21,
  this.iconText = '',
  this.isNetwork = false,
  this.fontsize = 10});
  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        GestureDetector(
                onTap: () => Navigator.pushNamed(context, navigationLocation),
                child: Container(
                  // padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Appcolor.grey,
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: radiusCircle,
                    backgroundImage: (isNetwork)?NetworkImage(imageLink):AssetImage(imageLink),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Text(
                iconText,
                style: TextStyle(
                  
                  color: Appcolor.white,
                  fontSize: fontsize
                ),

              )
      ],
    );
  }
  
}