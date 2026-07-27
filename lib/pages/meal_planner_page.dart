import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/MealCard.dart';
import '../widgets/shopping_list_content.dart';

class MealPlannerPage extends StatefulWidget {
  const MealPlannerPage({super.key});

  @override
  _MealPlannerPageState createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  TextEditingController mealController = TextEditingController();
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  String selectedMealType = 'Breakfast';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addMeal() {
    if (mealController.text.isNotEmpty) {
      // Save meal to Firestore
      _firestore.collection('meals').add({
        'mealType': selectedMealType,
        'mealName': mealController.text,
        'date': "${selectedDay.toLocal()}".split(' ')[0],
      });

      mealController.clear();
    }
  }

  void _deleteMeal(String mealId) {
    // Delete meal from Firestore
    _firestore.collection('meals').doc(mealId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background
      appBar: AppBar(
        title: Text(
          "🍽️ Meal Planner",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange.shade400,
        elevation: 4,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingListContent()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Calendar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.deepOrange.shade400, blurRadius: 10)],
                ),
                padding: EdgeInsets.all(12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color:Colors.deepOrange.shade400,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.deepOrange.shade400,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(color: Colors.white),
                    todayTextStyle: TextStyle(color: Colors.white),
                    selectedTextStyle: TextStyle(color: Colors.white),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.deepOrange.shade400),
                    rightChevronIcon: Icon(Icons.chevron_right, color:Colors.deepOrange.shade400),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Input Area
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.deepOrange.shade400, blurRadius: 10)],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      dropdownColor: Colors.grey.shade800,
                      value: selectedMealType,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color:Colors.deepOrange.shade400),
                      style: TextStyle(color: Colors.white),
                      items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text("🍽️ $type", style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedMealType = val!;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: mealController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'What will you eat?',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.fastfood, color: Colors.deepOrange.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _addMeal,
                      icon: Icon(Icons.add),
                      label: Text('Add Meal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:Colors.deepOrange.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "📋 Your Meal Plan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              SizedBox(height: 10),

              // StreamBuilder to get meals from Firestore in real-time
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('meals').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!snapshot.hasData) {
                    return Text('No meals added yet!');
                  }

                  var meals = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      var meal = meals[index];
                      return MealCard(
                        mealType: meal['mealType'],
                        mealName: meal['mealName'],
                        mealDate: meal['date'],
                        onDelete: () => _deleteMeal(meal.id),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
