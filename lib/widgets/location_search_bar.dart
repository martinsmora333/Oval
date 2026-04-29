import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/maps_config.dart';
import '../utils/location_search_utils.dart';
import '../utils/location_utils.dart';

/// A widget that displays a search bar with location suggestions.
class LocationSearchBar extends StatefulWidget {
  /// The hint text to display in the search bar.
  final String hintText;

  /// The text style of the search bar hint.
  final TextStyle? hintStyle;

  /// The text style of the search bar text.
  final TextStyle? textStyle;

  /// The color of the search bar.
  final Color? backgroundColor;

  /// The color of the search bar border.
  final Color? borderColor;

  /// The border radius of the search bar.
  final BorderRadius? borderRadius;

  /// The elevation of the search bar.
  final double elevation;

  /// The padding of the search bar.
  final EdgeInsetsGeometry? padding;

  /// The margin of the search bar.
  final EdgeInsetsGeometry? margin;

  /// The prefix icon of the search bar.
  final Widget? prefixIcon;

  /// The suffix icon of the search bar.
  final Widget? suffixIcon;

  /// Callback when a location is selected.
  final Function(LatLng position, String address)? onLocationSelected;

  /// Callback when the search bar is tapped.
  final VoidCallback? onTap;

  /// Callback when the search text changes.
  final ValueChanged<String>? onChanged;

  /// The controller for the search bar text field.
  final TextEditingController? controller;

  /// The focus node for the search bar text field.
  final FocusNode? focusNode;

  /// Whether the search bar is enabled.
  final bool enabled;

  /// Whether to show the clear button.
  final bool showClearButton;

  /// Whether to show the search icon.
  final bool showSearchIcon;

  /// The color of the cursor.
  final Color? cursorColor;

  /// The style of the cursor.
  final TextSelectionThemeData? cursorStyle;

  /// The decoration of the search bar.
  final InputDecoration? decoration;

  /// The initial value of the search bar.
  final String? initialValue;

  /// The keyboard type of the search bar.
  final TextInputType? keyboardType;

  /// The text input action of the search bar.
  final TextInputAction? textInputAction;

  /// The text capitalisation of the search bar.
  final TextCapitalization textCapitalization;

  /// The style of the text in the search bar.
  final TextStyle? style;

  /// The style of the text in the search bar when it is disabled.
  final TextStyle? disabledStyle;

  /// The style of the text in the search bar when it has an error.
  final TextStyle? errorStyle;

  /// The maximum number of lines for the search bar.
  final int? maxLines;

  /// The minimum number of lines for the search bar.
  final int? minLines;

  /// Whether to expand the search bar to fill the available space.
  final bool expands;

  /// The maximum length of the search bar text.
  final int? maxLength;

  /// Whether to show the character counter.
  final bool showCounter;

  /// Whether to obscure the search bar text.
  final bool obscureText;

  /// Whether to autocorrect the search bar text.
  final bool autocorrect;

  /// Whether to enable suggestions for the search bar text.
  final bool enableSuggestions;

  /// Whether to enable the interactive selection of the search bar text.
  final bool enableInteractiveSelection;

  /// The scroll padding for the search bar.
  final EdgeInsets scrollPadding;

  /// Whether to enable the floating cursor for the search bar.
  final bool enableFloatingCursor;

  /// The scroll physics for the search bar.
  final ScrollPhysics? scrollPhysics;

  /// The scroll controller for the search bar.
  final ScrollController? scrollController;

  /// The autofocus setting for the search bar.
  final bool autofocus;

  /// The initial position of the cursor in the search bar.
  final int? cursorPosition;

  /// The initial selection of the search bar text.
  final TextSelection? initialSelection;

  /// The keyboard appearance of the search bar.
  final Brightness? keyboardAppearance;

  /// The color of the cursor when the search bar is focused.
  final Color? focusColor;

  /// The color of the cursor when the search bar is not focused.
  final Color? unfocusColor;

  /// The color of the cursor when the search bar is disabled.
  final Color? disabledColor;

  /// The color of the cursor when the search bar has an error.
  final Color? errorColor;

  /// The color of the cursor when the search bar is hovered.
  final Color? hoverColor;

  /// The color of the cursor when the search bar is focused.
  final Color? highlightColor;

  /// The splash color of the cursor when the search bar is pressed.
  final Color? splashColor;

  /// The color of the cursor when the search bar is selected.
  final Color? selectedColor;

  /// The color of the cursor when the search bar is selected and hovered.
  final Color? selectedHoverColor;

  /// The color of the cursor when the search bar is selected and pressed.
  final Color? selectedPressedColor;

  /// The color of the cursor when the search bar is disabled and hovered.
  final Color? disabledHoverColor;

  /// The color of the cursor when the search bar is disabled and pressed.
  final Color? disabledPressedColor;

  /// The color of the cursor when the search bar is disabled and selected.
  final Color? disabledSelectedColor;

  /// The color of the cursor when the search bar is disabled, selected, and hovered.
  final Color? disabledSelectedHoverColor;

  /// The color of the cursor when the search bar is disabled, selected, and pressed.
  final Color? disabledSelectedPressedColor;

  /// Creates a [LocationSearchBar] widget.
  const LocationSearchBar({
    super.key,
    this.hintText = 'Search for a location',
    this.hintStyle,
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.elevation = 2.0,
    this.padding,
    this.margin,
    this.prefixIcon,
    this.suffixIcon,
    this.onLocationSelected,
    this.onTap,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.showClearButton = true,
    this.showSearchIcon = true,
    this.cursorColor,
    this.cursorStyle,
    this.decoration,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.style,
    this.disabledStyle,
    this.errorStyle,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.showCounter = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection = true,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableFloatingCursor = true,
    this.scrollPhysics,
    this.scrollController,
    this.autofocus = false,
    this.cursorPosition,
    this.initialSelection,
    this.keyboardAppearance,
    this.focusColor,
    this.unfocusColor,
    this.disabledColor,
    this.errorColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.selectedColor,
    this.selectedHoverColor,
    this.selectedPressedColor,
    this.disabledHoverColor,
    this.disabledPressedColor,
    this.disabledSelectedColor,
    this.disabledSelectedHoverColor,
    this.disabledSelectedPressedColor,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isSearching = false;
  List<Prediction> _suggestions = [];
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_controller.text.isEmpty) {
      setState(() {
        _searchQuery = '';
        _suggestions = [];
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_controller.text.isNotEmpty) {
        _searchPlaces(_controller.text);
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final apiKey = MapsConfig.googlePlacesApiKey;
      if (apiKey.isEmpty) {
        throw Exception('Google Places API key not found');
      }

      // Get current location for bias
      LatLng? currentLocation;
      try {
        final position = await LocationUtils.getCurrentPosition();
        currentLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        // Ignore error and continue without location bias
      }

      final predictions = await LocationSearchUtils.searchPlaces(
        query: query,
        apiKey: apiKey,
        location: currentLocation,
        radius: 10000, // 10km radius
      );

      if (mounted) {
        setState(() {
          _suggestions = predictions;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error searching for locations'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _searchPlaces(query),
            ),
          ),
        );
      }
    }
  }

  void _onSuggestionSelected(Prediction prediction) async {
    _controller.text = prediction.description ?? '';
    _focusNode.unfocus();
    _removeOverlay();

    try {
      final apiKey = MapsConfig.googlePlacesApiKey;
      if (apiKey.isEmpty) {
        throw Exception('Google Places API key not found');
      }

      final details = await LocationSearchUtils.getPlaceDetails(
        placeId: prediction.placeId ?? '',
        apiKey: apiKey,
        fields: ['geometry', 'formatted_address'],
      );

      if (details != null && details.geometry?.location != null) {
        final location = details.geometry!.location;
        final position = LatLng(location.lat, location.lng);

        widget.onLocationSelected?.call(
          position,
          details.formattedAddress ?? prediction.description ?? '',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error getting location details'),
          ),
        );
      }
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 8.0,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 4.0,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsList() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No results found'),
        );
      }
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(suggestion.structuredFormatting?.mainText ?? ''),
          subtitle: Text(suggestion.structuredFormatting?.secondaryText ?? ''),
          onTap: () => _onSuggestionSelected(suggestion),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: widget.hintStyle,
          filled: true,
          fillColor: widget.backgroundColor ?? Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: widget.borderColor ?? Theme.of(context).dividerColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: widget.borderColor ?? Theme.of(context).dividerColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
          contentPadding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          prefixIcon: widget.showSearchIcon
              ? (widget.prefixIcon ?? const Icon(Icons.search))
              : null,
          suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _suggestions = [];
                      _searchQuery = '';
                    });
                  },
                )
              : widget.suffixIcon,
        ),
        style: widget.textStyle,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        enabled: widget.enabled,
        cursorColor: widget.cursorColor,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        expands: widget.expands,
        maxLength: widget.maxLength,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.enableSuggestions,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        scrollPadding: widget.scrollPadding,
        scrollPhysics: widget.scrollPhysics,
        scrollController: widget.scrollController,
        autofocus: widget.autofocus,
      ),
    );
  }
}
