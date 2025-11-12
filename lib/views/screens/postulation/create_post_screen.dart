import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../models/postulation_model.dart';
import '../../../core/constant/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../database/database_helper.dart';
import 'package:animate_do/animate_do.dart';


class CreatePostScreen extends StatefulWidget {
  final Post? post;
  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String title = "";
  String description = "";
  String tagsText = "";
  String? imagePath;
  bool _isSubmitting = false;

  final ImagePicker picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      title = widget.post!.title;
      description = widget.post!.description;
      imagePath = widget.post!.imagePath;
      tagsText = widget.post!.tags;
    }
    
    // Pulse animation for image picker when no image
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      // Save image to app documents folder
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedImage.path);
      final savedImage = await File(pickedImage.path).copy('${appDir.path}/$fileName');

      setState(() {
        imagePath = savedImage.path; // store the local path
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        title: FadeIn(
          duration: const Duration(milliseconds: 600),
          child: Text(
            widget.post == null ? "Create New Post" : "Edit Post",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section with gradient
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      const Color(0xFF7C3AED),
                      AppTheme.primaryColor.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(-5, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
                child: Column(
                  children: [
                    Pulse(
                      infinite: true,
                      duration: const Duration(milliseconds: 1800),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.post == null ? Icons.add_photo_alternate_rounded : Icons.edit_rounded,
                          size: 54,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.post == null 
                          ? "Share your amazing event!"
                          : "Update your post",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Post Title *", Icons.title),
                          const SizedBox(height: 8),
                          _buildTextField(
                            initialValue: title,
                            hint: "Enter an eye-catching title (min 5 letters)...",
                            icon: Icons.edit_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Title is required";
                              }
                              // Count only alphabetic characters
                              final alphabeticChars = value.replaceAll(RegExp(r'[^a-zA-Z]'), '');
                              if (alphabeticChars.length < 5) {
                                return "Title must contain at least 5 alphabetic characters";
                              }
                              return null;
                            },
                            onSaved: (value) => title = value!,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Description *", Icons.description),
                          const SizedBox(height: 8),
                          _buildTextField(
                            initialValue: description,
                            hint: "Tell us more about your event (minimum 10 characters)...",
                            icon: Icons.notes,
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Description is required";
                              }
                              if (value.trim().length < 10) {
                                return "Description must be at least 10 characters";
                              }
                              return null;
                            },
                            onSaved: (value) => description = value!,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tags Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Tags *", Icons.local_offer),
                          const SizedBox(height: 4),
                          Text(
                            "Format: #tag1, #tag2, #tag3",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            initialValue: tagsText,
                            hint: "#music, #concert, #festival",
                            icon: Icons.tag,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Tags are required";
                              }
                              // Check if tags start with #
                              final tags = value.split(',').map((e) => e.trim()).toList();
                              for (var tag in tags) {
                                if (tag.isNotEmpty && !tag.startsWith('#')) {
                                  return "Each tag must start with # (e.g., #music)";
                                }
                              }
                              return null;
                            },
                            onSaved: (value) => tagsText = value ?? '',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Image Section
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 550),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Post Image *", Icons.image),
                          const SizedBox(height: 8),
                          _buildImagePicker(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 700),
                      child: _buildSubmitButton(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.15),
                AppTheme.primaryColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.primaryColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppTheme.primaryColor,
              width: 2.5,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
        onSaved: onSaved,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: imagePath != null 
                ? [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ]
                : [
                    AppTheme.primaryColor.withOpacity(0.05),
                    AppTheme.primaryColor.withOpacity(0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: imagePath != null 
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withOpacity(0.4),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: imagePath != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      key: ValueKey(imagePath),
                    ),
                  ),
                  // Overlay with change button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Change",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ScaleTransition(
                scale: _pulseAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.2),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 56,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tap to add an image",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "JPG, PNG up to 10MB",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            const Color(0xFF7C3AED),
            AppTheme.primaryColor.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () async {
          // Prevent double submission
          if (_isSubmitting) return;
          
          if (_formKey.currentState!.validate()) {
            // Validate image is required
            if (imagePath == null || imagePath!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Please add an image to your post'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }
            
            setState(() => _isSubmitting = true);
            
            _formKey.currentState!.save();

            // Get current user ID
            if (authProvider.user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not authenticated')),
              );
              setState(() => _isSubmitting = false);
              return;
            }

            try {
              final post = Post(
                id: widget.post?.id, // Keep existing ID if updating
                title: title,
                description: description,
                imagePath: imagePath,
                userId: authProvider.user!.id!,
                tags: tagsText,
                date: widget.post?.date ?? DateTime.now(), // Keep original date if updating
              );

              bool success;
              if (widget.post != null) {
                // Update existing post
                success = await DatabaseHelper.instance.updatePost(post.toMap());
              } else {
                // Create new post
                success = await DatabaseHelper.instance.addPost(post.toMap());
              }

              if (!mounted) return;
              
              if (success) {
                Navigator.pop(context, post);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.post != null ? 'Failed to update post' : 'Failed to create post'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() => _isSubmitting = false);
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _isSubmitting = false);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.post == null ? Icons.publish_rounded : Icons.update_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.post == null ? "Publish Post" : "Update Post",
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}