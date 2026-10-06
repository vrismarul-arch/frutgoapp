import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'order_placed_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // =========================================================
  // COLORS
  // =========================================================

  static const Color green = Color(0xFF65B83D);
  static const Color dark = Color(0xFF252525);
  static const Color grey = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);

  // =========================================================
  // FORM
  // =========================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _addressLine2Controller =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // =========================================================
  // CHECKOUT STATE
  // =========================================================

  // Delivery date/time is not user-selectable.
  // It always reflects the exact current date & time and is
  // refreshed live so the "Delivery Schedule" card on screen
  // always shows the real current booking time, not a fixed slot.
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  bool _loadingAddresses = false;
  bool _gettingLocation = false;
  bool _placingOrder = false;
  bool _showSavedAddresses = false;

  String? _addressError;

  // =========================================================
  // LOCATION
  // =========================================================

  double? _latitude;
  double? _longitude;

  // =========================================================
  // SELECTED ADDRESS
  // =========================================================

  String? _selectedAddressId;

  List<SavedAddress> _savedAddresses = [];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckoutData();
    });

    // Keep the displayed "current booking time" ticking live
    // while the user is on the checkout screen.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    _clockTimer?.cancel();

    super.dispose();
  }

  // =========================================================
  // LOAD CHECKOUT DATA
  // =========================================================

  Future<void> _loadCheckoutData() async {
    final AuthProvider authProvider = context.read<AuthProvider>();

    final UserModel? user = authProvider.user;

    if (user != null) {
      _loadUserDetails(user);
    }

    await _loadSavedAddresses();
  }

  // =========================================================
  // LOAD USER DETAILS
  // =========================================================

  void _loadUserDetails(UserModel user) {
    _nameController.text = user.name;
    _emailController.text = user.email;

    try {
      final dynamic json = user.toJson();

      if (json is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);

        final String phone = _readValue(
          data,
          ['phone', 'mobile', 'mobileNumber', 'phoneNumber'],
        );

        if (phone.isNotEmpty) {
          _phoneController.text = phone;
        }

        final String address = _readValue(
          data,
          ['address', 'deliveryAddress', 'houseAddress', 'streetAddress'],
        );

        if (address.isNotEmpty) {
          _addressController.text = address;
        }

        final String city = _readValue(
          data,
          ['city', 'location', 'town'],
        );

        if (city.isNotEmpty) {
          _cityController.text = city;
        }

        final String state = _readValue(
          data,
          ['state', 'stateName'],
        );

        if (state.isNotEmpty) {
          _stateController.text = state;
        }

        final String pincode = _readValue(
          data,
          ['pincode', 'pinCode', 'postalCode', 'zipCode', 'zip'],
        );

        if (pincode.isNotEmpty) {
          _pincodeController.text = pincode;
        }
      }
    } catch (e) {
      debugPrint('FRUTGO USER DETAILS ERROR: $e');
    }
  }

  // =========================================================
  // READ VALUE
  // =========================================================

  String _readValue(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value != null) {
        final String result = value.toString().trim();

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return '';
  }

  // =========================================================
  // LOAD SAVED ADDRESSES
  // =========================================================

  Future<void> _loadSavedAddresses() async {
    if (!mounted) return;

    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });

    try {
      final dynamic response = await ApiService.instance.getAddresses();

      debugPrint('FRUTGO ADDRESSES RESPONSE: $response');

      List<dynamic> rawAddresses = [];

      // -----------------------------------------------------
      // RESPONSE IS DIRECT LIST
      // -----------------------------------------------------

      if (response is List) {
        rawAddresses = response;
      }

      // -----------------------------------------------------
      // RESPONSE IS MAP
      // -----------------------------------------------------

      else if (response is Map) {
        final dynamic addresses = response['addresses'] ??
            response['data']?['addresses'] ??
            response['data'] ??
            response['results'];

        if (addresses is List) {
          rawAddresses = addresses;
        }
      }

      final List<SavedAddress> addresses = rawAddresses
          .whereType<Map>()
          .map(
            (item) => SavedAddress.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((address) => address.id.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _savedAddresses = addresses;
      });

      // -----------------------------------------------------
      // AUTO SELECT DEFAULT
      // -----------------------------------------------------

      if (addresses.isNotEmpty) {
        SavedAddress selected = addresses.first;

        for (final address in addresses) {
          if (address.isDefault) {
            selected = address;
            break;
          }
        }

        _selectSavedAddress(selected, closeDropdown: false);
      }
    } catch (e) {
      debugPrint('FRUTGO ADDRESS ERROR: $e');

      if (mounted) {
        setState(() {
          _addressError = _cleanError(e);
        });
      }
    } finally {
      // IMPORTANT: NO RETURN INSIDE FINALLY
      if (mounted) {
        setState(() {
          _loadingAddresses = false;
        });
      }
    }
  }

  // =========================================================
  // SELECT SAVED ADDRESS
  // =========================================================

  void _selectSavedAddress(
    SavedAddress address, {
    bool closeDropdown = true,
  }) {
    if (!mounted) return;

    setState(() {
      _selectedAddressId = address.id;

      if (address.fullName.isNotEmpty) {
        _nameController.text = address.fullName;
      }

      if (address.phone.isNotEmpty) {
        _phoneController.text = address.phone;
      }

      _addressController.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pincodeController.text = address.pincode;

      _latitude = address.latitude;
      _longitude = address.longitude;

      if (closeDropdown) {
        _showSavedAddresses = false;
      }
    });

    debugPrint('FRUTGO SELECTED ADDRESS: ${address.id}');
  }

  // =========================================================
  // CURRENT LOCATION
  // =========================================================

  Future<void> _getCurrentLocation() async {
    if (_gettingLocation) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _gettingLocation = true;
    });

    try {
      // =======================================================
      // LOCATION SERVICE
      // =======================================================

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          _showMessage(
            'Please turn on location services.',
            error: true,
          );
        }

        return;
      }

      // =======================================================
      // PERMISSION
      // =======================================================

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showMessage(
            'Location permission is required.',
            error: true,
          );
        }

        return;
      }

      // =======================================================
      // GET GPS
      // =======================================================

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final double latitude = position.latitude;
      final double longitude = position.longitude;

      debugPrint('FRUTGO CURRENT LOCATION: $latitude, $longitude');

      // =======================================================
      // REVERSE GEOCODING
      // (renamed to geoService — avoids clashing with the
      // 'geocoding' import prefix)
      // =======================================================

      final geocoding.Geocoding geoService = geocoding.Geocoding();

      final List<geocoding.Placemark> placemarks =
          await geoService.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        if (mounted) {
          _showMessage(
            'Unable to find address from location.',
            error: true,
          );
        }

        return;
      }

      final geocoding.Placemark place = placemarks.first;

      // =======================================================
      // BUILD ADDRESS
      // =======================================================

      final List<String> addressParts = [];

      final String name = (place.name ?? '').trim();
      final String street = (place.street ?? '').trim();
      final String thoroughfare = (place.thoroughfare ?? '').trim();
      final String subLocality = (place.subLocality ?? '').trim();

      if (name.isNotEmpty) {
        addressParts.add(name);
      }

      if (street.isNotEmpty && street != name) {
        addressParts.add(street);
      }

      if (thoroughfare.isNotEmpty &&
          thoroughfare != street &&
          thoroughfare != name) {
        addressParts.add(thoroughfare);
      }

      if (subLocality.isNotEmpty) {
        addressParts.add(subLocality);
      }

      final String address = addressParts.join(', ');

      // =======================================================
      // CITY
      // =======================================================

      final String city = (place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              '')
          .trim();

      // =======================================================
      // STATE
      // =======================================================

      final String state = (place.administrativeArea ?? '').trim();

      // =======================================================
      // PINCODE
      // =======================================================

      final String pincode = (place.postalCode ?? '').trim();

      if (!mounted) return;

      // =======================================================
      // UPDATE FORM
      // =======================================================

      setState(() {
        if (address.isNotEmpty) {
          _addressController.text = address;
        }

        if (city.isNotEmpty) {
          _cityController.text = city;
        }

        if (state.isNotEmpty) {
          _stateController.text = state;
        }

        if (pincode.isNotEmpty) {
          _pincodeController.text = pincode;
        }

        _latitude = latitude;
        _longitude = longitude;

        // Current GPS address is not a saved address.
        _selectedAddressId = null;
      });

      _showMessage('Current location added successfully.');
    } catch (e) {
      debugPrint('FRUTGO LOCATION ERROR: $e');

      if (mounted) {
        _showMessage(
          'Unable to get current location.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // =========================================================
  // API DATE
  // =========================================================

  String _formatApiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // =========================================================
  // API TIME (24hr, for backend)
  // =========================================================

  String _formatApiTime(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    final String second = date.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }

  // =========================================================
  // DISPLAY TIME (current booking time, 12hr with AM/PM)
  // =========================================================

  String _formatDisplayTime(DateTime date) {
    int hour12 = date.hour % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }

  // =========================================================
  // DISPLAY DATE
  // =========================================================

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // =========================================================
  // VALIDATE NAME
  // =========================================================

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Enter your name';
    }

    return null;
  }

  // =========================================================
  // VALIDATE PHONE
  // =========================================================

  String? _validatePhone(String? value) {
    final String phone = (value ?? '').trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Enter valid 10-digit mobile number';
    }

    return null;
  }

  // =========================================================
  // VALIDATE EMAIL
  // =========================================================

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter valid email address';
    }

    return null;
  }

  // =========================================================
  // VALIDATE ADDRESS
  // =========================================================

  String? _validateAddress(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Enter delivery address';
    }

    return null;
  }

  // =========================================================
  // VALIDATE CITY
  // =========================================================

  String? _validateCity(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Enter city';
    }

    return null;
  }

  // =========================================================
  // VALIDATE PINCODE
  // =========================================================

  String? _validatePincode(String? value) {
    final String pincode = (value ?? '').trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      return 'Enter valid 6-digit pincode';
    }

    return null;
  }

  // =========================================================
  // PLACE ORDER
  // =========================================================

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();

    if (_placingOrder) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      _showMessage(
        'Please login before placing an order.',
        error: true,
      );

      return;
    }

    final CartProvider cart = context.read<CartProvider>();

    if (cart.items.isEmpty) {
      _showMessage(
        'Your cart is empty.',
        error: true,
      );

      return;
    }

    // Capture the exact moment the order is placed — this is the
    // real "current booking time" sent to the backend and shown
    // on the success screen.
    final DateTime bookingTime = DateTime.now();

    final Map<String, dynamic> orderData = {
      'name': _nameController.text.trim(),
      'mobile': _phoneController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'address': _addressController.text.trim(),
      'addressLine2': _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),

      // Always the exact current date & time of booking.
      'deliveryDate': _formatApiDate(bookingTime),
      'bookingTime': _formatApiTime(bookingTime),
      'deliveryTime': _formatDisplayTime(bookingTime),

      'paymentMethod': 'cod',

      // GPS
      'latitude': _latitude,
      'longitude': _longitude,

      // Saved address ID
      'addressId': _selectedAddressId,
    };

    debugPrint('================================');
    debugPrint('FRUTGO PLACE ORDER');
    debugPrint(orderData.toString());
    debugPrint('================================');

    setState(() {
      _placingOrder = true;
    });

    try {
      final Map<String, dynamic> response =
          await ApiService.instance.placeOrder(orderData);

      debugPrint('FRUTGO ORDER SUCCESS');
      debugPrint(response.toString());

      // =======================================================
      // REFRESH CART
      // =======================================================

      try {
        await cart.loadCart();
      } catch (e) {
        debugPrint('FRUTGO CART REFRESH ERROR: $e');
      }

      if (!mounted) {
        return;
      }

      // =======================================================
      // NAVIGATE TO FULL-SCREEN ORDER PLACED SCREEN
      // (replaces the old dialog — pushReplacement so the user
      // can't swipe/back into the checkout form after ordering)
      // =======================================================

      final Map<String, dynamic> orderMap =
          response['order'] is Map
              ? Map<String, dynamic>.from(response['order'] as Map)
              : <String, dynamic>{};

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(
            order: orderMap,
            bookingTime: bookingTime,
          ),
        ),
      );
    } catch (e) {
      debugPrint('FRUTGO ORDER ERROR: $e');

      if (mounted) {
        _showMessage(
          _cleanError(e),
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  // =========================================================
  // ERROR
  // =========================================================

  String _cleanError(Object error) {
    String message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }

    return message;
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // INPUT FIELD
  // =========================================================

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: green),
          filled: true,
          fillColor: const Color(0xFFF7F9F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: dark,
      ),
    );
  }

  // =========================================================
  // PRICE ROW
  // =========================================================

  Widget _priceRow(String title, double amount, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SAVED ADDRESS SECTION
  // =========================================================

  Widget _buildSavedAddressSection() {
    // -------------------------------------------------------
    // LOADING
    // -------------------------------------------------------

    if (_loadingAddresses) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8DF)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: green,
              ),
            ),
            SizedBox(width: 12),
            Text('Loading saved addresses...'),
          ],
        ),
      );
    }

    // -------------------------------------------------------
    // NO ADDRESS
    // -------------------------------------------------------

    if (_savedAddresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8DF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No saved addresses found. '
                'Use current location or enter your address manually.',
              ),
            ),
          ],
        ),
      );
    }

    SavedAddress? selectedAddress;

    for (final address in _savedAddresses) {
      if (address.id == _selectedAddressId) {
        selectedAddress = address;
        break;
      }
    }

    return Column(
      children: [
        // -----------------------------------------------------
        // SELECTED ADDRESS
        // -----------------------------------------------------

        InkWell(
          onTap: () {
            setState(() {
              _showSavedAddresses = !_showSavedAddresses;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _selectedAddressId != null
                    ? green
                    : const Color(0xFFE2E8DF),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAddress?.addressLabel ??
                            'Choose Saved Address',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedAddress == null
                            ? 'Select a saved address'
                            : '${selectedAddress.addressLine1}'
                              '${selectedAddress.city.isNotEmpty ? ', ${selectedAddress.city}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showSavedAddresses
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),

        // -----------------------------------------------------
        // ADDRESS LIST
        // -----------------------------------------------------

        if (_showSavedAddresses)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8DF)),
            ),
            child: Column(
              children: _savedAddresses.map((address) {
                final bool selected = address.id == _selectedAddressId;

                return InkWell(
                  onTap: () {
                    _selectSavedAddress(address);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFF1F8ED)
                          : Colors.white,
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFEDEDED)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          address.isDefault
                              ? Icons.home_outlined
                              : Icons.location_on_outlined,
                          color: green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    address.addressLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (address.isDefault)
                                    Container(
                                      margin: const EdgeInsets.only(left: 7),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: green,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              if (address.fullName.isNotEmpty)
                                Text(
                                  address.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (address.phone.isNotEmpty)
                                Text(
                                  address.phone,
                                  style: const TextStyle(
                                    color: grey,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                address.addressLine1,
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (address.addressLine2.isNotEmpty)
                                Text(
                                  address.addressLine2,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              Text(
                                '${address.city}'
                                '${address.state.isNotEmpty ? ', ${address.state}' : ''}'
                                '${address.pincode.isNotEmpty ? ' - ${address.pincode}' : ''}',
                                style: const TextStyle(
                                  color: grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: green),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // =================================================
              // PERSONAL DETAILS
              // =================================================

              _sectionTitle('Personal Details'),
              const SizedBox(height: 12),

              _field(
                label: 'Name',
                icon: Icons.person_outline,
                controller: _nameController,
                validator: _validateName,
              ),

              _field(
                label: 'Mobile Number',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),

              _field(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),

              const SizedBox(height: 8),

              // =================================================
              // DELIVERY ADDRESS
              // =================================================

              _sectionTitle('Delivery Address'),
              const SizedBox(height: 12),

              _buildSavedAddressSection(),

              if (_addressError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _addressError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 14),

              // =================================================
              // CURRENT LOCATION
              // =================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _gettingLocation ? null : _getCurrentLocation,
                  icon: _gettingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: green,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _gettingLocation
                        ? 'Getting location...'
                        : 'Use Current Location',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 15, color: green),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Location: '
                        '${_latitude!.toStringAsFixed(5)}, '
                        '${_longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 11, color: grey),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // =================================================
              // ADDRESS
              // =================================================

              _field(
                label: 'House Number / Address',
                icon: Icons.home_outlined,
                controller: _addressController,
                validator: _validateAddress,
                maxLines: 3,
              ),

              // =================================================
              // ADDRESS LINE 2
              // =================================================

              _field(
                label: 'Apartment / Landmark (Optional)',
                icon: Icons.apartment_outlined,
                controller: _addressLine2Controller,
                validator: (_) => null,
              ),

              // =================================================
              // CITY
              // =================================================

              _field(
                label: 'City',
                icon: Icons.location_city_outlined,
                controller: _cityController,
                validator: _validateCity,
              ),

              // =================================================
              // STATE
              // =================================================

              _field(
                label: 'State',
                icon: Icons.map_outlined,
                controller: _stateController,
                validator: (_) => null,
              ),

              // =================================================
              // PINCODE
              // =================================================

              _field(
                label: 'Pincode',
                icon: Icons.pin_drop_outlined,
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                validator: _validatePincode,
              ),

              const SizedBox(height: 8),

              // =================================================
              // DELIVERY SCHEDULE (READ-ONLY — LIVE CURRENT TIME)
              // =================================================

              _sectionTitle('Delivery Schedule'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8DF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: green),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Date',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDisplayDate(_now),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: green),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: green,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // DELIVERY TIME (LIVE — YOUR CURRENT BOOKING TIME)
              // =================================================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8DF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_outlined, color: green),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Booking Time',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDisplayTime(_now),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PAYMENT
              // =================================================

              _sectionTitle('Payment Method'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments_outlined, color: green),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash on Delivery',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Pay when your order arrives',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: green),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // CART TOTAL
              // =================================================

              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Column(
                    children: [
                      _priceRow('Subtotal', cart.subtotal),
                      const SizedBox(height: 8),
                      _priceRow('Delivery Fee', cart.deliveryFee),
                      const Divider(height: 24),
                      _priceRow('Total', cart.total, bold: true),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // =================================================
              // PLACE ORDER
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _placingOrder ? null : _placeOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _placingOrder
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SAVED ADDRESS MODEL
// =============================================================

class SavedAddress {
  final String id;
  final String addressLabel;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const SavedAddress({
    required this.id,
    required this.addressLabel,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id']?.toString() ??
          json['address_id']?.toString() ??
          json['addressId']?.toString() ??
          '',
      addressLabel: json['address_label']?.toString() ??
          json['addressLabel']?.toString() ??
          json['label']?.toString() ??
          'Home',
      fullName: json['full_name']?.toString() ??
          json['fullName']?.toString() ??
          json['name']?.toString() ??
          '',
      phone: json['phone']?.toString() ??
          json['mobile']?.toString() ??
          json['mobileNumber']?.toString() ??
          '',
      addressLine1: json['address_line1']?.toString() ??
          json['addressLine1']?.toString() ??
          json['address']?.toString() ??
          '',
      addressLine2: json['address_line2']?.toString() ??
          json['addressLine2']?.toString() ??
          '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ??
          json['pinCode']?.toString() ??
          json['postalCode']?.toString() ??
          '',
      isDefault: json['is_default'] == true ||
          json['isDefault'] == true ||
          json['default'] == true,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  // =========================================================
  // PARSE DOUBLE
  // =========================================================

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}