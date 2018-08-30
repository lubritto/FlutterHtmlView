import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_video.dart';
import 'package:flutter_youtube/flutter_youtube.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:flutter_html_view/flutter_html_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class HtmlParser {
  HtmlParser();

  String _apiKey;

  Widget _buildPlaceholder() => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          new LimitedBox(
              maxHeight: 90.0,
              maxWidth: 90.0,
              child: CircularProgressIndicator()),
        ],
      );

  _parseChildren(dom.Element e, widgetList) {
    print(e);

    if (e is String || e is dom.Text) {
      String old = e.text;

      var newElement = dom.Element.tag('p')..text = old;

      widgetList.add(Padding(
          padding: EdgeInsets.only(bottom: 0.0),
          child: HtmlText(data: newElement.outerHtml)));
      return;
    } else if (!e.outerHtml.contains("<img") &&
        !e.outerHtml.contains("<iframe")) {
      print(e.outerHtml);
      widgetList.add(Padding(
          padding: EdgeInsets.only(bottom: 0.0),
          child: HtmlText(data: e.outerHtml)));
      return;
    } else if (e.localName == "img" && e.attributes.containsKey('src')) {
      var src = e.attributes['src'];

      if (src.startsWith("http") || src.startsWith("https")) {
        widgetList.add(CachedNetworkImage(
          imageUrl: src,
          fit: BoxFit.cover,
        ));
      } else if (src.startsWith('data:image')) {
        var exp = RegExp(r'data:.*;base64,');
        var base64Str = src.replaceAll(exp, '');
        var bytes = base64.decode(base64Str);

        widgetList.add(Image.memory(bytes, fit: BoxFit.cover));
      }
    } else if (e.localName == "iframe" && e.attributes.containsKey('src')) {
      String src = e.attributes['src'] as String;

      String id = src.split("/embed/")[1];

      widgetList.add(GestureDetector(
          onTap: () {
            FlutterYoutube.playYoutubeVideoByUrl(
              apiKey: _apiKey,
              videoUrl: "https://www.youtube.com/watch?v=$id",
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: 'https://img.youtube.com/vi/$id/0.jpg',
                fit: BoxFit.cover,
                placeholder: _buildPlaceholder(),
              ),
              Center(
                  child: Container(
                alignment: Alignment.center,
                width: 70.0,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/YouTube_play_buttom_icon_%282013-2017%29.svg/1280px-YouTube_play_buttom_icon_%282013-2017%29.svg.png',
                  fit: BoxFit.cover,
                ),
              ))
            ],
          )));
    } else if (e.localName == "video") {
      if (e.attributes.containsKey('src')) {
        var src = e.attributes['src'];
        // var videoElements = e.getElementsByTagName("video");
        widgetList.add(
          new NetworkPlayerLifeCycle(
            src,
            (BuildContext context, VideoPlayerController controller) =>
                new AspectRatioVideo(controller),
          ),
        );
      } else {
        if (e.children.length > 0) {
          e.children.forEach((dom.Element source) {
            try {
              if (source.attributes['type'] == "video/mp4") {
                var src = e.children[0].attributes['src'];
                widgetList.add(
                  new NetworkPlayerLifeCycle(
                    src,
                    (BuildContext context, VideoPlayerController controller) =>
                        new AspectRatioVideo(controller),
                  ),
                );
              }
            } catch (e) {
              print(e);
            }
          });
        }
      }
    } else if (e.nodes.length > 0)
      e.nodes.forEach((e) => _parseChildren(e, widgetList));
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

    List<dom.Node> docBodyChildren = docBody.nodes;

    if (docBodyChildren.length > 0)
      docBodyChildren.forEach((e) => _parseChildren(e, widgetList));

    return widgetList;
  }
}
