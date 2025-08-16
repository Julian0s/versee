import 'package:flutter/material.dart';
import 'package:versee/services/playlist_service.dart';

enum NotesContentType { lyrics, notes }

class NoteItem {
  final String id;
  final String title;
  final int slideCount;
  final DateTime createdDate;
  final String description;
  final NotesContentType type;
  final List<NoteSlide> slides;
  final String? audioUrl;
  final Duration? audioDuration;

  NoteItem({
    required this.id,
    required this.title,
    required this.slideCount,
    required this.createdDate,
    required this.description,
    required this.type,
    required this.slides,
    this.audioUrl,
    this.audioDuration,
  });

  NoteItem copyWith({
    String? id,
    String? title,
    int? slideCount,
    DateTime? createdDate,
    String? description,
    NotesContentType? type,
    List<NoteSlide>? slides,
    String? audioUrl,
    Duration? audioDuration,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      slideCount: slideCount ?? this.slideCount,
      createdDate: createdDate ?? this.createdDate,
      description: description ?? this.description,
      type: type ?? this.type,
      slides: slides ?? this.slides,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
    );
  }

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
}

class NoteSlide {
  final String id;
  final String content;
  final String? backgroundImageUrl;
  final bool isBackgroundGif;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Duration? displayDuration;
  final int order;
  final bool hasTextShadow;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  NoteSlide({
    required this.id,
    required this.content,
    this.backgroundImageUrl,
    this.isBackgroundGif = false,
    this.backgroundColor,
    this.textStyle,
    this.displayDuration,
    required this.order,
    this.hasTextShadow = false,
    this.shadowColor,
    this.shadowBlurRadius = 2.0,
    this.shadowOffset = const Offset(1.0, 1.0),
  });

  NoteSlide copyWith({
    String? id,
    String? content,
    String? backgroundImageUrl,
    bool? isBackgroundGif,
    Color? backgroundColor,
    TextStyle? textStyle,
    Duration? displayDuration,
    int? order,
    bool? hasTextShadow,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) {
    return NoteSlide(
      id: id ?? this.id,
      content: content ?? this.content,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      isBackgroundGif: isBackgroundGif ?? this.isBackgroundGif,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      displayDuration: displayDuration ?? this.displayDuration,
      order: order ?? this.order,
      hasTextShadow: hasTextShadow ?? this.hasTextShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }

  bool get hasBackgroundImage => backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;
}

int _textDecorationToInt(TextDecoration decoration) {
  switch (decoration) {
    case TextDecoration.none:
      return 0;
    case TextDecoration.underline:
      return 1;
    case TextDecoration.overline:
      return 2;
    case TextDecoration.lineThrough:
      return 3;
    default:
      return 0;
  }
}

// Extensão para converter NoteItem para PresentationItem
extension NoteItemExtension on NoteItem {
  List<PresentationItem> toPresentationItems() {
    return slides.map((slide) {
      return PresentationItem(
        id: '${id}_slide_${slide.id}',
        title: '$title - Slide ${slide.order + 1}',
        type: type == NotesContentType.lyrics ? ContentType.lyrics : ContentType.notes,
        content: slide.content,
        metadata: {
          'noteId': id,
          'slideId': slide.id,
          'slideOrder': slide.order,
          'backgroundImageUrl': slide.backgroundImageUrl,
          'isBackgroundGif': slide.isBackgroundGif,
          'backgroundColor': slide.backgroundColor?.value,
          'textStyle': slide.textStyle != null ? {
            'color': slide.textStyle!.color?.value,
            'fontSize': slide.textStyle!.fontSize,
            'fontWeight': slide.textStyle!.fontWeight?.index,
            'fontStyle': slide.textStyle!.fontStyle?.index,
            'decoration': slide.textStyle!.decoration != null ? _textDecorationToInt(slide.textStyle!.decoration!) : null,
          } : null,
          'hasTextShadow': slide.hasTextShadow,
          'shadowColor': slide.shadowColor?.value,
          'shadowBlurRadius': slide.shadowBlurRadius,
          'shadowOffsetX': slide.shadowOffset.dx,
          'shadowOffsetY': slide.shadowOffset.dy,
          'hasAudio': hasAudio,
          'audioUrl': audioUrl,
          'audioDuration': audioDuration?.inMilliseconds,
          'displayDuration': slide.displayDuration?.inMilliseconds,
        },
      );
    }).toList();
  }
}