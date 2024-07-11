import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error = null;

  void _loadItems() async {
    final url = Uri.https(
        "flutter-shoppinglist-fb849-default-rtdb.europe-west1.firebasedatabase.app",
        "shopping-list.json");
    final response = await http.get(url);

    if (response.body == "null") {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic>? listData = json.decode(response.body);
    final List<GroceryItem> _loadedItems = [];
    if (response.statusCode >= 400) {
      setState(() {
        _isLoading = false;
      });
      _error = "Failed to fetch data please try again later";
      return;
    }

    for (final item in listData!.entries) {
      var itemcategory = categories.entries
          .firstWhere((x) => x.value.title == item.value["category"])
          .value;
      _loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value["quantity"],
            category: itemcategory),
      );
    }
    setState(() {
      _groceryItems = _loadedItems;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _deleteItem(GroceryItem groceryItemToDelete) async {
    final _index = _groceryItems.indexOf(groceryItemToDelete);
    setState(() {
      _groceryItems.remove(groceryItemToDelete);
    });

    final url = Uri.https(
        "flutter-shoppinglist-fb849-default-rtdb.europe-west1.firebasedatabase.app",
        "shopping-list/${groceryItemToDelete.id}.json");

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(_index, groceryItemToDelete);
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget widgetBody = const Center(
      child: Text("No items found!"),
    );
    if (_isLoading) {
      widgetBody = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty) {
      widgetBody = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
                key: ValueKey(_groceryItems[index].id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete),
                ),
                direction: DismissDirection.endToStart,
                child: ListTile(
                  title: Text(
                    _groceryItems[index].name,
                  ),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(_groceryItems[index].quantity.toString()),
                ),
                onDismissed: (direction) async => {
                  _deleteItem(_groceryItems[index]),
                },
                confirmDismiss: (DismissDirection direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you wish to delete this item?"),
                        actions: [
                          InkWell(
                              onTap: () => Navigator.of(context).pop(true),
                              child: const Text("DELETE")),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ));
    }
    if (_error != null) {
      widgetBody = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.plus_one))
        ],
      ),
      body: widgetBody,
    );
  }
}
