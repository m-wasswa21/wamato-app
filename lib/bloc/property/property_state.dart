import 'package:equatable/equatable.dart';
import '../../models/property.dart';

abstract class PropertyState extends Equatable {
  const PropertyState();
  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {
  const PropertyInitial();
}

class PropertyLoading extends PropertyState {
  const PropertyLoading();
}

class PropertyLoaded extends PropertyState {
  final List<Property> featured;
  final List<Property> stays;
  final List<Property> recent;

  const PropertyLoaded({
    required this.featured,
    required this.stays,
    required this.recent,
  });

  @override
  List<Object?> get props => [featured, stays, recent];
}

class PropertyError extends PropertyState {
  final String message;
  const PropertyError(this.message);
  @override
  List<Object?> get props => [message];
}
