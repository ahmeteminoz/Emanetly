import 'package:flutter/material.dart';
import '../models/item.dart';
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
    
    // Normalize categories to match dropdown options
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = AppStateProvider.of(context);
    
    final updatedItem = widget.item.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim(),
      imageUrl: _selectedColorValue != null ? null : _selectedImagePath,
      mockImageColorValue: _selectedColorValue ?? widget.item.mockImageColorValue,
    );

    await appState.updateItem(updatedItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emanet ilanı başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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
              ElevatedButton(
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
