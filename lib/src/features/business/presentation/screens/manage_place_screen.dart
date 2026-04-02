import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/constants/app_constants.dart';
import 'package:queue/src/shared/models/place.dart';
import 'package:queue/src/shared/models/place_category.dart';
import 'package:queue/src/shared/repositories/firestore_places_repository.dart';

class ManagePlaceScreen extends StatefulWidget {
  const ManagePlaceScreen({super.key, required this.ownerId, this.place});

  final String ownerId;
  final Place? place;

  @override
  State<ManagePlaceScreen> createState() => _ManagePlaceScreenState();
}

class _ManagePlaceScreenState extends State<ManagePlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _instagramController;
  PlaceCategory _category = PlaceCategory.coffee;
  LatLng _selectedLatLng = const LatLng(
    AppConstants.tarazLatitude,
    AppConstants.tarazLongitude,
  );
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place?.name ?? '');
    _phoneController = TextEditingController(text: widget.place?.phone ?? '');
    _instagramController = TextEditingController(
      text: widget.place?.instagram ?? '',
    );
    _category = widget.place?.category ?? PlaceCategory.coffee;
    if (widget.place != null) {
      _selectedLatLng = widget.place!.latLng;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = context.read<FirestorePlacesRepository>();
    final place = Place(
      id: widget.place?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: widget.ownerId,
      name: _nameController.text.trim(),
      category: _category,
      latitude: _selectedLatLng.latitude,
      longitude: _selectedLatLng.longitude,
      phone: _phoneController.text.trim(),
      instagram: _instagramController.text.trim(),
      createdAt: widget.place?.createdAt ?? DateTime.now(),
      imageUrl: widget.place?.imageUrl,
    );

    if (widget.place == null) {
      await repo.createPlace(place);
    } else {
      await repo.updatePlace(place);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.place == null
              ? '${place.name} is now live in QueueLess'
              : '${place.name} updated successfully',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place == null ? 'Add Your Place' : 'Edit Place'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102638), Color(0xFF17324A)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.place == null
                      ? 'Create your business place'
                      : 'Refine your business presence',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Add strong contact details and a precise map pin so nearby users can trust and visit your place faster.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Place name',
                        hintText: 'Brown Coffee Taraz',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a place name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PlaceCategory>(
                      initialValue: _category,
                      items: PlaceCategory.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        hintText: '+7 700 123 4567',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Add your business phone'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        hintText: '@your_brand',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Add your Instagram handle'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tap on the map to set your exact business location',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 260,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLatLng,
                            zoom: AppConstants.defaultMapZoom,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: _selectedLatLng,
                            ),
                          },
                          onTap: (value) =>
                              setState(() => _selectedLatLng = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Selected: ${_selectedLatLng.latitude.toStringAsFixed(4)}, ${_selectedLatLng.longitude.toStringAsFixed(4)}',
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save place'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
