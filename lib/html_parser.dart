import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_video.dart';
import 'package:flutter_youtube/flutter_youtube.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:flutter_html_view/flutter_html_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HtmlParser {
  HtmlParser();

  String _apiKey;

  _parseChildren(e, widgetList) {
    print(e);
    if (e is dom.Text) {
      widgetList.add(new HtmlText(data: e.text));
    } else if (e.localName == "img" && e.attributes.containsKey('src')) {
      var src = e.attributes['src'];

      if (src.startsWith("http") || src.startsWith("https")) {
        widgetList.add(new CachedNetworkImage(
          imageUrl: src,
          fit: BoxFit.cover,
        ));
      } else if (src.startsWith('data:image')) {
        var exp = new RegExp(r'data:.*;base64,');
        var base64Str = src.replaceAll(exp, '');
        var bytes = base64.decode(base64Str);

        widgetList.add(new Image.memory(bytes, fit: BoxFit.cover));
      }
    } else if (e.localName == "video" && e.attributes.containsKey('src')) {
      String src = e.attributes['src'] as String;

      String id = src.split("=")[1];

      widgetList.add(
        GestureDetector(
          onTap: () {
            FlutterYoutube.playYoutubeVideoByUrl(
              apiKey: _apiKey,
              videoUrl: "https://www.youtube.com/watch?v=id",
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: 'https://img.youtube.com/vi/$id/0.jpg',
                fit: BoxFit.cover,
              ),
              Center(
                child: Container(
                  alignment: Alignment.center,
                  width: 70.0,
                  child: CachedNetworkImage(
                    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/YouTube_play_buttom_icon_%282013-2017%29.svg/1280px-YouTube_play_buttom_icon_%282013-2017%29.svg.png',
                    fit: BoxFit.cover,
                  ),
                )
              )
            ],
          )
        )
      );
    } else if (!e.outerHtml.contains("<img") ||
        !e.outerHtml.contains("<video") ||
        !e.hasContent()) {
      print(e.outerHtml);
      widgetList.add(new HtmlText(data: e.outerHtml));
    }

    if (e.children.length > 0)
      e.children.forEach((e) => _parseChildren(e, widgetList));
  }

  List<Widget> HParse(String html, String apiKey) {
    _apiKey = apiKey;

    List<Widget> widgetList = new List();

    dom.Document document = parse(html);

    dom.Element docBody = document.body;

    List<dom.Element> styleElements = docBody.getElementsByTagName("style");
    List<dom.Element> scriptElements = docBody.getElementsByTagName("script");
    if (styleElements.length > 0) {
      for (int i = 0; i < styleElements.length; i++) {
        docBody.getElementsByTagName("style").first.remove();
      }
    }
    if (scriptElements.length > 0) {
      for (int i = 0; i < scriptElements.length; i++) {
        docBody.getElementsByTagName("script").first.remove();
      }
    }

    List<dom.Element> docBodyChildren = docBody.children;
    if (docBodyChildren.length > 0)
      docBodyChildren.forEach((e) => _parseChildren(e, widgetList));

    return widgetList;
  }
}
