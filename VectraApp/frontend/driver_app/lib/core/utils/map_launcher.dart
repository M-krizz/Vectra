import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps for navigation to the specified coordinates.
/// Works on Web, Android, and iOS.
Future<void> launchGoogleMaps(double lat, double lng) async {
  if (kIsWeb) {
    // On web, just open in a new tab
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
    return;
  }

  // On Android, try the native Google Maps navigation intent first
  if (Platform.isAndroid) {
    final Uri googleNavUri = Uri.parse(
      'google.navigation:q=$lat,$lng&mode=d',
    );
    if (await canLaunchUrl(googleNavUri)) {
      await launchUrl(googleNavUri);
      return;
    }

    // Fallback: try geo: scheme (works with any maps app)
    final Uri geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
  }

  // On iOS, try Apple Maps first, then Google Maps
  if (Platform.isIOS) {
    final Uri appleMapsUri = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d',
    );
    if (await canLaunchUrl(appleMapsUri)) {
      await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
      return;
    }
  }

  // Universal fallback: open Google Maps web URL in external browser
  final Uri googleMapsUrl = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );

  // Don't check canLaunchUrl for https — just try to launch directly.
  // canLaunchUrl can return false on some Android versions even when
  // the browser is available, due to package visibility restrictions.
  try {
    final launched = await launchUrl(
      googleMapsUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Could not launch Maps for coordinates: $lat, $lng');
    }
  } catch (_) {
    throw Exception('Could not launch Maps for coordinates: $lat, $lng');
  }
}
