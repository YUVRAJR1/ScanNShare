import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sticky_headers/sticky_headers.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> sentImages = [];
  List<String> receivedImages = [];

  Map<String, List<Map<String, dynamic>>> categorizedImages = {};
  String currentType = 'sent';

  List<Map<String, dynamic>> recentlyDeletedCategoryImages = [];
  String? recentlyDeletedCategory = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        sentImages = prefs.getStringList('sent_history_${user.uid}') ?? [];
        receivedImages = prefs.getStringList('received_history_${user.uid}') ?? [];
      });
    }
  }

  Future<void> deleteImage(String type, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> currentList = type == 'sent' ? sentImages : receivedImages;
    currentList.removeAt(index);

    await prefs.setStringList('${type}_history_${user.uid}', currentList);

    setState(() {
      if (type == 'sent') {
        sentImages = currentList;
      } else {
        receivedImages = currentList;
      }
    });
  }

  Future<void> clearHistory(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all images in this history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await prefs.remove('${type}_history_${user.uid}');
              setState(() {
                if (type == 'sent') {
                  sentImages.clear();
                } else {
                  receivedImages.clear();
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String getCategory(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays <= 7) {
      return "Last Week";
    } else {
      return "Older";
    }
  }

  void showImageDialog(String base64Data) {
    Uint8List bytes = base64Decode(base64Data);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close")),
        ],
      ),
    );
  }

  Future<void> deleteCategoryImages(String type, String category, List<Map<String, dynamic>> imagesToDelete) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> currentList = type == 'sent' ? sentImages : receivedImages;

    setState(() {
      recentlyDeletedCategoryImages = imagesToDelete;
      recentlyDeletedCategory = category;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $category Images?'),
        content: Text('Are you sure you want to delete all images from "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final imagesBase64 = imagesToDelete.map((img) => img['original'] as String).toSet();
              currentList.removeWhere((item) => imagesBase64.contains(item));

              await prefs.setStringList('${type}_history_${user.uid}', currentList);

              setState(() {
                if (type == 'sent') {
                  sentImages = currentList;
                } else {
                  receivedImages = currentList;
                }
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$category deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      restoreDeletedCategory(type, category, imagesToDelete);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void restoreDeletedCategory(String type, String category, List<Map<String, dynamic>> images) {
    final prefs = SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      prefs.then((prefs) {
        List<String> currentList = type == 'sent' ? sentImages : receivedImages;

        final newImages = images.map((img) => img['original'] as String).toList();
        currentList.addAll(newImages);

        prefs.setStringList('${type}_history_${user.uid}', currentList);

        setState(() {
          if (type == 'sent') {
            sentImages = currentList;
          } else {
            receivedImages = currentList;
          }

          // Clear temporary storage
          recentlyDeletedCategoryImages = [];
          recentlyDeletedCategory = '';
        });
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> prepareCategorized(String type) {
    List<String> base64List = type == 'sent' ? sentImages : receivedImages;
    Map<String, List<Map<String, dynamic>>> result = {};

    for (var imageData in base64List) {
      final data = jsonDecode(imageData);
      final timestampString = data['timestamp'];
      final timestamp = timestampString != null ? DateTime.parse(timestampString) : DateTime.now();
      final category = getCategory(timestamp);

      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add({
        'image': data['image'],
        'timestamp': timestamp,
        'original': imageData,
      });
    }

    // Sort inside each category
    result.forEach((key, list) {
      list.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    });

    return result;
  }

  Widget buildListView(String type) {
    Map<String, List<Map<String, dynamic>>> localCategorizedImages = prepareCategorized(type);

    if (localCategorizedImages.isEmpty) {
      return const Center(child: Text("No history found"));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => clearHistory(type),
              icon: const Icon(Icons.delete_forever),
              label: const Text("Clear History"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: ListView(
              key: ValueKey(localCategorizedImages.length), // Important for animation!
              children: localCategorizedImages.entries.map((entry) {
                String category = entry.key;
                List<Map<String, dynamic>> images = entry.value;

                return StickyHeader(
                  header: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteCategoryImages(type, category, images),
                        ),
                      ],
                    ),
                  ),
                  content: Column(
                    children: images.map((img) {
                      final imageBytes = base64Decode(img['image']);
                      final formattedDate = DateFormat('MMMM d, yyyy').format(img['timestamp']);
                      final originalData = img['original'];

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            imageBytes,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: const Text("Image"),
                        subtitle: Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'view') {
                              showImageDialog(img['image']);
                            } else if (value == 'delete') {
                              deleteImage(type, (type == 'sent' ? sentImages : receivedImages).indexOf(originalData));
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          tabs: const [
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              buildListView('sent'),
              buildListView('received'),
            ],
          ),
        ),
      ],
    );
  }
}
