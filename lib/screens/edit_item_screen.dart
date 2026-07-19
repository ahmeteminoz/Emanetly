import 'dart:io';
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
    _selectedColorValue = widget.item.mockImageColorValue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      // 1. Kırpma Adımı (Crop)
      final croppedFile = await ImageUtils.cropImage(
        imageFile: File(pickedFile.path),
        isCircle: false,
      );
      if (croppedFile == null) return;

      // 2. Önizleme Adımı (Preview)
      if (!mounted) return;
      final confirm = await ImageUtils.showImagePreviewDialog(
        context: context,
        imageFile: croppedFile,
      );
      if (!confirm) return;

      setState(() {
        _selectedImagePath = croppedFile.path;
        _selectedColorValue = null; // Mock rengini gerçek fotoğraf seçildiğinde siliyoruz
      });
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
                  'Ürün Fotoğrafını Güncelle',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeriden Gerçek Fotoğraf Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Kameradan Gerçek Fotoğraf Çek'),
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
      imageUrl: _selectedColorValue != null ? null : _selectedImagePath,
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
              // Image Picker Area
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: _selectedImagePath != null && _selectedImagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _selectedImagePath!.startsWith('http')
                                  ? Image.network(_selectedImagePath!, fit: BoxFit.cover)
                                  : Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black.withOpacity(0.4),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImagePath = null;
                                        _selectedColorValue = widget.item.mockImageColorValue;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: theme.colorScheme.outline),
                              const SizedBox(height: 8),
                              Text('Ürün Fotoğrafını Güncelle', style: TextStyle(color: theme.colorScheme.outline)),
                            ],
                          ),
                        ),
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
