
import "dart:io";

void main() {
  final dir = Directory("./lib");
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith(".dart"));
  
  for (var file in files) {
    if (file.path.contains("app_theme.dart") || file.path.contains("app_colors.dart")) continue;
    
    var content = file.readAsStringSync();
    var originalLength = content.length;
    
    // Replace hardcoded whites for backgrounds with surface color
    content = content.replaceAll("backgroundColor: Colors.white,", "backgroundColor: Theme.of(context).colorScheme.surface,");
    content = content.replaceAll("color: Colors.white,", "color: Theme.of(context).colorScheme.surface,");
    content = content.replaceAll("color: Colors.white)", "color: Theme.of(context).colorScheme.surface)");
    
    // Replace light grays with surfaceVariant
    content = content.replaceAll("Color(0xFFF5F7FA)", "Theme.of(context).colorScheme.surfaceVariant"); 
    content = content.replaceAll("Color(0xFFF3F4F6)", "AppColors.divider");
    content = content.replaceAll("Color(0xFFE5E7EB)", "AppColors.border");
    
    // Replace specific container colors
    content = content.replaceAll("Color(0xFFE8F0FE)", "AppColors.primary.withOpacity(0.1)");
    content = content.replaceAll("Color(0xFFE8F5E9)", "AppColors.success.withOpacity(0.1)");
    content = content.replaceAll("Color(0xFFFFF3E0)", "AppColors.warning.withOpacity(0.1)");
    content = content.replaceAll("Color(0xFFFFEBEE)", "AppColors.error.withOpacity(0.1)");
    content = content.replaceAll("Color(0xFFEDE7F6)", "AppColors.secondary.withOpacity(0.1)");

    if (content.length != originalLength && !content.contains("import 'package:vectra_rider/")) {
       file.writeAsStringSync(content);
       stdout.writeln("Updated ${file.path}");
    }
  }
}

