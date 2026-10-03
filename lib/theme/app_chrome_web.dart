import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/material.dart';

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

void _setMeta(String name, String content) {
  final head = html.document.head;
  if (head == null) return;
  html.Element? el = html.document.querySelector('meta[name="$name"]');
  if (el == null) {
    el = html.MetaElement()..name = name;
    head.append(el);
  }
  el.setAttribute('content', content);
}

/// Push this screen's chrome into FlutterGo preview letterboxing + theme-color.
void syncPreviewChrome(Color top, Color bottom) {
  final topHex = _hex(top);
  final bottomHex = _hex(bottom);
  _setMeta('theme-color', topHex);
  _setMeta('od-chrome-top', topHex);
  _setMeta('od-chrome-bottom', bottomHex);
  try {
    js.context.callMethod('FgSetChrome', [topHex, bottomHex]);
  } catch (_) {}
}
