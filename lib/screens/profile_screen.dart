import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color green = Color(0xFF65B83D);
  static const Color dark = Color(0xFF252525);
  static const Color grey = Color(0xFF777777);
  static const Color background = Color(0xFFF7F7F7);
  static const Color lightGreen = Color(0xFFF0F9EB);
  static const Color border = Color(0xFFE5E5E5);

  // ============================================================
  // SUPPORT
  // ============================================================

  static const String supportEmail =
      'support@frutgo.com';

  static const String supportPhone =
      '+919629974228';

  static const String supportWhatsApp =
      '919629974228';

  // ============================================================
  // STATE
  // ============================================================

  Map<String, dynamic> user = {};

  List<Map<String, dynamic>> addresses = [];

  List<Map<String, dynamic>> orders = [];

  bool loading = true;
  bool refreshing = false;
  bool saving = false;
  bool loadingAddresses = false;
  bool loadingOrders = false;
  bool gettingLocation = false;

  DateTime? serverTime;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressLabelController =
      TextEditingController();

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController addressLine1Controller =
      TextEditingController();

  final TextEditingController addressLine2Controller =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController stateController =
      TextEditingController();

  final TextEditingController pincodeController =
      TextEditingController();

  double? selectedLatitude;
  double? selectedLongitude;

  int? editingAddressId;

  // ============================================================
  // API BASE URL
  // ============================================================

  String get baseUrl {
    return Env.apiBaseUrl;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadEverything();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    addressLabelController.dispose();
    fullNameController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('userToken');

    if (token == null ||
        token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  // ============================================================
  // USER HEADERS
  // ============================================================

  Future<Map<String, String>> userHeaders() async {
    final token = await getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] =
          'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> loadEverything() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      await fetchUser();
      await fetchAddresses();
      await fetchOrders();
    } catch (e) {
      debugPrint(
        'LOAD PROFILE ERROR: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshProfile() async {
    if (refreshing) {
      return;
    }

    if (mounted) {
      setState(() {
        refreshing = true;
      });
    }

    try {
      await fetchUser();
      await fetchAddresses();
      await fetchOrders();
    } catch (e) {
      debugPrint(
        'REFRESH ERROR: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      refreshing = false;
    });

    showMessage(
      'Profile refreshed',
    );
  }

  // ============================================================
  // FETCH USER
  // ============================================================

  Future<void> fetchUser() async {
    final headers =
        await userHeaders();

    if (!headers.containsKey(
      'Authorization',
    )) {
      showMessage(
        'Please login again.',
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/auth/me',
        ),
        headers: headers,
      );

      debugPrint(
        'USER STATUS: ${response.statusCode}',
      );

      debugPrint(
        'USER RESPONSE: ${response.body}',
      );

      if (response.statusCode == 401) {
        showMessage(
          'Session expired. Please login again.',
        );
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        showMessage(
          'Unable to load profile.',
        );
        return;
      }

      final decoded =
          jsonDecode(response.body);

      Map<String, dynamic> result = {};

      if (decoded is Map &&
          decoded['user'] is Map) {
        result =
            Map<String, dynamic>.from(
          decoded['user'],
        );
      } else if (decoded is Map) {
        result =
            Map<String, dynamic>.from(
          decoded,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        user = result;

        nameController.text =
            valueOf(
          result,
          [
            'name',
          ],
        );

        emailController.text =
            valueOf(
          result,
          [
            'email',
          ],
        );

        phoneController.text =
            valueOf(
          result,
          [
            'phone',
            'mobile',
          ],
        );
      });
    } catch (e) {
      debugPrint(
        'FETCH USER ERROR: $e',
      );
    }
  }

  // ============================================================
  // FETCH ADDRESSES
  // ============================================================

  Future<void> fetchAddresses() async {
    if (mounted) {
      setState(() {
        loadingAddresses = true;
      });
    }

    try {
      final headers =
          await userHeaders();

      if (!headers.containsKey(
        'Authorization',
      )) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/addresses',
        ),
        headers: headers,
      );

      debugPrint(
        'ADDRESS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'ADDRESS RESPONSE: ${response.body}',
      );

      if (response.statusCode == 401) {
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return;
      }

      final decoded =
          jsonDecode(response.body);

      List<Map<String, dynamic>> result =
          [];

      if (decoded is Map &&
          decoded['addresses'] is List) {
        result =
            (decoded['addresses'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList();
      } else if (decoded is List) {
        result =
            decoded
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        addresses = result;
      });
    } catch (e) {
      debugPrint(
        'FETCH ADDRESSES ERROR: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loadingAddresses = false;
    });
  }

  // ============================================================
  // FETCH ORDERS
  // ============================================================

  Future<void> fetchOrders() async {
    if (mounted) {
      setState(() {
        loadingOrders = true;
      });
    }

    try {
      final headers =
          await userHeaders();

      if (!headers.containsKey(
        'Authorization',
      )) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/orders',
        ),
        headers: headers,
      );

      debugPrint(
        'ORDERS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'ORDERS RESPONSE: ${response.body}',
      );

      if (response.statusCode == 401) {
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return;
      }

      final decoded =
          jsonDecode(response.body);

      List<Map<String, dynamic>> result =
          [];

      if (decoded is Map) {
        if (decoded['serverTime'] != null) {
          try {
            serverTime = DateTime.parse(
              decoded['serverTime'].toString(),
            );
          } catch (_) {}
        }

        if (decoded['orders'] is List) {
          result =
              (decoded['orders'] as List)
                  .whereType<Map>()
                  .map(
                    (item) =>
                        Map<String, dynamic>.from(
                      item,
                    ),
                  )
                  .toList();
        } else if (decoded['data'] is List) {
          result =
              (decoded['data'] as List)
                  .whereType<Map>()
                  .map(
                    (item) =>
                        Map<String, dynamic>.from(
                      item,
                    ),
                  )
                  .toList();
        }
      } else if (decoded is List) {
        result =
            decoded
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        orders = result;
      });
    } catch (e) {
      debugPrint(
        'FETCH ORDERS ERROR: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loadingOrders = false;
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String valueOf(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: buildAppBar(),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: green,
              ),
            )
          : RefreshIndicator(
              color: green,
              onRefresh: refreshProfile,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  35,
                ),
                children: [
                  buildProfileCard(),

                  const SizedBox(height: 16),

                  buildAddressSection(),

                  const SizedBox(height: 20),

                  buildOrdersSection(),

                  const SizedBox(height: 20),

                  buildSupportSection(),

                  const SizedBox(height: 20),

                  buildLogoutButton(),
                ],
              ),
            ),
      bottomNavigationBar:
          const FrutgoBottomNavigation(
        currentIndex: 3,
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: dark,
          size: 20,
        ),
      ),
      title: const Text(
        'MY ACCOUNT',
        style: TextStyle(
          color: dark,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed:
              refreshing ? null : refreshProfile,
          icon: refreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: dark,
                ),
        ),
        IconButton(
          tooltip: 'Menu',
          onPressed: openMoreMenu,
          icon: const Icon(
            Icons.more_vert_rounded,
            color: dark,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget buildProfileCard() {
    final name =
        valueOf(
          user,
          ['name'],
        ).isEmpty
            ? 'User'
            : valueOf(
                user,
                ['name'],
              );

    final email =
        valueOf(
          user,
          ['email'],
        );

    final phone =
        valueOf(
          user,
          ['phone', 'mobile'],
        );

    final avatar =
        valueOf(
          user,
          ['avatar', 'picture'],
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.person_rounded,
                          color: green,
                          size: 42,
                        );
                      },
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: green,
                      size: 42,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: dark,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    phone,
                    style:
                        const TextStyle(
                      color: grey,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed:
                openProfileEditor,
            icon: const Icon(
              Icons.edit_outlined,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS SECTION
  // ============================================================

  Widget buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: green,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'MANAGE ADDRESSES',
                  style: TextStyle(
                    color: dark,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed:
                    openNewAddressEditor,
                icon: const Icon(
                  Icons.add_rounded,
                  color: green,
                  size: 18,
                ),
                label: const Text(
                  'ADD NEW',
                  style: TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (loadingAddresses)
            const Padding(
              padding:
                  EdgeInsets.all(20),
              child: Center(
                child:
                    CircularProgressIndicator(
                  color: green,
                ),
              ),
            )
          else if (addresses.isEmpty)
            buildNoAddress()
          else
            Column(
              children: addresses
                  .map(
                    buildAddressCard,
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NO ADDRESS
  // ============================================================

  Widget buildNoAddress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: grey,
            size: 38,
          ),
          const SizedBox(height: 8),
          const Text(
            'No saved address',
            style: TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add an address for faster checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                openNewAddressEditor,
            style:
                ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor:
                  Colors.white,
              elevation: 0,
            ),
            icon: const Icon(
              Icons.add,
              size: 18,
            ),
            label: const Text(
              'ADD ADDRESS',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget buildAddressCard(
    Map<String, dynamic> address,
  ) {
    final id =
        int.tryParse(
      '${address['id']}',
    );

    final label =
        valueOf(
          address,
          [
            'address_label',
            'addressLabel',
          ],
        );

    final fullName =
        valueOf(
          address,
          ['full_name', 'fullName'],
        );

    final phone =
        valueOf(
          address,
          ['phone'],
        );

    final line1 =
        valueOf(
          address,
          [
            'address_line1',
            'addressLine1',
          ],
        );

    final line2 =
        valueOf(
          address,
          [
            'address_line2',
            'addressLine2',
          ],
        );

    final city =
        valueOf(
          address,
          ['city'],
        );

    final state =
        valueOf(
          address,
          ['state'],
        );

    final pincode =
        valueOf(
          address,
          ['pincode'],
        );

    final isDefault =
        address['is_default'] == true ||
            address['is_default'] == 1 ||
            address['isDefault'] == true;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: isDefault
            ? lightGreen
            : background,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? green
              : border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color: isDefault
                      ? green
                      : Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  label.isEmpty
                      ? 'Home'
                      : label,
                  style: TextStyle(
                    color: isDefault
                        ? Colors.white
                        : dark,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style:
                        TextStyle(
                      color: green,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

              const Spacer(),

              if (id != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: grey,
                  ),
                  onSelected:
                      (value) {
                    if (value ==
                        'edit') {
                      openEditAddressEditor(
                        address,
                      );
                    } else if (value ==
                        'delete') {
                      confirmDeleteAddress(
                        id,
                      );
                    } else if (value ==
                        'default') {
                      setDefaultAddress(
                        id,
                      );
                    }
                  },
                  itemBuilder:
                      (context) {
                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit address',
                        ),
                      ),
                      if (!isDefault)
                        const PopupMenuItem(
                          value:
                              'default',
                          child: Text(
                            'Make default',
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete address',
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (fullName.isNotEmpty)
            Text(
              fullName,
              style:
                  const TextStyle(
                color: dark,
                fontSize: 14,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

          if (phone.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 3,
              ),
              child: Text(
                phone,
                style:
                    const TextStyle(
                  color: grey,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 7),

          if (line1.isNotEmpty)
            Text(
              line1,
              style:
                  const TextStyle(
                color: dark,
                fontSize: 13,
                height: 1.4,
              ),
            ),

          if (line2.isNotEmpty)
            Text(
              line2,
              style:
                  const TextStyle(
                color: grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),

          if (city.isNotEmpty ||
              state.isNotEmpty ||
              pincode.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 3,
              ),
              child: Text(
                [
                  if (city.isNotEmpty)
                    city,
                  if (state.isNotEmpty)
                    state,
                  if (pincode.isNotEmpty)
                    pincode,
                ].join(', '),
                style:
                    const TextStyle(
                  color: grey,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 10),

          Row(
            children: [
              if (!isDefault &&
                  id != null)
                TextButton(
                  onPressed:
                      () {
                    setDefaultAddress(
                      id,
                    );
                  },
                  child:
                      const Text(
                    'MAKE DEFAULT',
                    style:
                        TextStyle(
                      color: green,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

              const Spacer(),

              if (id != null)
                TextButton.icon(
                  onPressed:
                      () {
                    openEditAddressEditor(
                      address,
                    );
                  },
                  icon:
                      const Icon(
                    Icons.edit_outlined,
                    color: green,
                    size: 16,
                  ),
                  label:
                      const Text(
                    'EDIT',
                    style:
                        TextStyle(
                      color: green,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS EDITOR
  // ============================================================

  void openNewAddressEditor() {
    clearAddressControllers();

    editingAddressId = null;

    openAddressSheet(
      title: 'Add New Address',
      subtitle:
          'Save a delivery address',
    );
  }

  void openEditAddressEditor(
    Map<String, dynamic> address,
  ) {
    editingAddressId =
        int.tryParse(
      '${address['id']}',
    );

    addressLabelController.text =
        valueOf(
      address,
      [
        'address_label',
        'addressLabel',
      ],
    );

    fullNameController.text =
        valueOf(
      address,
      [
        'full_name',
        'fullName',
      ],
    );

    phoneController.text =
        valueOf(
      address,
      ['phone'],
    );

    addressLine1Controller.text =
        valueOf(
      address,
      [
        'address_line1',
        'addressLine1',
      ],
    );

    addressLine2Controller.text =
        valueOf(
      address,
      [
        'address_line2',
        'addressLine2',
      ],
    );

    cityController.text =
        valueOf(
      address,
      ['city'],
    );

    stateController.text =
        valueOf(
      address,
      ['state'],
    );

    pincodeController.text =
        valueOf(
      address,
      ['pincode'],
    );

    selectedLatitude =
        double.tryParse(
      valueOf(
        address,
        ['latitude'],
      ),
    );

    selectedLongitude =
        double.tryParse(
      valueOf(
        address,
        ['longitude'],
      ),
    );

    openAddressSheet(
      title: 'Edit Address',
      subtitle:
          'Update your delivery address',
    );
  }

  // ============================================================
  // CLEAR ADDRESS
  // ============================================================

  void clearAddressControllers() {
    addressLabelController.clear();
    fullNameController.clear();
    phoneController.clear();
    addressLine1Controller.clear();
    addressLine2Controller.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();

    selectedLatitude = null;
    selectedLongitude = null;
  }

  // ============================================================
  // ADDRESS SHEET
  // ============================================================

  void openAddressSheet({
    required String title,
    required String subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(
              sheetContext,
            ).viewInsets.bottom,
          ),
          child: Container(
            height:
                MediaQuery.of(
                      sheetContext,
                    ).size.height *
                    .90,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                drawerHandle(),

                drawerHeader(
                  title,
                  subtitle,
                  () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                const Divider(
                  height: 1,
                ),

                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      children: [
                        currentLocationButton(),

                        const SizedBox(
                          height: 18,
                        ),

                        buildInput(
                          addressLabelController,
                          'Address Label',
                          Icons.label_outline,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          fullNameController,
                          'Full Name',
                          Icons.person_outline,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          phoneController,
                          'Phone Number',
                          Icons.phone_outlined,
                          keyboard:
                              TextInputType.phone,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          addressLine1Controller,
                          'Address Line 1',
                          Icons.home_outlined,
                          maxLines: 2,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          addressLine2Controller,
                          'Address Line 2',
                          Icons.location_on_outlined,
                          maxLines: 2,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          cityController,
                          'City',
                          Icons.location_city_outlined,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          stateController,
                          'State',
                          Icons.map_outlined,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        buildInput(
                          pincodeController,
                          'Pincode',
                          Icons.pin_drop_outlined,
                          keyboard:
                              TextInputType.number,
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        saveButton(
                          editingAddressId ==
                                  null
                              ? 'SAVE ADDRESS'
                              : 'UPDATE ADDRESS',
                          () async {
                            final success =
                                await saveAddress();

                            if (!mounted) {
                              return;
                            }

                            if (success &&
                                sheetContext
                                    .mounted) {
                              Navigator.pop(
                                sheetContext,
                              );
                            }
                          },
                        ),

                        const SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CURRENT LOCATION BUTTON
  // ============================================================

  Widget currentLocationButton() {
    return InkWell(
      onTap:
          gettingLocation
              ? null
              : getCurrentLocation,
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color: lightGreen,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                green.withValues(
              alpha: .25,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: gettingLocation
                  ? const Padding(
                      padding:
                          EdgeInsets.all(
                        11,
                      ),
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: green,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: green,
                    ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Use Current Location',
                    style:
                        TextStyle(
                      color: dark,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Get your current GPS location',
                    style:
                        TextStyle(
                      color: grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: green,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> getCurrentLocation() async {
    if (mounted) {
      setState(() {
        gettingLocation = true;
      });
    }

    try {
      final enabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!enabled) {
        showMessage(
          'Please enable location services.',
        );
        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        showMessage(
          'Location permission is required.',
        );
        return;
      }

      final position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      selectedLatitude =
          position.latitude;

      selectedLongitude =
          position.longitude;

      addressLine1Controller.text =
          'Current location '
          '(${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)})';

      showMessage(
        'Current location added.',
      );
    } catch (e) {
      debugPrint(
        'LOCATION ERROR: $e',
      );

      showMessage(
        'Unable to get current location.',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      gettingLocation = false;
    });
  }

  // ============================================================
  // VALIDATE ADDRESS
  // ============================================================

  String? validateAddress() {
    if (fullNameController.text.trim().isEmpty) {
      return 'Full name is required';
    }

    final phone =
        phoneController.text.trim();

    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(
      r'^[6-9]\d{9}$',
    ).hasMatch(phone)) {
      return 'Enter a valid 10-digit phone number';
    }

    if (addressLine1Controller.text
        .trim()
        .isEmpty) {
      return 'Address is required';
    }

    if (cityController.text
        .trim()
        .isEmpty) {
      return 'City is required';
    }

    if (stateController.text
        .trim()
        .isEmpty) {
      return 'State is required';
    }

    final pin =
        pincodeController.text.trim();

    if (!RegExp(
      r'^\d{6}$',
    ).hasMatch(pin)) {
      return 'Enter a valid 6-digit pincode';
    }

    return null;
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<bool> saveAddress() async {
    final validation =
        validateAddress();

    if (validation != null) {
      showMessage(validation);
      return false;
    }

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    bool success = false;

    try {
      final headers =
          await userHeaders();

      if (!headers.containsKey(
        'Authorization',
      )) {
        showMessage(
          'Please login again.',
        );
        return false;
      }

      final existing =
          addresses.isEmpty;

      final payload =
          <String, dynamic>{
        'addressLabel':
            addressLabelController.text
                    .trim()
                    .isEmpty
                ? 'Home'
                : addressLabelController
                    .text
                    .trim(),

        'fullName':
            fullNameController.text
                .trim(),

        'phone':
            phoneController.text
                .trim(),

        'addressLine1':
            addressLine1Controller
                .text
                .trim(),

        'addressLine2':
            addressLine2Controller
                .text
                .trim(),

        'city':
            cityController.text
                .trim(),

        'state':
            stateController.text
                .trim(),

        'pincode':
            pincodeController.text
                .trim(),

        'latitude':
            selectedLatitude,

        'longitude':
            selectedLongitude,

        'isDefault':
            existing,
      };

      late http.Response response;

      if (editingAddressId == null) {
        response =
            await http.post(
          Uri.parse(
            '$baseUrl/addresses',
          ),
          headers: headers,
          body:
              jsonEncode(payload),
        );
      } else {
        response =
            await http.put(
          Uri.parse(
            '$baseUrl/addresses/$editingAddressId',
          ),
          headers: headers,
          body:
              jsonEncode(payload),
        );
      }

      debugPrint(
        'SAVE ADDRESS STATUS: ${response.statusCode}',
      );

      debugPrint(
        'SAVE ADDRESS RESPONSE: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        success = true;

        await fetchAddresses();

        showMessage(
          editingAddressId == null
              ? 'Address added successfully.'
              : 'Address updated successfully.',
        );
      } else {
        showMessage(
          getErrorMessage(
            response,
            'Unable to save address.',
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'SAVE ADDRESS ERROR: $e',
      );

      showMessage(
        'Unable to save address.',
      );
    }

    if (!mounted) {
      return success;
    }

    setState(() {
      saving = false;
    });

    return success;
  }

  // ============================================================
  // DELETE ADDRESS CONFIRMATION
  // ============================================================

  Future<void> confirmDeleteAddress(
    int id,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Address?',
          ),
          content:
              const Text(
            'This saved address will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteAddress(id);
    }
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  Future<void> deleteAddress(
    int id,
  ) async {
    try {
      final headers =
          await userHeaders();

      final response =
          await http.delete(
        Uri.parse(
          '$baseUrl/addresses/$id',
        ),
        headers: headers,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        await fetchAddresses();

        showMessage(
          'Address deleted.',
        );
      } else {
        showMessage(
          getErrorMessage(
            response,
            'Unable to delete address.',
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'DELETE ADDRESS ERROR: $e',
      );

      showMessage(
        'Unable to delete address.',
      );
    }
  }

  // ============================================================
  // SET DEFAULT ADDRESS
  // ============================================================

  Future<void> setDefaultAddress(
    int id,
  ) async {
    try {
      final headers =
          await userHeaders();

      final response =
          await http.patch(
        Uri.parse(
          '$baseUrl/addresses/$id/default',
        ),
        headers: headers,
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        await fetchAddresses();

        showMessage(
          'Default address updated.',
        );
      } else {
        showMessage(
          getErrorMessage(
            response,
            'Unable to set default address.',
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'DEFAULT ADDRESS ERROR: $e',
      );

      showMessage(
        'Unable to set default address.',
      );
    }
  }

  // ============================================================
  // PROFILE EDITOR
  // ============================================================

  void openProfileEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(
              sheetContext,
            ).viewInsets.bottom,
          ),
          child: Container(
            height:
                MediaQuery.of(
                      sheetContext,
                    ).size.height *
                    .68,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                drawerHandle(),
                drawerHeader(
                  'Edit Profile',
                  'Update your account details',
                  () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),
                const Divider(
                  height: 1,
                ),
                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      children: [
                        buildInput(
                          nameController,
                          'Name',
                          Icons.person_outline,
                        ),
                        const SizedBox(
                          height: 13,
                        ),
                        buildInput(
                          phoneController,
                          'Phone Number',
                          Icons.phone_outlined,
                          keyboard:
                              TextInputType.phone,
                        ),
                        const SizedBox(
                          height: 13,
                        ),
                        buildInput(
                          emailController,
                          'Email',
                          Icons.email_outlined,
                          keyboard:
                              TextInputType.emailAddress,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        saveButton(
                          'SAVE CHANGES',
                          () async {
                            final success =
                                await saveProfile();

                            if (success &&
                                sheetContext
                                    .mounted) {
                              Navigator.pop(
                                sheetContext,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<bool> saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      showMessage(
        'Name is required.',
      );
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage(
        'Phone number is required.',
      );
      return false;
    }

    if (!RegExp(
      r'^[6-9]\d{9}$',
    ).hasMatch(
      phoneController.text.trim(),
    )) {
      showMessage(
        'Enter a valid 10-digit phone number.',
      );
      return false;
    }

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    bool success = false;

    try {
      final headers =
          await userHeaders();

            final response =
          await http.put(
        Uri.parse(
          '$baseUrl/users/auth/phone',
        ),
        headers: headers,
        body: jsonEncode({
          'name':
              nameController.text.trim(),
          'phone':
              phoneController.text.trim(),
        }),
      );

      debugPrint(
        'PROFILE UPDATE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'PROFILE UPDATE RESPONSE: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        success = true;

        await fetchUser();

        showMessage(
          'Profile updated successfully.',
        );
      } else if (response.statusCode == 404) {
        showMessage(
          'Profile update route is not available on the server.',
        );
      } else {
        showMessage(
          getErrorMessage(
            response,
            'Unable to update profile.',
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'SAVE PROFILE ERROR: $e',
      );

      showMessage(
        'Unable to update profile.',
      );
    }

    if (!mounted) {
      return success;
    }

    setState(() {
      saving = false;
    });

    return success;
  }

  // ============================================================
  // ORDERS SECTION
  // ============================================================

  Widget buildOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MY ORDERS',
                  style: TextStyle(
                    color: dark,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              if (orders.isNotEmpty)
                TextButton(
                  onPressed:
                      openAllOrders,
                  child:
                      const Text(
                    'VIEW ALL',
                    style:
                        TextStyle(
                      color: green,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          if (loadingOrders)
            const Padding(
              padding:
                  EdgeInsets.all(25),
              child: Center(
                child:
                    CircularProgressIndicator(
                  color: green,
                ),
              ),
            )
          else if (orders.isEmpty)
            buildNoOrders()
          else
            Column(
              children:
                  orders
                      .take(3)
                      .map(
                        buildOrderCard,
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NO ORDERS
  // ============================================================

  Widget buildNoOrders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: green,
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            'No orders yet',
            style: TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget buildOrderCard(
    Map<String, dynamic> order,
  ) {
    final items =
        order['items'] is List
            ? (order['items'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList()
            : <Map<String, dynamic>>[];

    final total =
        order['total'] ?? 0;

    final status =
        valueOf(
          order,
          ['status'],
        );

    final orderId =
        valueOf(
          order,
          ['id'],
        );

    final item =
        items.isNotEmpty
            ? items.first
            : <String, dynamic>{};

    final image =
        valueOf(
          item,
          ['image'],
        );

    final name =
        valueOf(
          item,
          ['name'],
        ).isEmpty
            ? 'Order'
            : valueOf(
                item,
                ['name'],
              );

    final expected =
        parseDate(
      order['expected_delivery_at'],
    );

    final booked =
        parseDate(
      order['booked_at'],
    );

    final isActive =
        status.toLowerCase() !=
                'delivered' &&
            status.toLowerCase() !=
                'completed' &&
            status.toLowerCase() !=
                'cancelled' &&
            status.toLowerCase() !=
                'canceled';

    return InkWell(
      onTap: () {
        openOrderDetails(
          order,
        );
      },
      borderRadius:
          BorderRadius.circular(17),
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color: background,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          border:
              Border.all(color: border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration:
                      BoxDecoration(
                    color:
                        lightGreen,
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                  child:
                      ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                    child:
                        image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons
                                        .shopping_bag_outlined,
                                    color:
                                        green,
                                  );
                                },
                              )
                            : const Icon(
                                Icons
                                    .shopping_bag_outlined,
                                color:
                                    green,
                              ),
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              dark,
                          fontSize:
                              14,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Order #$orderId',
                        style:
                            const TextStyle(
                          color:
                              grey,
                          fontSize:
                              11,
                        ),
                      ),
                      if (items.length >
                          1)
                        Text(
                          '+ ${items.length - 1} more item(s)',
                          style:
                              const TextStyle(
                            color:
                                grey,
                            fontSize:
                                10,
                          ),
                        ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .end,
                  children: [
                    Text(
                      '₹$total',
                      style:
                          const TextStyle(
                        color:
                            dark,
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    statusBadge(
                      status,
                    ),
                  ],
                ),
              ],
            ),

            if (isActive &&
                expected != null) ...[
              const SizedBox(
                height: 12,
              ),
              DeliveryCountdown(
                expectedDelivery:
                    expected,
                serverTime:
                    serverTime,
              ),
            ] else if (booked != null &&
                status.isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: grey,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Booked ${formatDateTime(booked)}',
                    style:
                        const TextStyle(
                      color:
                          grey,
                      fontSize:
                          10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget statusBadge(
    String status,
  ) {
    final value =
        status.toLowerCase();

    Color badgeColor = green;
    Color badgeBackground =
        lightGreen;

    if (value ==
            'cancelled' ||
        value ==
            'canceled') {
      badgeColor =
          Colors.red;
      badgeBackground =
          const Color(
        0xFFFFEEEE,
      );
    } else if (value !=
            'delivered' &&
        value !=
            'completed') {
      badgeColor =
          Colors.orange.shade800;
      badgeBackground =
          const Color(
        0xFFFFF3DF,
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            badgeBackground,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status.isEmpty
            ? 'PENDING'
            : status.toUpperCase(),
        style:
            TextStyle(
          color:
              badgeColor,
          fontSize: 8,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // ALL ORDERS
  // ============================================================

  void openAllOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AllOrdersScreen(
          orders: orders,
          serverTime:
              serverTime,
        ),
      ),
    );
  }

  // ============================================================
  // ORDER DETAILS
  // ============================================================

  void openOrderDetails(
    Map<String, dynamic> order,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) {
        return OrderDetailsSheet(
          order: order,
          serverTime:
              serverTime,
        );
      },
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  Widget buildSupportSection() {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(color: border),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: green,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'NEED HELP?',
                style:
                    TextStyle(
                  color:
                      dark,
                  fontSize:
                      14,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child:
                    supportButton(
                  Icons
                      .help_outline_rounded,
                  'Help Center',
                  openHelpCenter,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    supportButton(
                  Icons
                      .headset_mic_outlined,
                  'Contact Support',
                  contactSupport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget supportButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration:
            BoxDecoration(
          color: background,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border:
              Border.all(color: border),
        ),
        child:
            Column(
          children: [
            Icon(
              icon,
              color: green,
              size: 22,
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              label,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: dark,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELP CENTER
  // ============================================================

  void openHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder:
          (sheetContext) {
        return Container(
          height:
              MediaQuery.of(
                    sheetContext,
                  ).size.height *
                  .78,
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(
                28,
              ),
            ),
          ),
          child:
              Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              drawerHandle(),
              drawerHeader(
                'Help Center',
                'Frequently asked questions',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                },
              ),
              const Divider(
                height: 1,
              ),
              Expanded(
                child:
                    ListView(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 8,
                  ),
                  children: [
                    faqItem(
                      'How do I track my order?',
                      'Open My Account and tap your order. '
                          'The delivery countdown appears when an expected '
                          'delivery time is available.',
                    ),
                    divider(),
                    faqItem(
                      'How do I add an address?',
                      'Open Manage Addresses and tap ADD NEW. '
                          'You can also use your current GPS location.',
                    ),
                    divider(),
                    faqItem(
                      'How do I change my default address?',
                      'Open Manage Addresses and select MAKE DEFAULT '
                          'on the address you want to use.',
                    ),
                    divider(),
                    faqItem(
                      'How do I cancel an order?',
                      'Open the order details and use the cancellation '
                          'option when the order is eligible.',
                    ),
                    divider(),
                    faqItem(
                      'What if my payment failed?',
                      'Please contact support if your account was charged '
                          'but the order was not created.',
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                      ),
                      child:
                          saveButton(
                        'CONTACT SUPPORT',
                        () {
                          Navigator.pop(
                            sheetContext,
                          );
                          contactSupport();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget faqItem(
    String question,
    String answer,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Text(
            question,
            style:
                const TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            answer,
            style:
                const TextStyle(
              color: grey,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACT SUPPORT
  // ============================================================

  void contactSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),
      ),
      builder:
          (sheetContext) {
        return SafeArea(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const SizedBox(
                height: 10,
              ),
              drawerHandle(),
              drawerHeader(
                'Contact Support',
                'We are here to help',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                },
              ),
              const Divider(
                height: 1,
              ),
              menuItem(
                Icons.email_outlined,
                'Email Support',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  launchSupportEmail();
                },
              ),
              divider(),
              menuItem(
                Icons.call_outlined,
                'Call Support',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  launchSupportPhone();
                },
              ),
              divider(),
              menuItem(
                Icons.chat_outlined,
                'WhatsApp Support',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  launchSupportWhatsApp();
                },
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> launchSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query:
          'subject=Frutgo Support Request',
    );

    try {
      final launched =
          await launchUrl(uri);

      if (!launched) {
        showMessage(
          'Unable to open email app.',
        );
      }
    } catch (e) {
      debugPrint(
        'EMAIL ERROR: $e',
      );
      showMessage(
        'Unable to open email app.',
      );
    }
  }

  Future<void> launchSupportPhone() async {
    final uri =
        Uri(
      scheme: 'tel',
      path: supportPhone,
    );

    try {
      final launched =
          await launchUrl(uri);

      if (!launched) {
        showMessage(
          'Unable to open phone app.',
        );
      }
    } catch (e) {
      debugPrint(
        'PHONE ERROR: $e',
      );
      showMessage(
        'Unable to open phone app.',
      );
    }
  }

  Future<void> launchSupportWhatsApp() async {
    final uri =
        Uri.parse(
      'https://wa.me/$supportWhatsApp',
    );

    try {
      final launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        showMessage(
          'Unable to open WhatsApp.',
        );
      }
    } catch (e) {
      debugPrint(
        'WHATSAPP ERROR: $e',
      );
      showMessage(
        'Unable to open WhatsApp.',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed:
            confirmLogout,
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              Colors.red,
          side:
              const BorderSide(
            color: Colors.red,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
        icon: const Icon(
          Icons.logout_rounded,
        ),
        label: const Text(
          'LOGOUT',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<void> confirmLogout() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Logout?',
          ),
          content:
              const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'CANCEL',
              ),
            ),
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'LOGOUT',
                style:
                    TextStyle(
                  color:
                      Colors.red,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await logout();
  }

  Future<void> logout() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      'userToken',
    );

    await prefs.remove(
      'token',
    );

    await prefs.remove(
      'user',
    );

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  // ============================================================
  // MORE MENU
  // ============================================================

  void openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),
      ),
      builder:
          (sheetContext) {
        return SafeArea(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const SizedBox(
                height: 10,
              ),
              drawerHandle(),
              const SizedBox(
                height: 8,
              ),
              menuItem(
                Icons.person_outline,
                'Edit Profile',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        openProfileEditor();
                      }
                    },
                  );
                },
              ),
              divider(),
              menuItem(
                Icons.location_on_outlined,
                'Manage Addresses',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        openNewAddressEditor();
                      }
                    },
                  );
                },
              ),
              divider(),
              menuItem(
                Icons.receipt_long_outlined,
                'View All Orders',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        openAllOrders();
                      }
                    },
                  );
                },
              ),
              divider(),
              menuItem(
                Icons.help_outline,
                'Help Center',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        openHelpCenter();
                      }
                    },
                  );
                },
              ),
              divider(),
              menuItem(
                Icons.logout_rounded,
                'Logout',
                () {
                  Navigator.pop(
                    sheetContext,
                  );
                  WidgetsBinding
                      .instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        confirmLogout();
                      }
                    },
                  );
                },
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style:
          const TextStyle(
        color: dark,
        fontSize: 14,
        fontWeight:
            FontWeight.w600,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(
          color: grey,
          fontSize: 13,
        ),
        prefixIcon:
            Icon(
          icon,
          color: green,
          size: 21,
        ),
        filled: true,
        fillColor:
            background,
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color: green,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget saveButton(
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child:
          ElevatedButton(
        onPressed:
            saving
                ? null
                : onPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              green,
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              green.withValues(
            alpha: .55,
          ),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
        child:
            saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      color:
                          Colors.white,
                      strokeWidth:
                          2,
                    ),
                  )
                : Text(
                    text,
                    style:
                        const TextStyle(
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
      ),
    );
  }

  Widget drawerHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFD4D4D4,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
    );
  }

  Widget drawerHeader(
    String title,
    String subtitle,
    VoidCallback close,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        15,
        10,
        13,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        dark,
                    fontSize:
                        21,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        grey,
                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: close,
            icon:
                const Icon(
              Icons.close_rounded,
              color: dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget menuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child:
          Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 20,
          vertical: 17,
        ),
        child:
            Row(
          children: [
            Icon(
              icon,
              color: green,
              size: 24,
            ),
            const SizedBox(
              width: 17,
            ),
            Expanded(
              child:
                  Text(
                title,
                style:
                    const TextStyle(
                  color:
                      dark,
                  fontSize:
                      14,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),
            const Icon(
              Icons
                  .chevron_right_rounded,
              color: grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget divider() {
    return const Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: border,
    );
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(
        text,
      ).toLocal();
    } catch (_) {
      return null;
    }
  }

  String formatDateTime(
    DateTime date,
  ) {
    final hour =
        date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        hour >= 12
            ? 'PM'
            : 'AM';

    final displayHour =
        hour == 0
            ? 12
            : hour > 12
                ? hour - 12
                : hour;

    return '$displayHour:$minute $period';
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String getErrorMessage(
    http.Response response,
    String fallback,
  ) {
    try {
      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is Map &&
          decoded['message'] != null) {
        return decoded['message']
            .toString();
      }
    } catch (_) {}

    return fallback;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              green,
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
  }
}

// ============================================================================
// DELIVERY COUNTDOWN
// ============================================================================

class DeliveryCountdown
    extends StatefulWidget {
  final DateTime expectedDelivery;
  final DateTime? serverTime;

  const DeliveryCountdown({
    super.key,
    required this.expectedDelivery,
    this.serverTime,
  });

  @override
  State<DeliveryCountdown> createState() =>
      _DeliveryCountdownState();
}

class _DeliveryCountdownState
    extends State<DeliveryCountdown> {
  Timer? _timer;

  Duration remaining =
      Duration.zero;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    updateCountdown();

    _timer =
        Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (_) {
        updateCountdown();
      },
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  void updateCountdown() {
    final now =
        correctedNow();

    final difference =
        widget.expectedDelivery
            .difference(
      now,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      remaining =
          difference.isNegative
              ? Duration.zero
              : difference;
    });
  }

  // ============================================================
  // SERVER CORRECTED TIME
  // ============================================================

  DateTime correctedNow() {
    final server =
        widget.serverTime;

    if (server == null) {
      return DateTime.now();
    }

    final localNow =
        DateTime.now();

    final offset =
        localNow.difference(
      server,
    );

    return localNow.subtract(
      offset,
    );
  }

  // ============================================================
  // UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(
    covariant DeliveryCountdown
        oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.expectedDelivery !=
            widget.expectedDelivery ||
        oldWidget.serverTime !=
            widget.serverTime) {
      updateCountdown();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;

    super.dispose();
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(
          2,
          '0',
        );
  }

  String formatExpectedTime() {
    final date =
        widget.expectedDelivery;

    final hour =
        date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        hour >= 12
            ? 'PM'
            : 'AM';

    final displayHour =
        hour == 0
            ? 12
            : hour > 12
                ? hour - 12
                : hour;

    return '$displayHour:$minute $period';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final seconds =
        remaining.inSeconds;

    final hours =
        seconds ~/ 3600;

    final minutes =
        (seconds % 3600) ~/ 60;

    final secs =
        seconds % 60;

    if (remaining <=
        Duration.zero) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(
          13,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.green.shade50,
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          border:
              Border.all(
            color:
                Colors.green.shade200,
          ),
        ),
        child:
            Row(
          children: [
            Icon(
              Icons
                  .check_circle_rounded,
              color:
                  Colors.green.shade700,
              size: 25,
            ),
            const SizedBox(
              width: 9,
            ),
            Expanded(
              child:
                  Text(
                'Expected delivery time reached',
                style:
                    TextStyle(
                  color:
                      Colors.green.shade800,
                  fontSize:
                      12,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        13,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        border:
            Border.all(
          color:
              Colors.orange.shade200,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .delivery_dining_rounded,
                color:
                    Colors.orange.shade800,
                size: 24,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child:
                    Text(
                  'Estimated delivery',
                  style:
                      TextStyle(
                    color:
                        Colors.orange.shade900,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ),
              Text(
                formatExpectedTime(),
                style:
                    TextStyle(
                  color:
                      Colors.orange.shade800,
                  fontSize:
                      11,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              countdownBox(
                twoDigits(
                  hours,
                ),
                'HRS',
              ),
              const SizedBox(
                width: 5,
              ),
              const Text(
                ':',
                style:
                    TextStyle(
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              countdownBox(
                twoDigits(
                  minutes,
                ),
                'MIN',
              ),
              const SizedBox(
                width: 5,
              ),
              const Text(
                ':',
                style:
                    TextStyle(
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              countdownBox(
                twoDigits(
                  secs,
                ),
                'SEC',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget countdownBox(
    String value,
    String label,
  ) {
    return Container(
      width: 55,
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        border:
            Border.all(
          color:
              Colors.orange.shade200,
        ),
      ),
      child:
          Column(
        children: [
          Text(
            value,
            style:
                const TextStyle(
              fontSize:
                  18,
              fontWeight:
                  FontWeight
                      .w800,
            ),
          ),
          const SizedBox(
            height: 1,
          ),
          Text(
            label,
            style:
                TextStyle(
              fontSize:
                  7,
              color:
                  Colors.grey.shade600,
              fontWeight:
                  FontWeight
                      .w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ALL ORDERS SCREEN
// ============================================================================

class AllOrdersScreen
    extends StatelessWidget {
  final List<Map<String, dynamic>>
      orders;

  final DateTime? serverTime;

  const AllOrdersScreen({
    super.key,
    required this.orders,
    this.serverTime,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          _ProfileScreenState
              .background,
      appBar:
          AppBar(
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.white,
        elevation:
            0,
        leading:
            IconButton(
          onPressed:
              () {
            Navigator.pop(
              context,
            );
          },
          icon:
              const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color:
                _ProfileScreenState
                    .dark,
            size:
                20,
          ),
        ),
        title:
            const Text(
          'MY ORDERS',
          style:
              TextStyle(
            color:
                _ProfileScreenState
                    .dark,
            fontSize:
                19,
            fontWeight:
                FontWeight
                    .w800,
          ),
        ),
      ),
      body:
          orders.isEmpty
              ? const Center(
                  child:
                      Text(
                    'No orders yet',
                    style:
                        TextStyle(
                      color:
                          _ProfileScreenState
                              .grey,
                    ),
                  ),
                )
              : ListView
                  .builder(
                  padding:
                      const EdgeInsets
                          .all(
                    16,
                  ),
                  itemCount:
                      orders.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    return FullOrderCard(
                      order:
                          orders[index],
                      serverTime:
                          serverTime,
                    );
                  },
                ),
    );
  }
}

// ============================================================================
// FULL ORDER CARD
// ============================================================================

class FullOrderCard
    extends StatelessWidget {
  final Map<String, dynamic>
      order;

  final DateTime? serverTime;

  const FullOrderCard({
    super.key,
    required this.order,
    this.serverTime,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final items =
        order['items'] is List
            ? (order['items']
                    as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList()
            : <Map<String, dynamic>>[];

    final firstItem =
        items.isNotEmpty
            ? items.first
            : <String, dynamic>{};

    final image =
        '${firstItem['image'] ?? ''}';

    final name =
        '${firstItem['name'] ?? 'Product'}';

    final variant =
        '${firstItem['variant'] ?? ''}';

    final total =
        order['total'] ?? 0;

    final status =
        '${order['status'] ?? 'pending'}';

    final id =
        '${order['id'] ?? '-'}';

    final expected =
        _parseDate(
      order['expected_delivery_at'],
    );

    final active =
        status.toLowerCase() !=
                'delivered' &&
            status.toLowerCase() !=
                'completed' &&
            status.toLowerCase() !=
                'cancelled' &&
            status.toLowerCase() !=
                'canceled';

    return InkWell(
      onTap:
          () {
        showModalBottomSheet(
          context:
              context,
          isScrollControlled:
              true,
          backgroundColor:
              Colors.transparent,
          builder:
              (_) {
            return OrderDetailsSheet(
              order:
                  order,
              serverTime:
                  serverTime,
            );
          },
        );
      },
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child:
          Container(
        margin:
            const EdgeInsets
                .only(
          bottom:
              14,
        ),
        padding:
            const EdgeInsets
                .all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border:
              Border.all(
            color:
                _ProfileScreenState
                    .border,
          ),
        ),
        child:
            Column(
          children: [
            Row(
              children: [
                Container(
                  width:
                      66,
                  height:
                      66,
                  decoration:
                      BoxDecoration(
                    color:
                        _ProfileScreenState
                            .lightGreen,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    child:
                        image.isNotEmpty
                            ? Image.network(
                                image,
                                fit:
                                    BoxFit.cover,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons
                                        .shopping_basket_outlined,
                                    color:
                                        _ProfileScreenState
                                            .green,
                                  );
                                },
                              )
                            : const Icon(
                                Icons
                                    .shopping_basket_outlined,
                                color:
                                    _ProfileScreenState
                                        .green,
                              ),
                  ),
                ),
                const SizedBox(
                  width:
                      12,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        name,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              _ProfileScreenState
                                  .dark,
                          fontSize:
                              15,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const SizedBox(
                        height:
                            4,
                      ),
                      Text(
                        'Order #$id',
                        style:
                            const TextStyle(
                          color:
                              _ProfileScreenState
                                  .grey,
                          fontSize:
                              11,
                        ),
                      ),
                      if (variant.isNotEmpty)
                        Text(
                          variant,
                          style:
                              const TextStyle(
                            color:
                                _ProfileScreenState
                                    .grey,
                            fontSize:
                                11,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .end,
                  children: [
                    Text(
                      '₹$total',
                      style:
                          const TextStyle(
                        color:
                            _ProfileScreenState
                                .dark,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    const SizedBox(
                      height:
                          6,
                    ),
                    Text(
                      status.toUpperCase(),
                      style:
                          const TextStyle(
                        color:
                            _ProfileScreenState
                                .green,
                        fontSize:
                            9,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (active &&
                expected != null) ...[
              const SizedBox(
                height:
                    12,
              ),
              DeliveryCountdown(
                expectedDelivery:
                    expected,
                serverTime:
                    serverTime,
              ),
            ],

            const SizedBox(
              height:
                  12,
            ),

            const Divider(
              height:
                  1,
            ),

            const SizedBox(
              height:
                  10,
            ),

            Row(
              children: [
                Text(
                  '${items.length} item(s)',
                  style:
                      const TextStyle(
                    color:
                        _ProfileScreenState
                            .grey,
                    fontSize:
                        11,
                  ),
                ),
                const Spacer(),
                const Text(
                  'VIEW DETAILS',
                  style:
                      TextStyle(
                    color:
                        _ProfileScreenState
                            .green,
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      _ProfileScreenState
                          .green,
                  size:
                      18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(
        value.toString(),
      ).toLocal();
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// ORDER DETAILS SHEET
// ============================================================================

class OrderDetailsSheet
    extends StatelessWidget {
  final Map<String, dynamic>
      order;

  final DateTime? serverTime;

  const OrderDetailsSheet({
    super.key,
    required this.order,
    this.serverTime,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final items =
        order['items'] is List
            ? (order['items']
                    as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item,
                  ),
                )
                .toList()
            : <Map<String, dynamic>>[];

    final expected =
        parseDate(
      order['expected_delivery_at'],
    );

    final status =
        '${order['status'] ?? 'pending'}';

    return Container(
      height:
          MediaQuery.of(
                context,
              ).size.height *
              .90,
      decoration:
          const BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),
      ),
      child:
          Column(
        children: [
          const SizedBox(
            height:
                10,
          ),
          Container(
            width:
                42,
            height:
                4,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFD4D4D4,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              14,
              10,
              12,
            ),
            child:
                Row(
              children: [
                Expanded(
                  child:
                      Text(
                    'Order #${order['id'] ?? '-'}',
                    style:
                        const TextStyle(
                      color:
                          _ProfileScreenState
                              .dark,
                      fontSize:
                          21,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      context,
                    );
                  },
                  icon:
                      const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height:
                1,
          ),
          Expanded(
            child:
                ListView(
              padding:
                  const EdgeInsets
                      .all(
                20,
              ),
              children: [
                if (expected != null &&
                    status.toLowerCase() !=
                        'cancelled' &&
                    status.toLowerCase() !=
                        'canceled' &&
                    status.toLowerCase() !=
                        'delivered' &&
                    status.toLowerCase() !=
                        'completed')
                  DeliveryCountdown(
                    expectedDelivery:
                        expected,
                    serverTime:
                        serverTime,
                  ),

                const SizedBox(
                  height:
                      16,
                ),

                detailRow(
                  'Status',
                  status,
                ),

                detailRow(
                  'Payment',
                  '${order['payment_method'] ?? 'COD'}',
                ),

                detailRow(
                  'Name',
                  '${order['name'] ?? ''}',
                ),

                detailRow(
                  'Phone',
                  '${order['mobile'] ?? ''}',
                ),

                detailRow(
                  'Email',
                  '${order['email'] ?? ''}',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                const Text(
                  'DELIVERY ADDRESS',
                  style:
                      TextStyle(
                    color:
                        _ProfileScreenState
                            .dark,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height:
                      8,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        _ProfileScreenState
                            .background,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      Text(
                    [
                      if (('${order['address'] ?? ''}')
                          .trim()
                          .isNotEmpty)
                        '${order['address']}',
                      if (('${order['address_line2'] ?? ''}')
                          .trim()
                          .isNotEmpty)
                        '${order['address_line2']}',
                      if (('${order['city'] ?? ''}')
                          .trim()
                          .isNotEmpty)
                        '${order['city']}',
                      if (('${order['state'] ?? ''}')
                          .trim()
                          .isNotEmpty)
                        '${order['state']}',
                      if (('${order['pincode'] ?? ''}')
                          .trim()
                          .isNotEmpty)
                        '${order['pincode']}',
                    ].join(
                      ', ',
                    ),
                    style:
                        const TextStyle(
                      color:
                          _ProfileScreenState
                              .dark,
                      fontSize:
                          13,
                      height:
                          1.45,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      18,
                ),

                const Text(
                  'ORDER ITEMS',
                  style:
                      TextStyle(
                    color:
                        _ProfileScreenState
                            .dark,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                ...items.map(
                  (item) =>
                      productItem(
                    item,
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                amountRow(
                  'Subtotal',
                  order['subtotal'],
                ),

                amountRow(
                  'Delivery Fee',
                  order['delivery_fee'],
                ),

                const Divider(),

                amountRow(
                  'Total',
                  order['total'],
                  bold:
                      true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(
        value.toString(),
      ).toLocal();
    } catch (_) {
      return null;
    }
  }

  Widget detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            5,
      ),
      child:
          Row(
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color:
                  _ProfileScreenState
                      .grey,
              fontSize:
                  12,
            ),
          ),
          const Spacer(),
          Flexible(
            child:
                Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    _ProfileScreenState
                        .dark,
                fontSize:
                    12,
                fontWeight:
                    FontWeight
                        .w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget productItem(
    Map<String, dynamic>
        item,
  ) {
    final image =
        '${item['image'] ?? ''}';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),
      padding:
          const EdgeInsets.all(
        10,
      ),
      decoration:
          BoxDecoration(
        color:
            _ProfileScreenState
                .background,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                58,
            height:
                58,
            decoration:
                BoxDecoration(
              color:
                  _ProfileScreenState
                      .lightGreen,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child:
                  image.isNotEmpty
                      ? Image.network(
                          image,
                          fit:
                              BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons
                                  .shopping_bag_outlined,
                              color:
                                  _ProfileScreenState
                                      .green,
                            );
                          },
                        )
                      : const Icon(
                          Icons
                              .shopping_bag_outlined,
                          color:
                              _ProfileScreenState
                                  .green,
                        ),
            ),
          ),
          const SizedBox(
            width:
                12,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  '${item['name'] ?? 'Product'}',
                  maxLines:
                      2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        _ProfileScreenState
                            .dark,
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
                const SizedBox(
                  height:
                      4,
                ),
                Text(
                  '${item['variant'] ?? ''} • Qty ${item['qty'] ?? 1}',
                  style:
                      const TextStyle(
                    color:
                        _ProfileScreenState
                            .grey,
                    fontSize:
                        11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item['price'] ?? 0}',
            style:
                const TextStyle(
              color:
                  _ProfileScreenState
                      .green,
              fontWeight:
                  FontWeight
                      .w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget amountRow(
    String title,
    dynamic amount, {
    bool bold =
        false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            6,
      ),
      child:
          Row(
        children: [
          Text(
            title,
            style:
                TextStyle(
              color:
                  bold
                      ? _ProfileScreenState
                          .dark
                      : _ProfileScreenState
                          .grey,
              fontSize:
                  bold
                      ? 14
                      : 12,
              fontWeight:
                  bold
                      ? FontWeight
                          .w800
                      : FontWeight
                          .w500,
            ),
          ),
          const Spacer(),
          Text(
            '₹${amount ?? 0}',
            style:
                TextStyle(
              color:
                  bold
                      ? _ProfileScreenState
                          .green
                      : _ProfileScreenState
                          .dark,
              fontSize:
                  bold
                      ? 15
                      : 12,
              fontWeight:
                  FontWeight
                      .w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM NAVIGATION
// ============================================================================

class FrutgoBottomNavigation
    extends StatelessWidget {
  final int currentIndex;

  const FrutgoBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  void navigate(
    BuildContext context,
    int index,
  ) {
    if (index ==
        currentIndex) {
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
        break;

      case 1:
        Navigator.pushNamed(
          context,
          '/home',
        );
        break;

      case 2:
        Navigator.pushNamed(
          context,
          '/cart',
        );
        break;

      case 3:
        break;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      top:
          false,
      child:
          Container(
        decoration:
            const BoxDecoration(
          color:
              Colors.white,
          border:
              Border(
            top:
                BorderSide(
              color:
                  Color(
                0xFFE5E5E5,
              ),
            ),
          ),
        ),
        child:
            BottomNavigationBar(
          currentIndex:
              currentIndex,
          onTap:
              (index) {
            navigate(
              context,
              index,
            );
          },
          backgroundColor:
              Colors.white,
          elevation:
              0,
          type:
              BottomNavigationBarType
                  .fixed,
          selectedItemColor:
              _ProfileScreenState
                  .green,
          unselectedItemColor:
              const Color(
            0xFF888888,
          ),
          selectedFontSize:
              11,
          unselectedFontSize:
              11,
          items:
              const [
            BottomNavigationBarItem(
              icon:
                  Icon(
                Icons
                    .home_outlined,
              ),
              activeIcon:
                  Icon(
                Icons
                    .home_rounded,
              ),
              label:
                  'Home',
            ),
            BottomNavigationBarItem(
              icon:
                  Icon(
                Icons
                    .search_outlined,
              ),
              activeIcon:
                  Icon(
                Icons
                    .search_rounded,
              ),
              label:
                  'Search',
            ),
            BottomNavigationBarItem(
              icon:
                  Icon(
                Icons
                    .shopping_cart_outlined,
              ),
              activeIcon:
                  Icon(
                Icons
                    .shopping_cart_rounded,
              ),
              label:
                  'Cart',
            ),
            BottomNavigationBarItem(
              icon:
                  Icon(
                Icons
                    .person_outline_rounded,
              ),
              activeIcon:
                  Icon(
                Icons
                    .person_rounded,
              ),
              label:
                  'Profile',
            ),
          ],
        ),
      ),
    );
  }
}