import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../database/database_helper.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(List<int> mentionedUserIds)? onMentionsChanged;
  final int maxLines;
  final int? minLines;

  const MentionTextField({
    super.key,
    required this.controller,
    this.hintText = 'Write a comment...',
    this.onMentionsChanged,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<MentionTextField> createState() => MentionTextFieldState();
}

class MentionTextFieldState extends State<MentionTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<User> _suggestedUsers = [];
  String _currentMentionQuery = '';
  int _cursorPosition = 0;
  final List<int> _mentionedUserIds = [];
  final Map<String, int> _mentionedUsers = {}; // @username -> userId

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    _cursorPosition = widget.controller.selection.baseOffset;

    // Check if user is typing @ for mention
    if (_cursorPosition > 0 && _cursorPosition <= text.length) {
      final textBeforeCursor = text.substring(0, _cursorPosition);
      final lastAtIndex = textBeforeCursor.lastIndexOf('@');

      if (lastAtIndex != -1) {
        final afterAt = textBeforeCursor.substring(lastAtIndex + 1);
        
        // Check if we're still in a mention (no space after @)
        if (!afterAt.contains(' ')) {
          _currentMentionQuery = afterAt;
          _searchUsers(_currentMentionQuery);
          return;
        }
      }
    }

    _removeOverlay();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      final allUsers = await DatabaseHelper.instance.getAllUsers();
      setState(() {
        _suggestedUsers = allUsers.take(5).map((u) => User.fromMap(u)).toList();
      });
    } else {
      final users = await DatabaseHelper.instance.searchUsers(query);
      setState(() {
        _suggestedUsers = users.map((u) => User.fromMap(u)).toList();
      });
    }

    if (_suggestedUsers.isNotEmpty && mounted) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -200), // Position above the text field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF246BFD),
                      child: Text(
                        user.prenom[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    onTap: () => _selectUser(user),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectUser(User user) {
    final text = widget.controller.text;
    final textBeforeCursor = text.substring(0, _cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final beforeMention = text.substring(0, lastAtIndex);
      final afterCursor = text.substring(_cursorPosition);
      final mention = '@${user.prenom}';

      final newText = '$beforeMention$mention $afterCursor';
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: beforeMention.length + mention.length + 1),
      );

      // Track the mentioned user
      _mentionedUsers[mention] = user.id!;
      if (!_mentionedUserIds.contains(user.id!)) {
        _mentionedUserIds.add(user.id!);
      }

      // Notify parent
      widget.onMentionsChanged?.call(_mentionedUserIds);
    }

    _removeOverlay();
  }

  // Extract mentioned user IDs from text
  List<int> getMentionedUserIds() {
    final text = widget.controller.text;
    final mentionedIds = <int>[];

    for (final entry in _mentionedUsers.entries) {
      if (text.contains(entry.key)) {
        mentionedIds.add(entry.value);
      }
    }

    return mentionedIds;
  }

  // Clear mentions
  void clearMentions() {
    _mentionedUsers.clear();
    _mentionedUserIds.clear();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF246BFD), width: 2),
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
