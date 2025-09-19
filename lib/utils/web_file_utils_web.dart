// Web implementation: use browser APIs to trigger download
import 'dart:html' as html;

Future<bool> webDownloadString(String fileName, String content) async {
  try {
    final bytes = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    return false;
  }
}
