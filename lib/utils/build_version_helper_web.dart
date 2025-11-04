import 'dart:html' as html;
import 'dart:js_util' as js_util;

String getAppBuildVersion() {
  try {
    final dynamic value = js_util.getProperty(html.window, 'APP_BUILD_VERSION');
    if (value is String && value.isNotEmpty && value != '__APP_BUILD_VERSION__') {
      return value;
    }
  } catch (_) {
    // Ignore and fall through to returning empty string.
  }
  return '';
}
