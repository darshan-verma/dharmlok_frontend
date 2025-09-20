import 'package:flutter/material.dart';
import '../../services/user_api_service.dart';
import '../../config/user_type_config.dart';

class UserBio extends StatefulWidget {
  final String userId;
  final UserType userType;
  
  const UserBio({
    Key? key, 
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  State<UserBio> createState() => _UserBioState();
}

class _UserBioState extends State<UserBio> {
  List<dynamic>? bio;
  bool isLoading = true;
  String? error;
  late UserApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = UserApiService.forUserType(widget.userType);
    fetchBiography();
  }

  Future<void> fetchBiography() async {
    try {
      final bioData = await apiService.fetchBiography(widget.userId);
      setState(() {
        bio = bioData ?? [];
        isLoading = false;
      });
      print('Fetched biography: $bio');
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    if (bio == null || bio!.isEmpty) {
      return const Center(child: Text('No biography available.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bio!.length,
      itemBuilder: (context, index) {
        final bioItem = bio![index];
        final type = bioItem['type'];
        final content = bioItem['content'] ?? [];
        final props = bioItem['props'] ?? {};

        return _renderBlockNoteItem(type, content, props);
      },
    );
  }

  Widget _renderBlockNoteItem(String type, dynamic content, Map<String, dynamic> props) {
    // Handle table type
    if (type == 'table' && content is Map && content['type'] == 'tableContent') {
      return _renderTable(Map<String, dynamic>.from(content));
    }

    // Handle heading type
    if (type == 'heading') {
      return _renderHeading(content, props);
    }

    // Handle bullet list item
    if (type == 'bulletListItem') {
      return _renderBulletListItem(content, props);
    }

    // Handle paragraph and other text types
    return _renderParagraph(content, props);
  }

  Widget _renderTable(Map<String, dynamic> tableContent) {
    final rows = tableContent['rows'] as List?;
    if (rows == null || rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade400),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows.map<TableRow>((row) {
          final cells = row['cells'] as List?;
          if (cells == null) return const TableRow(children: []);
          
          return TableRow(
            children: cells.map<Widget>((cell) {
              final cellContent = cell['content'] as List? ?? [];
              final cellProps = cell['props'] ?? {};
              
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildRichText(cellContent, cellProps, const TextStyle(fontSize: 15)),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _renderHeading(List<dynamic> content, Map<String, dynamic> props) {
    int level = props['level'] ?? 1;
    double fontSize = 22 - (level - 1) * 2.0;
    fontSize = fontSize < 14 ? 14 : fontSize; // Minimum font size
    
    final baseStyle = TextStyle(
      fontSize: fontSize, 
      fontWeight: FontWeight.bold,
      color: _getTextColor(props['textColor']),
    );

    final alignment = _getTextAlignment(props['textAlignment']);

    return Container(
      color: _getBackgroundColor(props['backgroundColor']),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      alignment: alignment,
      child: _buildRichText(content, props, baseStyle),
    );
  }

  Widget _renderBulletListItem(List<dynamic> content, Map<String, dynamic> props) {
    final baseStyle = TextStyle(
      fontSize: 15,
      color: _getTextColor(props['textColor']),
    );

    return Container(
      color: _getBackgroundColor(props['backgroundColor']),
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: baseStyle),
          Expanded(
            child: _buildRichText(content, props, baseStyle),
          ),
        ],
      ),
    );
  }

  Widget _renderParagraph(List<dynamic> content, Map<String, dynamic> props) {
    final baseStyle = TextStyle(
      fontSize: 15,
      color: _getTextColor(props['textColor']),
    );

    final alignment = _getTextAlignment(props['textAlignment']);

    return Container(
      color: _getBackgroundColor(props['backgroundColor']),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      alignment: alignment,
      child: _buildRichText(content, props, baseStyle),
    );
  }

  Widget _buildRichText(List<dynamic> content, Map<String, dynamic> props, TextStyle baseStyle) {
    List<InlineSpan> spans = [];
    
    print('_buildRichText called with content: $content');
    
    for (var c in content) {
      print('Processing content item: $c');
      if (c['type'] == 'text' && c['text'] != null) {
        print('Found text: ${c['text']}');
        TextStyle style = baseStyle;
        final styles = c['styles'] ?? {};
        
        if (styles is Map) {
          if (styles['bold'] == true) {
            style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
          }
          if (styles['italic'] == true) {
            style = style.merge(const TextStyle(fontStyle: FontStyle.italic));
          }
          if (styles['underline'] == true) {
            style = style.merge(const TextStyle(decoration: TextDecoration.underline));
          }
          if (styles['strikethrough'] == true) {
            style = style.merge(const TextStyle(decoration: TextDecoration.lineThrough));
          }
          if (styles['fontSize'] != null && styles['fontSize'] is num) {
            style = style.merge(TextStyle(fontSize: (styles['fontSize'] as num).toDouble()));
          }
          if (styles['textColor'] != null && styles['textColor'] is String) {
            style = style.merge(TextStyle(color: _parseColor(styles['textColor'])));
          }
          if (styles['backgroundColor'] != null && styles['backgroundColor'] is String) {
            style = style.merge(TextStyle(backgroundColor: _parseColor(styles['backgroundColor'])));
          }
        }
        spans.add(TextSpan(text: c['text'], style: style));
      }
    }
    
    print('Created ${spans.length} spans');
    
    return RichText(
      textAlign: _getTextAlignmentEnum(props['textAlignment']),
      text: TextSpan(
        children: spans.isNotEmpty ? spans : [TextSpan(text: 'No content', style: baseStyle)],
      ),
    );
  }

  Color? _getTextColor(String? textColor) {
    if (textColor == null || textColor == 'default') return Colors.black;
    return _parseColor(textColor);
  }

  Color? _getBackgroundColor(String? backgroundColor) {
    if (backgroundColor == null || backgroundColor == 'default') return null;
    return _parseColor(backgroundColor);
  }

  Color? _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      // Handle named colors
      switch (colorString.toLowerCase()) {
        case 'red': return Colors.red;
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'yellow': return Colors.yellow;
        case 'orange': return Colors.orange;
        case 'purple': return Colors.purple;
        case 'pink': return Colors.pink;
        case 'gray': case 'grey': return Colors.grey;
        case 'black': return Colors.black;
        case 'white': return Colors.white;
        default: return null;
      }
    } catch (_) {
      return null;
    }
  }

  Alignment _getTextAlignment(String? alignment) {
    switch (alignment) {
      case 'left': return Alignment.centerLeft;
      case 'center': return Alignment.center;
      case 'right': return Alignment.centerRight;
      case 'justify': return Alignment.centerLeft; // Flutter doesn't have justify
      default: return Alignment.centerLeft;
    }
  }

  TextAlign _getTextAlignmentEnum(String? alignment) {
    switch (alignment) {
      case 'left': return TextAlign.left;
      case 'center': return TextAlign.center;
      case 'right': return TextAlign.right;
      case 'justify': return TextAlign.justify;
      default: return TextAlign.left;
    }
  }
}