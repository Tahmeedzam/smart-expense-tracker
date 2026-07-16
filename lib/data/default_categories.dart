import 'local_database.dart';
import 'package:drift/drift.dart';

final List<CategoriesCompanion> defaultCategories = [
  const CategoriesCompanion(
    id: Value('cat_travel'),
    name: Value('Travelling'),
    icon: Value('directions_bus_rounded'),
    color: Value('#4F46E5'),
  ),
  const CategoriesCompanion(
    id: Value('cat_travel_bus'),
    parentId: Value('cat_travel'),
    name: Value('Bus'),
    icon: Value('directions_bus_rounded'),
  ),
  const CategoriesCompanion(
    id: Value('cat_travel_metro'),
    parentId: Value('cat_travel'),
    name: Value('Metro'),
    icon: Value('train_rounded'),
  ),
  const CategoriesCompanion(
    id: Value('cat_travel_cab'),
    parentId: Value('cat_travel'),
    name: Value('Cab'),
    icon: Value('local_taxi_rounded'),
  ),
  const CategoriesCompanion(
    id: Value('cat_travel_fuel'),
    parentId: Value('cat_travel'),
    name: Value('Fuel'),
    icon: Value('local_gas_station_rounded'),
  ),
  const CategoriesCompanion(
    id: Value('cat_food'),
    name: Value('Food'),
    icon: Value('lunch_dining_rounded'),
    color: Value('#0D9488'),
  ),
  const CategoriesCompanion(
    id: Value('cat_food_groceries'),
    parentId: Value('cat_food'),
    name: Value('Groceries'),
    icon: Value('shopping_cart_rounded'),
  ),
  const CategoriesCompanion(
    id: Value('cat_food_dining'),
    parentId: Value('cat_food'),
    name: Value('Dining Out'),
    icon: Value('restaurant_rounded'),
  ),
  const CategoriesCompanion(
    id: Value('cat_shopping'),
    name: Value('Shopping'),
    icon: Value('shopping_bag_rounded'),
    color: Value('#F59E0B'),
  ),
  const CategoriesCompanion(
    id: Value('cat_bills'),
    name: Value('Bills'),
    icon: Value('receipt_long_rounded'),
    color: Value('#DC2626'),
  ),
  const CategoriesCompanion(
    id: Value('cat_entertainment'),
    name: Value('Entertainment'),
    icon: Value('movie_rounded'),
    color: Value('#8B5CF6'),
  ),
  const CategoriesCompanion(
    id: Value('cat_health'),
    name: Value('Health'),
    icon: Value('local_hospital_rounded'),
    color: Value('#16A34A'),
  ),
];
