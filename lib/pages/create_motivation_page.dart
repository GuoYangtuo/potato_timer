import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:potato_timer/l10n/app_localizations.dart';
import 'package:potato_timer/models/motivation.dart';
import 'package:potato_timer/services/api_service.dart';
import 'package:potato_timer/theme/app_theme.dart';

class CreateMotivationPage extends StatefulWidget {
  final Motivation? editMotivation;

  const CreateMotivationPage({super.key, this.editMotivation});

  @override
  State<CreateMotivationPage> createState() => _CreateMotivationPageState();
}

class _CreateMotivationPageState extends State<CreateMotivationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _picker = ImagePicker();

  MotivationType _type = MotivationType.positive;
  bool _isPublic = false;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _mediaItems = [];
  List<String> _tags = [];
  List<Map<String, dynamic>> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
    
    if (widget.editMotivation != null) {
      final m = widget.editMotivation!;
      _titleController.text = m.title ?? '';
      _contentController.text = m.content ?? '';
      _type = m.type;
      _isPublic = m.isPublic;
      _tags = List.from(m.tags);
      _mediaItems = m.media.map((item) => {
        'type': item.type,
        'url': item.url,
        'thumbnailUrl': item.thumbnailUrl,
        'isUploaded': true,
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await ApiService().getTags();
      setState(() => _availableTags = tags);
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (final image in images) {
        setState(() {
          _mediaItems.add({
            'type': 'image',
            'file': File(image.path),
            'isUploaded': false,
          });
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _mediaItems.add({
          'type': 'video',
          'file': File(video.path),
          'isUploaded': false,
        });
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 至少需要标题或内容或媒体
    if (_titleController.text.trim().isEmpty && 
        _contentController.text.trim().isEmpty && 
        _mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写标题、内容或添加媒体')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 先上传未上传的媒体
      final uploadedMedia = <Map<String, dynamic>>[];
      
      for (final item in _mediaItems) {
        if (item['isUploaded'] == true) {
          uploadedMedia.add({
            'type': item['type'],
            'url': item['url'],
            'thumbnailUrl': item['thumbnailUrl'],
          });
        } else {
          final result = await ApiService().uploadFile(item['file'] as File);
          uploadedMedia.add({
            'type': result['type'],
            'url': result['url'],
            'thumbnailUrl': result['thumbnailUrl'],
          });
        }
      }

      if (widget.editMotivation != null) {
        await ApiService().updateMotivation(widget.editMotivation!.id, {
          'title': _titleController.text.trim().isEmpty 
              ? null 
              : _titleController.text.trim(),
          'content': _contentController.text.trim().isEmpty 
              ? null 
              : _contentController.text.trim(),
          'type': _type == MotivationType.positive ? 'positive' : 'negative',
          'isPublic': _isPublic,
          'media': uploadedMedia,
          'tags': _tags,
        });
      } else {
        await ApiService().createMotivation(
          title: _titleController.text.trim().isEmpty 
              ? null 
              : _titleController.text.trim(),
          content: _contentController.text.trim().isEmpty 
              ? null 
              : _contentController.text.trim(),
          type: _type == MotivationType.positive ? 'positive' : 'negative',
          isPublic: _isPublic,
          media: uploadedMedia,
          tags: _tags,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.editMotivation != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? l10n.editMotivation : l10n.createMotivation),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 类型选择
            Text(
              l10n.motivationType,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    type: MotivationType.positive,
                    icon: Icons.thumb_up_rounded,
                    title: l10n.positive,
                    subtitle: l10n.positiveDesc,
                    color: AppTheme.positiveColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    type: MotivationType.negative,
                    icon: Icons.thumb_down_rounded,
                    title: l10n.negative,
                    subtitle: l10n.negativeDesc,
                    color: AppTheme.negativeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 标题
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题（可选）',
                hintText: _type == MotivationType.positive 
                    ? '例如：理想中的生活' 
                    : '例如：不想重蹈覆辙',
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // 内容
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: l10n.content,
                hintText: '写下这段经历或想法...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            // 媒体上传
            Text(
              l10n.addMedia,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildMediaSection(),
            const SizedBox(height: 24),

            // 标签
            Text(
              l10n.addTags,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTagsSection(l10n),
            const SizedBox(height: 24),

            // 公开设置
            _buildSwitchTile(
              title: l10n.publicMotivation,
              subtitle: '公开后其他用户可以看到并收藏',
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required MotivationType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _type == type;

    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        // 已添加的媒体
        if (_mediaItems.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) {
                final item = _mediaItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: item['isUploaded'] == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                child: Image.network(
                                  item['url'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                child: Image.file(
                                  item['file'] as File,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (item['type'] == 'video')
                        const Positioned(
                          bottom: 4,
                          left: 4,
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 添加按钮
        Row(
          children: [
            Expanded(
              child: _buildAddMediaButton(
                icon: Icons.photo_library_rounded,
                label: '添加图片',
                onTap: _pickImages,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAddMediaButton(
                icon: Icons.video_library_rounded,
                label: '添加视频',
                onTap: _pickVideo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已选标签
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // 输入框
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '输入自定义标签',
                  isDense: true,
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addTag(_tagController.text.trim()),
              icon: const Icon(Icons.add_rounded),
              color: AppTheme.primaryColor,
            ),
          ],
        ),

        // 推荐标签
        if (_availableTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.popularTags,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags
                .where((t) => !_tags.contains(t['name']))
                .take(10)
                .map((tag) {
              return GestureDetector(
                onTap: () => _addTag(tag['name'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tag['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

