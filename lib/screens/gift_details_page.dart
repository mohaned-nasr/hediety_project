import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/gift.dart';
import '../services/database_helper.dart';
import '../models/user.dart';
import '../services/firebase_sync_service.dart';
//import '../services/notifi_service.dart';

class GiftDetailsPage extends StatefulWidget {
  final Gift gift;
  final User currentUser;

  GiftDetailsPage({required this.gift, required this.currentUser});

  @override
  _GiftDetailsPageState createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late String _status;
  String? _imageUrl;
  bool isReadOnly = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift.name);
    _categoryController = TextEditingController(text: widget.gift.category);
    _priceController = TextEditingController(text: widget.gift.price.toString());
    _status = widget.gift.status;
    _imageUrl = widget.gift.imageUrl;

    // Determine read-only mode
    isReadOnly = _status == 'pledged' || widget.gift.userId != widget.currentUser.id;

    print('Initialized GiftDetailsPage: '
        'giftId=${widget.gift.id}, currentUserId=${widget.currentUser.id}, isReadOnly=$isReadOnly, status=$_status');
  }

  @override
  Widget build(BuildContext context) {
    final isFriendViewing = widget.gift.userId != widget.currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gift Details'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildTextField('Name', _nameController, isReadOnly),
                    SizedBox(height: 16),
                    _buildTextField('Category', _categoryController, isReadOnly),
                    SizedBox(height: 16),
                    _buildTextField('Price', _priceController, isReadOnly, isNumber: true),
                    SizedBox(height: 20),
                    _imageSection(),
                    if (!isFriendViewing && _status != 'pledged')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: _buildSwitch(),
                      ),
                    if (isFriendViewing && _status == 'available')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _pledgeGift(),
                          icon: Icon(Icons.card_giftcard),
                          label: Text('Pledge Gift'),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isReadOnly && _status != 'pledged')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveGiftDetails,
                    child: Text('Save Changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isReadOnly, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      enabled: !isReadOnly,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isNumber && double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageUrl != null && _imageUrl!.isNotEmpty
              ? Image.network(
            _imageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
              : Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
        if (!isReadOnly)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.upload),
              label: Text('Upload Image'),
            ),
          ),
      ],
    );
  }

  Widget _buildSwitch() {
    return SwitchListTile(
      title: Text('Status: ${_status.toUpperCase()}'),
      value: _status == 'pledged',
      onChanged: (bool value) {
        setState(() {
          _status = value ? 'pledged' : 'available';
        });
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageUrl = pickedFile.path;
      });
    }
  }

  void _saveGiftDetails() async {
    if (_formKey.currentState!.validate()) {
      final updatedGift = Gift(
        firebaseKey: widget.gift.firebaseKey,
        id: widget.gift.id,
        name: _nameController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text),
        status: _status,
        imageUrl: _imageUrl ?? widget.gift.imageUrl,
        eventId: widget.gift.eventId,
        userId: widget.gift.userId,
      );

      await FirebaseSyncService().syncLocalGifts([updatedGift]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift details updated!')),
      );
      Navigator.pop(context);
    }
  }

  void _pledgeGift() async {
    try {
      // Update gift data
      final updatedGift = Gift(
        firebaseKey: widget.gift.firebaseKey,
        id: widget.gift.id,
        name: widget.gift.name,
        category: widget.gift.category,
        price: widget.gift.price,
        status: 'pledged',
        pledgedTo: widget.currentUser.id, // Set the current user as pledger
        eventId: widget.gift.eventId,
        userId: widget.gift.userId,
        imageUrl: widget.gift.imageUrl,
      );

      await FirebaseSyncService().syncLocalGifts([updatedGift]); // Sync with Firebase or local DB

      // Send notification to gift list creator
      /*if (widget.gift.userId != widget.currentUser.id) {
        final creatorName = await dbHelper.getUserNameById(widget.gift.userId);
        NotificationService().showNotification(
          title: 'Gift Pledged!',
          body: '${widget.currentUser.name} pledged to buy ${widget.gift.name}.',
        );
      }*/

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.gift.name} has been pledged!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error pledging gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pledge gift.')),
      );
    }
  }

}
