import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DharmguruPhotos extends StatefulWidget {
  final String guruId;
  const DharmguruPhotos({Key? key, required this.guruId}) : super(key: key);

  @override
  State<DharmguruPhotos> createState() => _DharmguruPhotosState();
}

class _DharmguruPhotosState extends State<DharmguruPhotos> with AutomaticKeepAliveClientMixin {
  List<dynamic>? photos;
  bool isLoading = true;
  String? error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchPhotos();
  }

  Future<void> fetchPhotos() async {
    try {
      print('Fetching photos for guruId: ${widget.guruId}');
      final response = await http.get(
        Uri.parse('https://darshan-dharmlok.vercel.app/api/users/${widget.guruId}'),
      );

      print('Photos API Status: ${response.statusCode}');
      print('Photos API Response length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both 'images' array and single 'image' field
        if (data['images'] != null && data['images'] is List) {
          photos = data['images'];
          print('Found ${photos!.length} images in images array');
        } else if (data['image'] != null) {
          // If single image, wrap it in a list
          photos = [data['image']];
          print('Found single image');
        } else {
          photos = [];
          print('No images field found in response');
        }
        print('Photos loaded: ${photos?.length ?? 0}');
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load photos: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching photos: $e');
      setState(() {
        error = 'Error loading photos: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load photos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error!.length > 200 ? '${error!.substring(0, 200)}...' : error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  fetchPhotos();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (photos == null || photos!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No photos available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          isLoading = true;
          error = null;
        });
        await fetchPhotos();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.0,
        ),
        itemCount: photos!.length,
        itemBuilder: (context, index) {
          final image = photos![index];
          final imageUrl = image['url'] ?? '';
          final title = image['title'] ?? '';
          final description = image['description'] ?? '';

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
