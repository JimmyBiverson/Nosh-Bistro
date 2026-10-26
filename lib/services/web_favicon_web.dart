import 'package:web/web.dart' as web;

void updateWebFavicon(String imageUrl) {
  final favicon = web.document.querySelector('link[rel~="icon"]');
  final url = imageUrl.isEmpty ? 'favicon.png' : imageUrl;
  if (favicon != null) {
    favicon.setAttribute('href', url);
  } else {
    web.document.head?.append(
      web.document.createElement('link')
        ..setAttribute('rel', 'icon')
        ..setAttribute('href', url),
    );
  }
}
