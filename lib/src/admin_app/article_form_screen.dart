import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart'; // For input formatters

import 'package:myapp/src/models/article.dart';

class ArticleFormScreen extends StatefulWidget {
  final String? articleId;

  const ArticleFormScreen({super.key, this.articleId});

  @override
  State<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends State<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _sourceController = TextEditingController();

  double _importance = 50;
  double _minZoom = 3;
  double _maxZoom = 15;
  DateTime _publishedAt = DateTime.now();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.articleId != null) {
      _loadArticleData(widget.articleId!);
    }
  }

  Future<void> _loadArticleData(String articleId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await _firestore.collection('articles').doc(articleId).get();
      if (doc.exists) {
        final article = Article.fromFirestore(doc, null);
        _titleController.text = article.title;
        _descriptionController.text = article.description;
        _urlController.text = article.url;
        _imageUrlController.text = article.imageUrl ?? '';
        _latitudeController.text = article.location.latitude.toString();
        _longitudeController.text = article.location.longitude.toString();
        _sourceController.text = article.source;
        _importance = article.importance.toDouble();
        _minZoom = article.minZoom.toDouble();
        _maxZoom = article.maxZoom.toDouble();
        _publishedAt = article.publishedAt;
      }
    } catch (e) {
      _showSnackBar('Failed to load article: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _crawlArticle() async {
    if (_urlController.text.isEmpty) {
      _showSnackBar('Please enter an article URL to crawl.', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Call the Cloud Function for crawling here
    // For now, this is a placeholder. The actual Cloud Function will extract data.
    // Replace with actual Cloud Function call
    await Future.delayed(const Duration(seconds: 2)); // Simulate network request

    // Mock data for demonstration
    _titleController.text = 'Crawled Article Title';
    _descriptionController.text = 'This is a description crawled from the provided URL.';
    _imageUrlController.text = 'https://picsum.photos/400/300';
    _sourceController.text = 'Crawled Source';
    _latitudeController.text = '37.5665'; // Seoul Lat
    _longitudeController.text = '126.9780'; // Seoul Lng

    _showSnackBar('Article data crawled successfully (mock)!', Colors.green);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final article = Article(
        id: widget.articleId ?? _firestore.collection('articles').doc().id, // Generate new ID if creating
        title: _titleController.text,
        description: _descriptionController.text,
        url: _urlController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        location: LatLng(
          double.parse(_latitudeController.text),
          double.parse(_longitudeController.text),
        ),
        importance: _importance.toInt(),
        minZoom: _minZoom.toInt(),
        maxZoom: _maxZoom.toInt(),
        publishedAt: _publishedAt,
        source: _sourceController.text,
      );

      if (widget.articleId == null) {
        // Create new article
        await _firestore.collection('articles').doc(article.id).set(article.toFirestore());
        _showSnackBar('Article created successfully!', Colors.green);
      } else {
        // Update existing article
        await _firestore.collection('articles').doc(article.id).update(article.toFirestore());
        _showSnackBar('Article updated successfully!', Colors.green);
      }
      if (mounted) context.pop(); // Go back to dashboard
    } catch (e) {
      _showSnackBar('Failed to save article: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleId == null ? 'Create New Article' : 'Edit Article'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Article URL',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.travel_explore),
                          onPressed: _crawlArticle,
                          tooltip: 'Crawl article data from URL',
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'URL cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Description cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL (Optional)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: const InputDecoration(labelText: 'Latitude'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
                            validator: (value) => value!.isEmpty || double.tryParse(value) == null ? 'Invalid Latitude' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: const InputDecoration(labelText: 'Longitude'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
                            validator: (value) => value!.isEmpty || double.tryParse(value) == null ? 'Invalid Longitude' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(labelText: 'Source'),
                      validator: (value) => value!.isEmpty ? 'Source cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Importance: ${_importance.toInt()}'),
                    Slider(
                      value: _importance,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: _importance.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _importance = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Min Zoom: ${_minZoom.toInt()}'),
                    Slider(
                      value: _minZoom,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: _minZoom.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _minZoom = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Max Zoom: ${_maxZoom.toInt()}'),
                    Slider(
                      value: _maxZoom,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: _maxZoom.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _maxZoom = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveArticle,
                        child: Text(widget.articleId == null ? 'Add Article' : 'Update Article'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _imageUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _sourceController.dispose();
    super.dispose();
  }
}
