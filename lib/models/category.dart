import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' | 'expense'

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id: map['id'],
    name: map['name'],
    icon: map['icon'],
    color: map['color'],
    type: map['type'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'type': type,
  };

  Color get colorValue => Color(int.parse(color));

  IconData get iconData {
    switch (icon) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'home': return Icons.home_rounded;
      case 'leisure': return Icons.sports_esports_rounded;
      case 'health': return Icons.favorite_rounded;
      case 'salary': return Icons.account_balance_wallet_rounded;
      case 'freelance': return Icons.laptop_mac_rounded;
      case 'invest': return Icons.trending_up_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}
