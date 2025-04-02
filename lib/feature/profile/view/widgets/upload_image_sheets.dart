import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageUploadBottomSheet extends StatefulWidget {
  const ImageUploadBottomSheet({
    required this.onImageSelected,
    super.key,
    this.maxHeight = 400,
  });
  final void Function(File) onImageSelected;
  final double maxHeight;

  static Future<void> show(
      BuildContext context, void Function(File) onImageSelected) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ImageUploadBottomSheet(onImageSelected: onImageSelected),
    );
  }

  @override
  State<ImageUploadBottomSheet> createState() => _ImageUploadBottomSheetState();
}

class _ImageUploadBottomSheetState extends State<ImageUploadBottomSheet> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isDenied) {
      setState(() {
        _errorMessage =
            'Permission denied. Please enable permissions in settings.';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (source == ImageSource.camera) {
        await _requestPermission(Permission.camera);
      } else {
        await _requestPermission(Permission.photos);
      }

      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  void _confirmSelection() {
    if (_selectedImage != null) {
      widget.onImageSelected(_selectedImage!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight:
            _selectedImage != null ? widget.maxHeight + 240 : widget.maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose an image from the options below',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Error message if any
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade50,
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),

          // Image preview
          if (_selectedImage != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),

          // Upload options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOptionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take a photo',
                  subtitle: 'Use your camera to take a new photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from gallery',
                  subtitle: 'Select an image from your device',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),

          // Confirm button
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Use This Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
