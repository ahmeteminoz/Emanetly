import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_utils.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';

class EditItemScreen extends StatefulWidget {
  final EmanetItem item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late String _selectedCategory;
  String? _selectedImagePath;
  final List<String> _selectedImagePaths = [];
  int? _selectedColorValue;
  bool _isSaving = false;
  double _uploadProgress = 0.0;

  final List<String> _categories = [
    'Elektronik',
    'Ders & Kırtasiye',
    'Spor & Hobi',
    'Günlük Eşya & Yaşam',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description);
    _locationController = TextEditingController(text: widget.item.location);
    
    final itemCategory = widget.item.category;
    if (_categories.contains(itemCategory)) {
      _selectedCategory = itemCategory;
    } else if (itemCategory == 'Ders/Kitap' || itemCategory == 'Kırtasiye') {
      _selectedCategory = 'Ders & Kırtasiye';
    } else if (itemCategory == 'Yağmurluk/Şemsiye') {
      _selectedCategory = 'Günlük Eşya & Yaşam';
    } else {
      _selectedCategory = 'Diğer';
    }

    _selectedImagePath = widget.item.imageUrl;
    _selectedImagePaths.addAll(widget.item.displayImages);
    if (_selectedImagePaths.isNotEmpty) {
      _selectedColorValue = null;
    } else {
      _selectedColorValue = widget.item.mockImageColorValue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImagePaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 5 fotoğraf ekleyebilirsiniz.')),
      );
      return;
    }
    final picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 80,
        );
        if (pickedFiles.isEmpty) return;
        final remainingSlots = 5 - _selectedImagePaths.length;
        final filesToAdd = pickedFiles.take(remainingSlots);
        setState(() {
          for (final file in filesToAdd) {
            _selectedImagePaths.add(file.path);
          }
          _selectedColorValue = null;
          _selectedImagePath = _selectedImagePaths.isNotEmpty ? _selectedImagePaths.last : null;
        });
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 80,
        );
        if (pickedFile == null) return;
        setState(() {
          _selectedImagePaths.add(pickedFile.path);
          _selectedColorValue = null;
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImageSourceSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fotoğraf Ekle',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeriden Fotoğraf Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Fotoğraf Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = AppStateProvider.of(context);
    await _performSave(appState);
  }

  Future<void> _performSave(AppState appState) async {
    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    final updatedItem = widget.item.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim(),
      imageUrl: _selectedColorValue != null ? null : (_selectedImagePaths.isNotEmpty ? _selectedImagePaths.first : null),
      images: _selectedColorValue != null ? const [] : _selectedImagePaths,
      mockImageColorValue: _selectedColorValue ?? widget.item.mockImageColorValue,
    );

    try {
      await appState.updateItem(
        updatedItem,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emanet ilanı başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Güncelleme Başarısız', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'İlan güncellenirken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('İptal', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'choose'),
                child: const Text('Yeni Resim Seç'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'retry'),
                child: const Text('Tekrar Dene'),
              ),
            ],
          );
        },
      );

      if (action == 'retry') {
        await _performSave(appState);
      } else if (action == 'choose') {
        _showImageSourceSheet();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanı Düzenle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedImagePaths.isEmpty && _selectedColorValue == null)
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Ürün Fotoğrafı Ekle (En fazla 5 adet)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fotoğraf seçmek veya şablon eklemek için dokunun',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fotoğraflar (${_selectedColorValue != null ? 1 : _selectedImagePaths.length}/5)',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_selectedColorValue != null)
                            const Text(
                              'Şablon Görseli Etkin',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110,
                        child: ReorderableListView(
                          scrollDirection: Axis.horizontal,
                          onReorder: (int oldIndex, int newIndex) {
                            if (_selectedColorValue != null) return;
                            if (oldIndex >= _selectedImagePaths.length || newIndex > _selectedImagePaths.length) {
                              return;
                            }
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final path = _selectedImagePaths.removeAt(oldIndex);
                              _selectedImagePaths.insert(newIndex, path);
                              _selectedImagePath = _selectedImagePaths.isNotEmpty ? _selectedImagePaths.last : null;
                            });
                          },
                          children: [
                            if (_selectedColorValue != null)
                              Container(
                                key: const ValueKey('mock_color_template'),
                                width: 110,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Color(_selectedColorValue!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.photo_outlined, color: Colors.white, size: 24),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Şablon',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black.withOpacity(0.4),
                                        child: IconButton(
                                          icon: const Icon(Icons.close, size: 10, color: Colors.white),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _selectedColorValue = null;
                                              _selectedImagePath = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._selectedImagePaths.asMap().entries.map((entry) {
                                final index = entry.key;
                                final path = entry.value;
                                final isCover = index == 0;
                                final isNetwork = path.startsWith('http');
                                return Container(
                                  key: ValueKey(path),
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCover ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                      width: isCover ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        GestureDetector(
                                          onTap: isNetwork
                                              ? null
                                              : () async {
                                                  final croppedFile = await ImageUtils.cropImage(
                                                    imageFile: File(path),
                                                    isCircle: false,
                                                  );
                                                  if (croppedFile != null) {
                                                    setState(() {
                                                      _selectedImagePaths[index] = croppedFile.path;
                                                    });
                                                  }
                                                },
                                          child: isNetwork
                                              ? Image.network(path, fit: BoxFit.cover)
                                              : Image.file(File(path), fit: BoxFit.cover),
                                        ),
                                        if (isCover)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: theme.colorScheme.primary.withOpacity(0.85),
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: const Text(
                                                'KAPAK',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.black.withOpacity(0.5),
                                            child: IconButton(
                                              icon: const Icon(Icons.close, size: 10, color: Colors.white),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedImagePaths.removeAt(index);
                                                  if (_selectedImagePaths.isEmpty) {
                                                    _selectedImagePath = null;
                                                  } else {
                                                    _selectedImagePath = _selectedImagePaths.last;
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            if (_selectedColorValue == null && _selectedImagePaths.length < 5)
                              GestureDetector(
                                key: const ValueKey('add_image_button'),
                                onTap: _showImageSourceSheet,
                                child: Container(
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CustomPaint(
                                    painter: DashRectPainter(
                                      color: theme.colorScheme.outlineVariant,
                                      strokeWidth: 1.5,
                                      gap: 3.0,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 24,
                                            color: theme.colorScheme.outline,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ekle',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.outline,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'İlan Başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Başlık zorunludur' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Teslim Alınacak Yer / Konum',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Konum zorunludur' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Eşya Açıklaması & Koşullar',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Açıklama zorunludur' : null,
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Görsel Yükleniyor... ${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    // Draw dashed lines
    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
