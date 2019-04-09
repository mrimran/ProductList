import 'package:flutter/material.dart';

import './user.dart';
import './location_data.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String image;
  final String imagePath;
  bool isFavorite;
  String userId;
  String userEmail;
  LocationData location;

  Product(
      {@required this.id,
      @required this.title,
      @required this.description,
      @required this.price,
      @required this.image,
      this.imagePath,
      this.isFavorite = false,
      this.userId,
      this.userEmail,
      this.location});

  Map get toMap {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'image': image,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
      'userId': userId
    };
  }
}
