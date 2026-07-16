import 'package:expense_tracker/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import 'home_screen.dart'; // AppColors, iconMap

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<Category> all = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await ref.read(categoryRepositoryProvider).fetchAll();
    setState(() {
      all = cats;
      loading = false;
    });
  }

  List<Category> get parents => all.where((c) => c.parentId == null).toList();
  List<Category> subsOf(String parentId) =>
      all.where((c) => c.parentId == parentId).toList();

  Future<void> _addCategory({String? parentId}) async {
    final nameCtrl = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parentId == null ? 'New Category' : 'New Subcategory'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref
          .read(categoryRepositoryProvider)
          .add(
            id: const Uuid().v4(),
            parentId: parentId,
            name: name,
            icon: 'category_rounded',
          );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (context, i) {
                    final parent = parents[i];
                    final subs = subsOf(parent.id);
                    return Card(
                      color: AppColors.background,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: Icon(
                          iconMap[parent.icon] ?? Icons.category_rounded,
                        ),
                        title: Text(parent.name),
                        children: [
                          ...subs.map(
                            (s) => ListTile(
                              leading: Icon(
                                iconMap[s.icon] ?? Icons.category_rounded,
                                size: 20,
                              ),
                              title: Text(s.name),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _addCategory(parentId: parent.id),
                            child: const Text('+ Add subcategory'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addCategory(),
                  child: const Text('+ Add Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
