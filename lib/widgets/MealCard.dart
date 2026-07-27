import 'package:flutter/material.dart';

class MealCard extends StatelessWidget {
  final String mealType;
  final String mealName;
  final String mealDate;
  final VoidCallback onDelete;

  const MealCard({super.key, 
    required this.mealType,
    required this.mealName,
    required this.mealDate,
    required this.onDelete,
  });

  IconData getMealIcon() {
    switch (mealType) {
      case 'Breakfast':
        return Icons.free_breakfast;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Snacks':
        return Icons.fastfood;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(getMealIcon(), color: const Color.fromARGB(255, 223, 164, 86), size: 30),
        title: Text(
          "$mealType - $mealName",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text("Date: $mealDate"),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
