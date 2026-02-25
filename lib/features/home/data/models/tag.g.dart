// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagImpl _$$TagImplFromJson(Map<String, dynamic> json) => _$TagImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      colorCode: json['color_code'] as String,
      icon: json['icon'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$$TagImplToJson(_$TagImpl instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'description': instance.description,
      'color_code': instance.colorCode,
      'icon': instance.icon,
      'created_at': instance.createdAt,
    };
