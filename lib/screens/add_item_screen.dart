import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_utils.dart';
import '../providers/app_state_provider.dart';
import '../providers/app_state.dart';

class AddItemScreen extends StatefulWidget {
  final VoidCallback? onItemAdded;
  const AddItemScreen({super.key, this.onItemAdded});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Elektronik';
  String? _selectedImagePath;
  final List<String> _selectedImagePaths = [];
  bool _isPublishing = false;
  double _uploadProgress = 0.0;

  // Mock Photo Customizer variables
  int? _selectedColorValue;
  String? _mockImageLabel;

  final List<String> _categories = [
    'Elektronik',
    'Ders & Kırtasiye',
    'Spor & Hobi',
    'Günlük Eşya & Yaşam',
    'Diğer'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showMockGalleryDialog() {
    final colorOptions = [
      {'name': 'Mavi Şablon', 'value': 0xFF3B82F6, 'icon': Icons.laptop_mac},
      {'name': 'Kırmızı Şablon', 'value': 0xFFEF4444, 'icon': Icons.umbrella},
      {'name': 'Turuncu Şablon', 'value': 0xFFF59E0B, 'icon': Icons.calculate},
      {'name': 'Yeşil Şablon', 'value': 0xFF10B981, 'icon': Icons.menu_book},
      {'name': 'Mor Şablon', 'value': 0xFF8B5CF6, 'icon': Icons.architecture},
      {'name': 'Pembe Şablon', 'value': 0xFFEC4899, 'icon': Icons.category},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Görsel Şablon Seç'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: colorOptions.length,
              itemBuilder: (context, index) {
                final option = colorOptions[index];
                final color = Color(option['value'] as int);
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColorValue = option['value'] as int;
                      _mockImageLabel = option['name'] as String;
                      _selectedImagePath = option['name'] as String;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(option['icon'] as IconData, color: Colors.white, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          option['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickRealImage(ImageSource source) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
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
                    _pickRealImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Fotoğraf Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickRealImage(ImageSource.camera);
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
    await _performPublish(appState);
  }

  Future<void> _performPublish(AppState appState) async {
    setState(() {
      _isPublishing = true;
      _uploadProgress = 0.0;
    });

    try {
      final success = await appState.addNewItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        imageUrl: _selectedColorValue != null ? null : _selectedImagePath,
        images: _selectedColorValue != null ? const [] : _selectedImagePaths,
        mockColorValue: _selectedColorValue,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emanet ilanı başarıyla yayınlandı!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onItemAdded?.call();
        } else {
          throw Exception("Görsel yüklemesi veya veri tabanı kaydı başarısız oldu.");
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Yayınlama Başarısız', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'İlan yayınlanırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
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
        await _performPublish(appState);
      } else if (action == 'choose') {
        _showImageSourceSheet();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yeni Emanet Paylaş'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Card(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Eşyaları paylaştığında diğer öğrencilerin ödünç almasını sağlarsın. Lütfen güvenilir ve doğru bilgi giriniz.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Photo Picker Placeholder Widget
                if (_selectedImagePaths.isEmpty && _selectedColorValue == null)
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPaint(
                        painter: DashRectPainter(color: theme.colorScheme.outlineVariant),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: theme.colorScheme.outline,
                              ),
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
                                'Görsel eklemek veya şablon seçmek için dokunun',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
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
                                          Icon(
                                            _selectedImagePath == 'Kamera' ? Icons.camera_alt_outlined : Icons.photo_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _mockImageLabel ?? 'Şablon',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                                              _mockImageLabel = null;
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
                                          onTap: () async {
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
                                          child: Image.file(File(path), fit: BoxFit.cover),
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
                const SizedBox(height: 24),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Eşya Adı / Başlık',
                    hintText: 'Örn: Casio fx-82 Hesap Makinesi',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen eşya adını girin';
                    }
                    if (value.trim().length < 3) {
                      return 'Başlık en az 3 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Field
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Location Field
                TextFormField(
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Teslim Konumu',
                    hintText: 'Örn: Kütüphane 1. Kat / Mühendislik Kantini',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen teslim edilebilecek bir konum girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Açıklama / Kurallar',
                    hintText: 'Eşyanın durumu nedir? Ne zamana kadar ödünç verebilirsiniz?',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen eşya açıklaması yazın';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                _isPublishing
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Yayınla',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
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

class CameraSimulatorDialog extends StatefulWidget {
  final Function(int colorValue) onCaptured;
  const CameraSimulatorDialog({super.key, required this.onCaptured});

  @override
  State<CameraSimulatorDialog> createState() => _CameraSimulatorDialogState();
}

class _CameraSimulatorDialogState extends State<CameraSimulatorDialog> {
  bool _isFlashing = false;

  void _capture() {
    setState(() {
      _isFlashing = true;
    });
    // Pick a color randomly representing mock camera photo
    final colorOptions = [0xFF3B82F6, 0xFFEF4444, 0xFFF59E0B, 0xFF10B981, 0xFF8B5CF6, 0xFFEC4899];
    final capturedColor = colorOptions[DateTime.now().millisecond % colorOptions.length];

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onCaptured(capturedColor);
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Viewfinder background grid simulator
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: GridPaper(
                  color: Colors.white,
                  divisions: 1,
                  subdivisions: 1,
                  interval: 100,
                ),
              ),
            ),
            // Viewfinder frame overlay lines
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            // Shutter overlay buttons
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Fotoğraf Çekmek İçin Dokunun',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Camera Title
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'KAMERA VİZÖRÜ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Camera Grid indicator icons
            Positioned(
              bottom: 54,
              left: 48,
              child: IconButton(
                icon: const Icon(Icons.flash_off, color: Colors.white54, size: 24),
                onPressed: () {},
              ),
            ),
            Positioned(
              bottom: 54,
              right: 48,
              child: IconButton(
                icon: const Icon(Icons.switch_camera, color: Colors.white54, size: 24),
                onPressed: () {},
              ),
            ),
            // Flash animation overlay
            if (_isFlashing)
              Positioned.fill(
                child: Container(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
