import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const UParkingApp());
}

// ============================================================================
// 1. MODELOS DE DATOS & ENUMS
// ============================================================================

enum UserRole {
  conductor,
  anfitrion,
}

enum VehicleCategory {
  bicicleta,
  scooter,
  motoneta,
  motocicleta,
  sedan,
  camioneta,
}

extension VehicleCategoryExtension on VehicleCategory {
  String get label {
    switch (this) {
      case VehicleCategory.bicicleta:
        return 'Bicicleta';
      case VehicleCategory.scooter:
        return 'Scooter eléctrico';
      case VehicleCategory.motoneta:
        return 'Motoneta';
      case VehicleCategory.motocicleta:
        return 'Motocicleta';
      case VehicleCategory.sedan:
        return 'Sedán / Compacto';
      case VehicleCategory.camioneta:
        return 'Camioneta / SUV';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleCategory.bicicleta:
        return Icons.pedal_bike;
      case VehicleCategory.scooter:
        return Icons.electric_scooter;
      case VehicleCategory.motoneta:
        return Icons.moped;
      case VehicleCategory.motocicleta:
        return Icons.two_wheeler;
      case VehicleCategory.sedan:
        return Icons.directions_car;
      case VehicleCategory.camioneta:
        return Icons.airport_shuttle;
    }
  }
}

enum PaymentMethod {
  billetera,
  efectivo,
  spei,
  tarjeta,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.billetera:
        return 'Billetera U-Parking (Saldo)';
      case PaymentMethod.efectivo:
        return 'Efectivo en cochera';
      case PaymentMethod.spei:
        return 'Transferencia SPEI / CoDi';
      case PaymentMethod.tarjeta:
        return 'Tarjeta Débito/Crédito';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.billetera:
        return Icons.account_balance_wallet;
      case PaymentMethod.efectivo:
        return Icons.payments_outlined;
      case PaymentMethod.spei:
        return Icons.account_balance_outlined;
      case PaymentMethod.tarjeta:
        return Icons.credit_card;
    }
  }
}

class UserAccount {
  String id;
  String name;
  String email;
  String phone;
  UserRole role;
  String defaultPlate;
  VehicleCategory defaultVehicle;
  double walletBalance; // Saldo real en la app

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.defaultPlate = 'UAP-102-B',
    this.defaultVehicle = VehicleCategory.sedan,
    this.walletBalance = 150.0,
  });
}

class Review {
  final String authorName;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class PeakHourRange {
  final double startDecimal;
  final double endDecimal;
  final String label;

  PeakHourRange({
    required this.startDecimal,
    required this.endDecimal,
    required this.label,
  });
}

class HostProfile {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final String avatarUrl;

  HostProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.avatarUrl,
  });
}

class ParkingSpot {
  final String id;
  String title;
  String address;
  String zone;
  double basePricePerHour;
  double rating;
  int totalBays;
  int availableBays;
  List<VehicleCategory> allowedVehicles;
  String availableHoursLabel;
  List<PeakHourRange> peakHours;
  List<String> tags;
  List<String> images;
  final HostProfile host;
  final double latitude;
  final double longitude;
  String howToGetThere;
  String heightLimit;
  String maxVehicleLength;
  String specificLimitations;
  final List<Review> reviews;

  ParkingSpot({
    required this.id,
    required this.title,
    required this.address,
    required this.zone,
    required this.basePricePerHour,
    required this.rating,
    required this.totalBays,
    required this.availableBays,
    required this.allowedVehicles,
    required this.availableHoursLabel,
    required this.peakHours,
    required this.tags,
    required this.images,
    required this.host,
    required this.latitude,
    required this.longitude,
    required this.howToGetThere,
    required this.heightLimit,
    required this.maxVehicleLength,
    required this.specificLimitations,
    required this.reviews,
  });
}

class Reservation {
  final String id;
  final ParkingSpot spot;
  final DateTime reservationDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double durationHours;
  final double totalAmount;
  final bool hasPeakSurge;
  final VehicleCategory vehicleUsed;
  final String driverName;
  final String driverPhone;
  final String plateNumber;
  final PaymentMethod paymentMethod;
  String status; // "Confirmada", "Cancelada"

  Reservation({
    required this.id,
    required this.spot,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalAmount,
    required this.hasPeakSurge,
    required this.vehicleUsed,
    required this.driverName,
    required this.driverPhone,
    required this.plateNumber,
    required this.paymentMethod,
    this.status = "Confirmada",
  });
}

// ============================================================================
// 2. ESTADO GLOBAL SIMULADO
// ============================================================================

UserAccount? currentUser;

final List<ParkingSpot> globalSpots = [
  ParkingSpot(
    id: 'up-centro-1',
    title: 'Cochera Casona 4 Poniente (Centro)',
    address: 'Calle 4 Poniente #518, Centro Histórico, Puebla',
    zone: 'Centro Histórico',
    basePricePerHour: 22.0,
    rating: 4.9,
    totalBays: 4,
    availableBays: 2,
    allowedVehicles: [VehicleCategory.sedan, VehicleCategory.camioneta, VehicleCategory.motoneta],
    availableHoursLabel: '07:30 - 21:30',
    peakHours: [
      PeakHourRange(startDecimal: 13.0, endDecimal: 16.0, label: '13:00 - 16:00 (Zona Restaurantera)'),
      PeakHourRange(startDecimal: 18.0, endDecimal: 20.5, label: '18:00 - 20:30 (Comercio Centro)'),
    ],
    tags: ['Techado Colonial', 'Cámaras 24h', 'Zócalo a 3 calles'],
    images: [
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
    ],
    host: HostProfile(
      id: 'host-1',
      name: 'Don Ignacio Ramos',
      phone: '222-211-9080',
      rating: 4.9,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
    ),
    latitude: 19.0465,
    longitude: -98.2012,
    howToGetThere: 'Bajar por 4 Poniente pasando Santo Domingo, zaguán verde oscuro número 518.',
    heightLimit: '2.25 metros',
    maxVehicleLength: 'Máximo 4.90 m (Sin remolque)',
    specificLimitations: 'No se admiten vehículos con fugas activas de aceite. Apagar motor al ingresar.',
    reviews: [
      Review(authorName: 'Ana Lucía M.', rating: 5.0, comment: 'Súper céntrico, llegué al Zócalo caminando en 4 min. Don Ignacio muy atento.', date: 'Ayer'),
      Review(authorName: 'Rodrigo P.', rating: 4.8, comment: 'Lugar techado muy fresco y trato excelente.', date: 'Hace 3 días'),
    ],
  ),
  ParkingSpot(
    id: 'up-centro-2',
    title: 'Estación Eco & Motos Los Sapos',
    address: 'Calle 5 Oriente #604, Barrio de los Sapos, Puebla',
    zone: 'Centro Histórico',
    basePricePerHour: 16.0,
    rating: 4.8,
    totalBays: 8,
    availableBays: 5,
    allowedVehicles: [
      VehicleCategory.bicicleta,
      VehicleCategory.scooter,
      VehicleCategory.motoneta,
      VehicleCategory.motocicleta,
      VehicleCategory.sedan,
    ],
    availableHoursLabel: '08:00 - 23:00',
    peakHours: [
      PeakHourRange(startDecimal: 14.0, endDecimal: 17.5, label: '14:00 - 17:30 (Tarde de Cafeterías)'),
    ],
    tags: ['Especial Bicis/Motos', 'Cámaras', 'Junto a Cafeterías'],
    images: [
      'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=700',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
    ],
    host: HostProfile(
      id: 'host-2',
      name: 'Beatriz Solís',
      phone: '222-456-1122',
      rating: 4.8,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120',
    ),
    latitude: 19.0418,
    longitude: -98.1965,
    howToGetThere: 'Sobre 5 Oriente cruzando 6 Sur, a 50 metros del Callejón de los Sapos, reja negra.',
    heightLimit: '2.10 metros',
    maxVehicleLength: 'Solo sedanes compactos y dos ruedas',
    specificLimitations: 'Prohibidas pickups dobles. Bicicletas deben traer candado de horquilla.',
    reviews: [
      Review(authorName: 'Carlos G.', rating: 4.8, comment: 'Excelente para dejar la motoneta mientras trabajas en los cafés.', date: 'Hace 5 días'),
    ],
  ),
  ParkingSpot(
    id: 'up-cu-1',
    title: 'Cochera Techada San Claudio (Frente a CU)',
    address: 'Av. San Claudio #1402 (Frente a Fac. Computación), Puebla',
    zone: 'Ciudad Universitaria (CU)',
    basePricePerHour: 18.0,
    rating: 4.9,
    totalBays: 3,
    availableBays: 1,
    allowedVehicles: [VehicleCategory.sedan, VehicleCategory.camioneta, VehicleCategory.motoneta],
    availableHoursLabel: '06:45 - 21:15',
    peakHours: [
      PeakHourRange(startDecimal: 7.5, endDecimal: 10.0, label: '07:30 - 10:00 (Entrada a Clases)'),
      PeakHourRange(startDecimal: 13.0, endDecimal: 15.0, label: '13:00 - 15:00 (Cambio de Turno)'),
    ],
    tags: ['Techado', 'Portón Eléctrico', 'Cámaras CU'],
    images: [
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=700',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
    ],
    host: HostProfile(
      id: 'host-3',
      name: 'Carlos Mendoza',
      phone: '222-345-6789',
      rating: 4.9,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
    ),
    latitude: 19.0025,
    longitude: -98.2014,
    howToGetThere: 'Sobre Av. San Claudio frente a la Facultad de Computación, portón blanco número 1402.',
    heightLimit: '2.20 metros',
    maxVehicleLength: '5.10 metros',
    specificLimitations: 'Portón automatizado. Se entrega control para estancias largas con depósito.',
    reviews: [
      Review(authorName: 'Gabriel S.', rating: 5.0, comment: 'Cruzas la calle y estás en la facultad. Servicio de 10.', date: 'Hace 2 días'),
      Review(authorName: 'Valeria T.', rating: 4.9, comment: 'Sombra todo el día, lugar impecable.', date: 'Hace 1 semana'),
    ],
  ),
];

final List<Reservation> globalReservations = [];

// ============================================================================
// 3. MOCK FRAME MÓVIL (VISTA EN CELULAR)
// ============================================================================

class UParkingApp extends StatelessWidget {
  const UParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U-Parking Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003B5C),
          primary: const Color(0xFF003B5C),
          secondary: const Color(0xFF00B4D8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003B5C),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const DeviceSimulationShell(),
    );
  }
}

class DeviceSimulationShell extends StatefulWidget {
  const DeviceSimulationShell({super.key});

  @override
  State<DeviceSimulationShell> createState() => _DeviceSimulationShellState();
}

class _DeviceSimulationShellState extends State<DeviceSimulationShell> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E222A),
        body: Center(
          child: Container(
            width: 395,
            height: 820,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(42),
              border: Border.all(color: const Color(0xFF2C323D), width: 10),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 4),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Column(
                children: [
                  Container(
                    height: 28,
                    color: const Color(0xFF003B5C),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('13:58', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.white70, size: 13),
                            SizedBox(width: 4),
                            Icon(Icons.battery_full, color: Colors.white70, size: 13),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: currentUser == null
                        ? AuthScreen(onAuthSuccess: _refresh)
                        : (currentUser!.role == UserRole.conductor
                            ? DriverMainShell(onLogout: _refresh)
                            : HostMainShell(onLogout: _refresh)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return currentUser == null
        ? AuthScreen(onAuthSuccess: _refresh)
        : (currentUser!.role == UserRole.conductor
            ? DriverMainShell(onLogout: _refresh)
            : HostMainShell(onLogout: _refresh));
  }
}

// ============================================================================
// 4. AUTENTICACIÓN (LOGIN & REGISTRO CON ROLES)
// ============================================================================

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginEmailCtrl = TextEditingController(text: 'cristian.pulido@buap.mx');
  final _loginPassCtrl = TextEditingController(text: '123456');

  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.conductor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _login() {
    currentUser = UserAccount(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: _selectedRole == UserRole.conductor ? 'Cristian Pulido' : 'Don Ignacio Ramos',
      email: _loginEmailCtrl.text.trim(),
      phone: _selectedRole == UserRole.conductor ? '222-765-4321' : '222-211-9080',
      role: _selectedRole,
      walletBalance: _selectedRole == UserRole.conductor ? 150.0 : 580.0,
    );
    widget.onAuthSuccess();
  }

  void _register() {
    if (_regNameCtrl.text.trim().isEmpty || _regEmailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    currentUser = UserAccount(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: _regNameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      phone: _regPhoneCtrl.text.trim().isEmpty ? '222-000-0000' : _regPhoneCtrl.text.trim(),
      role: _selectedRole,
      walletBalance: _selectedRole == UserRole.conductor ? 100.0 : 0.0,
    );
    widget.onAuthSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 65,
        centerTitle: true,
        title: const Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_parking, size: 24),
                SizedBox(width: 6),
                Text('U-PARKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
              ],
            ),
            Text('Puebla Centro & Zona Universitaria', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Registrarse'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRoleSelector(),
                const SizedBox(height: 16),
                TextField(
                  controller: _loginEmailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B5C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _login,
                  child: Text('Ingresar como ${_selectedRole == UserRole.conductor ? "Conductor" : "Anfitrión"}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRoleSelector(),
                const SizedBox(height: 14),
                TextField(
                  controller: _regNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _regEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo institucional o personal', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _regPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _regPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline), isDense: true),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B5C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _register,
                  child: const Text('Crear Cuenta', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingresar con el Rol de:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedRole = UserRole.conductor),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedRole == UserRole.conductor ? const Color(0xFF003B5C) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedRole == UserRole.conductor ? const Color(0xFF003B5C) : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.directions_car, size: 20, color: _selectedRole == UserRole.conductor ? Colors.white : Colors.black87),
                      const SizedBox(height: 2),
                      Text('Conductor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _selectedRole == UserRole.conductor ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedRole = UserRole.anfitrion),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedRole == UserRole.anfitrion ? const Color(0xFF003B5C) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedRole == UserRole.anfitrion ? const Color(0xFF003B5C) : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.house_siding, size: 20, color: _selectedRole == UserRole.anfitrion ? Colors.white : Colors.black87),
                      const SizedBox(height: 2),
                      Text('Anfitrión / Cochera', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _selectedRole == UserRole.anfitrion ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 5. SHELLS POR ROL
// ============================================================================

class DriverMainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const DriverMainShell({super.key, required this.onLogout});

  @override
  State<DriverMainShell> createState() => _DriverMainShellState();
}

class _DriverMainShellState extends State<DriverMainShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DriverExplorePage(),
      const DriverReservationsPage(),
      UserProfilePage(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Color(0xFF003B5C)),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number, color: Color(0xFF003B5C)),
            label: 'Mis Citas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF003B5C)),
            label: 'Mi Perfil',
          ),
        ],
      ),
    );
  }
}

class HostMainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const HostMainShell({super.key, required this.onLogout});

  @override
  State<HostMainShell> createState() => _HostMainShellState();
}

class _HostMainShellState extends State<HostMainShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HostDashboardPage(onNavigateToPublish: () => setState(() => _idx = 1)),
      SpotFormPage(onSaved: () => setState(() => _idx = 0)),
      const HostReservationsManagerPage(),
      UserProfilePage(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF003B5C)),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box, color: Color(0xFF003B5C)),
            label: 'Publicar',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl, color: Color(0xFF003B5C)),
            label: 'Gestión',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF003B5C)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. VISTA CONDUCTOR: EXPLORAR COCHERAS
// ============================================================================

class DriverExplorePage extends StatefulWidget {
  const DriverExplorePage({super.key});

  @override
  State<DriverExplorePage> createState() => _DriverExplorePageState();
}

class _DriverExplorePageState extends State<DriverExplorePage> {
  VehicleCategory? _filterCategory;
  String _selectedZone = 'Todas';

  @override
  Widget build(BuildContext context) {
    var filteredSpots = globalSpots.where((s) {
      final matchesVehicle = _filterCategory == null || s.allowedVehicles.contains(_filterCategory);
      final matchesZone = _selectedZone == 'Todas' || s.zone == _selectedZone;
      return matchesVehicle && matchesZone;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_car, size: 22),
            SizedBox(width: 8),
            Text('Buscar Estacionamiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('\$${currentUser?.walletBalance.toStringAsFixed(0) ?? "0"}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.blue.shade50.withOpacity(0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todas', 'Centro Histórico', 'Ciudad Universitaria (CU)'].map((zone) {
                  final isSelected = _selectedZone == zone;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(zone, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF003B5C),
                      onSelected: (_) => setState(() => _selectedZone = zone),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos', style: TextStyle(fontSize: 11)),
                    selected: _filterCategory == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterCategory = null);
                    },
                  ),
                  const SizedBox(width: 6),
                  ...VehicleCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        avatar: Icon(cat.icon, size: 14),
                        label: Text(cat.label, style: const TextStyle(fontSize: 11)),
                        selected: _filterCategory == cat,
                        onSelected: (selected) {
                          setState(() => _filterCategory = selected ? cat : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredSpots.isEmpty
                ? const Center(child: Text('No hay estacionamientos con este criterio.'))
                : ListView.builder(
                    itemCount: filteredSpots.length,
                    itemBuilder: (context, index) {
                      final spot = filteredSpots[index];
                      return _buildSpotCard(spot);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(ParkingSpot spot) {
    final hasSpace = spot.availableBays > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SpotDetailPage(spot: spot)),
          ).then((_) => setState(() {}));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    spot.images.isNotEmpty ? spot.images.first : 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 145, color: Colors.grey[200], child: const Icon(Icons.garage, size: 48, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasSpace ? Colors.teal : Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      hasSpace ? '${spot.availableBays} cajones libres' : 'Lleno',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
                    child: Text(spot.availableHoursLabel, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(spot.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 15, color: Colors.amber),
                          Text(' ${spot.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(' (${spot.reviews.length})', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(spot.address, style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(radius: 9, backgroundImage: NetworkImage(spot.host.avatarUrl)),
                      const SizedBox(width: 6),
                      Text('Anfitrión: ${spot.host.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (spot.peakHours.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 13, color: Colors.deepOrange),
                          const SizedBox(width: 3),
                          Text('Alta demanda: ${spot.peakHours.first.label}', style: const TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: spot.allowedVehicles.map((v) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(v.icon, size: 16, color: const Color(0xFF003B5C)),
                          );
                        }).toList(),
                      ),
                      Text(
                        '\$${spot.basePricePerHour.toStringAsFixed(2)} MXN / h',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. DETALLE Y APARTADO (CON MÉTODOS DE PAGO Y BILLETERA RESTAURADOS)
// ============================================================================

class SpotDetailPage extends StatefulWidget {
  final ParkingSpot spot;
  const SpotDetailPage({super.key, required this.spot});

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  late VehicleCategory _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  PaymentMethod _selectedPayment = PaymentMethod.billetera;
  int _photoIndex = 0;

  final _plateCtrl = TextEditingController(text: currentUser?.defaultPlate ?? 'UAP-102-B');
  final _driverPhoneCtrl = TextEditingController(text: currentUser?.phone ?? '222-765-4321');
  final _reviewCommentCtrl = TextEditingController();
  double _reviewScore = 5.0;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.spot.allowedVehicles.isNotEmpty
        ? widget.spot.allowedVehicles.first
        : VehicleCategory.sedan;
  }

  bool _isPeak(TimeOfDay start, TimeOfDay end) {
    double s = start.hour + (start.minute / 60.0);
    double e = end.hour + (end.minute / 60.0);
    for (var peak in widget.spot.peakHours) {
      if (s < peak.endDecimal && e > peak.startDecimal) return true;
    }
    return false;
  }

  double _duration() {
    double s = _startTime.hour + (_startTime.minute / 60.0);
    double e = _endTime.hour + (_endTime.minute / 60.0);
    double d = e - s;
    return d > 0 ? d : (d + 24);
  }

  double _total(double duration, bool isPeak) {
    double b = widget.spot.basePricePerHour * duration;
    return isPeak ? (b * 1.25) : b;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _openAddReviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Escribir Reseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calificación en estrellas:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 2, 3, 4, 5].map((star) {
                      return IconButton(
                        icon: Icon(
                          star <= _reviewScore ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () => setDialogState(() => _reviewScore = star.toDouble()),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewCommentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '¿Cómo estuvo la atención y la cochera?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B5C)),
                  onPressed: () {
                    if (_reviewCommentCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        widget.spot.reviews.insert(
                          0,
                          Review(
                            authorName: currentUser?.name ?? 'Usuario U-Parking',
                            rating: _reviewScore,
                            comment: _reviewCommentCtrl.text.trim(),
                            date: 'Hoy',
                          ),
                        );
                        double sum = widget.spot.reviews.fold(0, (prev, r) => prev + r.rating);
                        widget.spot.rating = sum / widget.spot.reviews.length;
                      });
                      _reviewCommentCtrl.clear();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Publicar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmReservation() {
    if (widget.spot.availableBays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cajones disponibles.'), backgroundColor: Colors.red),
      );
      return;
    }

    final duration = _duration();
    final isPeakHour = _isPeak(_startTime, _endTime);
    final totalAmount = _total(duration, isPeakHour);

    // Validación de saldo si elige Billetera U-Parking
    if (_selectedPayment == PaymentMethod.billetera) {
      if ((currentUser?.walletBalance ?? 0) < totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldo insuficiente en Billetera U-Parking. Recarga en tu Perfil o selecciona otro método.'),
            backgroundColor: Colors.deepOrange,
          ),
        );
        return;
      }
      currentUser!.walletBalance -= totalAmount;
    }

    final res = Reservation(
      id: 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      spot: widget.spot,
      reservationDate: _selectedDate,
      startTime: _startTime,
      endTime: _endTime,
      durationHours: duration,
      totalAmount: totalAmount,
      hasPeakSurge: isPeakHour,
      vehicleUsed: _selectedVehicle,
      driverName: currentUser?.name ?? 'Conductor',
      driverPhone: _driverPhoneCtrl.text.trim(),
      plateNumber: _plateCtrl.text.trim(),
      paymentMethod: _selectedPayment,
    );

    setState(() {
      widget.spot.availableBays--;
      globalReservations.insert(0, res);
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Cita Confirmada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${res.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B5C))),
            Text('Anfitrión: ${widget.spot.host.name} (${widget.spot.host.phone})'),
            Text('Vehículo: ${_selectedVehicle.label} (${_plateCtrl.text})'),
            Text('Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            Text('Horario: ${_startTime.format(context)} a ${_endTime.format(context)}'),
            Text('Método de pago: ${_selectedPayment.label}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Divider(),
            Text('Total cobrado: \$${totalAmount.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B5C)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration();
    final isPeakHour = _isPeak(_startTime, _endTime);
    final totalAmount = _total(duration, isPeakHour);

    return Scaffold(
      appBar: AppBar(title: Text(widget.spot.title, style: const TextStyle(fontSize: 16))),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotos
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: widget.spot.images.length,
                    onPageChanged: (i) => setState(() => _photoIndex = i),
                    itemBuilder: (context, i) => Image.network(
                      widget.spot.images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.garage, size: 50)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                    child: Text('Foto ${_photoIndex + 1}/${widget.spot.images.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF003B5C), borderRadius: BorderRadius.circular(12)),
                        child: Text(widget.spot.zone, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(' ${widget.spot.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' (${widget.spot.reviews.length} reseñas)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.spot.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.spot.address, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  const SizedBox(height: 12),

                  // Ficha del Anfitrión
                  Card(
                    elevation: 1,
                    color: Colors.blue.shade50.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 24, backgroundImage: NetworkImage(widget.spot.host.avatarUrl)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(widget.spot.host.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 14, color: Colors.blue),
                                  ],
                                ),
                                Text('Anfitrión U-Parking • ${widget.spot.host.rating} ★', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                                Text('Tel: ${widget.spot.host.phone}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.phone, size: 18),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Llamando a ${widget.spot.host.name}...')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Limitaciones físicas
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Limitaciones del Espacio:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                        Text('• Altura: ${widget.spot.heightLimit} | Largo: ${widget.spot.maxVehicleLength}', style: const TextStyle(fontSize: 11.5)),
                        Text('• Restricción: ${widget.spot.specificLimitations}', style: const TextStyle(fontSize: 11.5)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Horas de alta demanda
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50.withOpacity(0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Horas de Alta Demanda (+25%):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange)),
                            Text('Base: \$${widget.spot.basePricePerHour} MXN/h', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                          ],
                        ),
                        ...widget.spot.peakHours.map((p) => Text('• ${p.label}', style: const TextStyle(fontSize: 11.5))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Selección de vehículo y placas
                  const Text('1. Vehículo a Estacionar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: widget.spot.allowedVehicles.map((v) {
                      final sel = _selectedVehicle == v;
                      return ChoiceChip(
                        avatar: Icon(v.icon, size: 15, color: sel ? Colors.white : Colors.black87),
                        label: Text(v.label, style: const TextStyle(fontSize: 11)),
                        selected: sel,
                        selectedColor: const Color(0xFF003B5C),
                        labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          if (val) setState(() => _selectedVehicle = v);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _plateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Placas o referencia del vehículo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Fecha y Horario
                  const Text('2. Fecha y Horario de tu Cita:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 15),
                    label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (Cambiar Fecha)'),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(true),
                          icon: const Icon(Icons.login, size: 15),
                          label: Text('De: ${_startTime.format(context)}', style: const TextStyle(fontSize: 11.5)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(false),
                          icon: const Icon(Icons.logout, size: 15),
                          label: Text('A: ${_endTime.format(context)}', style: const TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ),

                  if (isPeakHour) ...[
                    const SizedBox(height: 6),
                    const Text('⚡ Recargo de hora pico incluido en el total.', style: TextStyle(color: Colors.deepOrange, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],

                  const SizedBox(height: 14),

                  // 3. MÉTODOS DE PAGO RESTAURADOS AL ESCOGER CAJÓN
                  const Text('3. Método de Pago:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...PaymentMethod.values.map((m) {
                    return RadioListTile<PaymentMethod>(
                      value: m,
                      groupValue: _selectedPayment,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(m.icon, size: 18, color: const Color(0xFF003B5C)),
                      title: Text(m.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      subtitle: m == PaymentMethod.billetera
                          ? Text('Saldo actual: \$${currentUser?.walletBalance.toStringAsFixed(2) ?? "0.00"} MXN', style: const TextStyle(fontSize: 11, color: Colors.teal))
                          : null,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPayment = val);
                      },
                    );
                  }),

                  const Divider(height: 24),

                  // Reseñas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reseñas (${widget.spot.reviews.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.rate_review_outlined, size: 15),
                        label: const Text('Calificar', style: TextStyle(fontSize: 12)),
                        onPressed: _openAddReviewDialog,
                      ),
                    ],
                  ),
                  ...widget.spot.reviews.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('${r.rating} ★ • ${r.date}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              Text(r.comment, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total (${duration.toStringAsFixed(1)} hrs):', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('\$${totalAmount.toStringAsFixed(2)} MXN', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003B5C))),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B5C), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
              onPressed: _confirmReservation,
              child: const Text('Agendar Cita', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. VISTA CONDUCTOR: MIS CITAS (CON REEMBOLSO A BILLETERA AL CANCELAR)
// ============================================================================

class DriverReservationsPage extends StatefulWidget {
  const DriverReservationsPage({super.key});

  @override
  State<DriverReservationsPage> createState() => _DriverReservationsPageState();
}

class _DriverReservationsPageState extends State<DriverReservationsPage> {
  void _cancel(Reservation r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar Cita?'),
        content: Text(
          'Se liberará el cajón en "${r.spot.title}".\n'
          '${r.paymentMethod == PaymentMethod.billetera ? "El monto de \$${r.totalAmount.toStringAsFixed(2)} MXN se reembolsará a tu Billetera U-Parking." : ""}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                r.status = 'Cancelada';
                r.spot.availableBays++;
                if (r.paymentMethod == PaymentMethod.billetera && currentUser != null) {
                  currentUser!.walletBalance += r.totalAmount;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Citas de Estacionamiento')),
      body: globalReservations.isEmpty
          ? const Center(child: Text('No tienes reservaciones agendadas.'))
          : ListView.builder(
              itemCount: globalReservations.length,
              itemBuilder: (context, i) {
                final r = globalReservations[i];
                final isCancelled = r.status == "Cancelada";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B5C))),
                            Chip(
                              label: Text(r.status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                              backgroundColor: isCancelled ? Colors.grey : Colors.teal,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        Text(r.spot.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Anfitrión: ${r.spot.host.name} (${r.spot.host.phone})', style: const TextStyle(fontSize: 11.5, color: Colors.blueGrey)),
                        Text('Fecha: ${r.reservationDate.day}/${r.reservationDate.month}/${r.reservationDate.year} • ${r.startTime.format(context)} a ${r.endTime.format(context)}', style: const TextStyle(fontSize: 11.5)),
                        Text('Método de pago: ${r.paymentMethod.label}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: \$${r.totalAmount.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (!isCancelled)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () => _cancel(r),
                                child: const Text('Cancelar Cita', style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 9. VISTA ANFITRIÓN: PANEL DE CONTROL (CON EDITAR Y ELIMINAR PUBLICACIÓN)
// ============================================================================

class HostDashboardPage extends StatefulWidget {
  final VoidCallback onNavigateToPublish;
  const HostDashboardPage({super.key, required this.onNavigateToPublish});

  @override
  State<HostDashboardPage> createState() => _HostDashboardPageState();
}

class _HostDashboardPageState extends State<HostDashboardPage> {
  void _deleteSpot(ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Estacionamiento?'),
        content: Text('¿Estás seguro de eliminar "${spot.title}" de la plataforma?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                globalSpots.remove(spot);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicación eliminada.')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editSpot(ParkingSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotFormPage(
          spotToEdit: spot,
          onSaved: () {
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSpots = globalSpots.length;
    int totalBaysCount = globalSpots.fold(0, (sum, s) => sum + s.totalBays);
    int freeBaysCount = globalSpots.fold(0, (sum, s) => sum + s.availableBays);
    int occupiedBaysCount = totalBaysCount - freeBaysCount;
    double totalRevenue = globalReservations
        .where((r) => r.status != "Cancelada")
        .fold(0.0, (sum, r) => sum + r.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard, size: 22),
            SizedBox(width: 8),
            Text('Panel de Control Anfitrión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${currentUser?.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Text('Administra, edita o elimina tus cocheras publicadas.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _buildMetricCard('Ingresos por Citas', '\$${totalRevenue.toStringAsFixed(2)}', Icons.monetization_on, Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Cajones Ocupados', '$occupiedBaysCount de $totalBaysCount', Icons.directions_car, Colors.deepOrange)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Cajones Libres', '$freeBaysCount libres', Icons.check_circle_outline, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Cocheras Activas', '$totalSpots lugares', Icons.home_work, const Color(0xFF003B5C))),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mis Cocheras Publicadas:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Publicar Nueva'),
                  onPressed: widget.onNavigateToPublish,
                ),
              ],
            ),
            const SizedBox(height: 6),

            ...globalSpots.map((spot) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(spot.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Editar publicación',
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                onPressed: () => _editSpot(spot),
                              ),
                              IconButton(
                                tooltip: 'Eliminar publicación',
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _deleteSpot(spot),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(spot.address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: spot.allowedVehicles.map((v) => Chip(
                              label: Text(v.label, style: const TextStyle(fontSize: 9.5)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            )).toList(),
                      ),
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Libres: ${spot.availableBays} / ${spot.totalBays}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                icon: const Icon(Icons.remove, size: 15),
                                onPressed: spot.availableBays > 0 ? () => setState(() => spot.availableBays--) : null,
                              ),
                              const SizedBox(width: 4),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.add, size: 15),
                                onPressed: spot.availableBays < spot.totalBays ? () => setState(() => spot.availableBays++) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. FORMULARIO UNIFICADO DE PUBLICAR Y EDITAR COCHERA (Con Vehículos y Fotos)
// ============================================================================

class SpotFormPage extends StatefulWidget {
  final ParkingSpot? spotToEdit;
  final VoidCallback onSaved;

  const SpotFormPage({super.key, this.spotToEdit, required this.onSaved});

  @override
  State<SpotFormPage> createState() => _SpotFormPageState();
}

class _SpotFormPageState extends State<SpotFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _baysCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _lengthCtrl;
  late TextEditingController _rulesCtrl;
  late TextEditingController _hoursCtrl;
  final _photoUrlCtrl = TextEditingController();

  String _zone = 'Centro Histórico';
  List<VehicleCategory> _allowedVehicles = [];
  List<String> _spotImages = [];

  @override
  void initState() {
    super.initState();
    final s = widget.spotToEdit;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _priceCtrl = TextEditingController(text: s?.basePricePerHour.toString() ?? '');
    _baysCtrl = TextEditingController(text: s?.totalBays.toString() ?? '3');
    _heightCtrl = TextEditingController(text: s?.heightLimit ?? '2.20 m');
    _lengthCtrl = TextEditingController(text: s?.maxVehicleLength ?? '4.80 m');
    _rulesCtrl = TextEditingController(text: s?.specificLimitations ?? 'No fugas de aceite. Dejar llave si pernocta.');
    _hoursCtrl = TextEditingController(text: s?.availableHoursLabel ?? '07:00 - 21:00');

    _zone = s?.zone ?? 'Centro Histórico';
    _allowedVehicles = s != null ? List.from(s.allowedVehicles) : [VehicleCategory.sedan, VehicleCategory.camioneta];
    _spotImages = s != null
        ? List.from(s.images)
        : ['https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700'];
  }

  void _addPhotoUrl() {
    final url = _photoUrlCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _spotImages.add(url);
        _photoUrlCtrl.clear();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_allowedVehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos un tipo de vehículo permitido.')),
        );
        return;
      }

      if (widget.spotToEdit != null) {
        // Actualizar cochera existente
        final s = widget.spotToEdit!;
        s.title = _titleCtrl.text.trim();
        s.address = _addressCtrl.text.trim();
        s.zone = _zone;
        s.basePricePerHour = double.parse(_priceCtrl.text.trim());
        s.totalBays = int.parse(_baysCtrl.text.trim());
        if (s.availableBays > s.totalBays) s.availableBays = s.totalBays;
        s.availableHoursLabel = _hoursCtrl.text.trim();
        s.allowedVehicles = List.from(_allowedVehicles);
        s.images = List.from(_spotImages);
        s.heightLimit = _heightCtrl.text.trim();
        s.maxVehicleLength = _lengthCtrl.text.trim();
        s.specificLimitations = _rulesCtrl.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cambios guardados en la publicación!'), backgroundColor: Colors.teal),
        );
      } else {
        // Crear nueva cochera
        final newSpot = ParkingSpot(
          id: 'up-${DateTime.now().millisecondsSinceEpoch}',
          title: _titleCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          zone: _zone,
          basePricePerHour: double.parse(_priceCtrl.text.trim()),
          rating: 5.0,
          totalBays: int.parse(_baysCtrl.text.trim()),
          availableBays: int.parse(_baysCtrl.text.trim()),
          allowedVehicles: List.from(_allowedVehicles),
          availableHoursLabel: _hoursCtrl.text.trim(),
          peakHours: [PeakHourRange(startDecimal: 13.0, endDecimal: 15.5, label: '13:00 - 15:30 (Pico Comercial)')],
          tags: ['Espacio Privado', 'Nuevo'],
          images: _spotImages.isEmpty
              ? ['https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700']
              : List.from(_spotImages),
          host: HostProfile(
            id: currentUser?.id ?? 'host-new',
            name: currentUser?.name ?? 'Anfitrión',
            phone: currentUser?.phone ?? '222-123-4567',
            rating: 5.0,
            avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
          ),
          latitude: 19.0435,
          longitude: -98.2000,
          howToGetThere: 'Tocar el timbre al llegar al portón.',
          heightLimit: _heightCtrl.text.trim(),
          maxVehicleLength: _lengthCtrl.text.trim(),
          specificLimitations: _rulesCtrl.text.trim(),
          reviews: [],
        );
        globalSpots.insert(0, newSpot);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cochera publicada con éxito!'), backgroundColor: Colors.teal),
        );
      }

      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.spotToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Estacionamiento' : 'Publicar Estacionamiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Datos Generales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _zone,
                decoration: const InputDecoration(labelText: 'Zona en Puebla', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'Centro Histórico', child: Text('Centro Histórico')),
                  DropdownMenuItem(value: 'Ciudad Universitaria (CU)', child: Text('Ciudad Universitaria (CU)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _zone = val);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título del espacio', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Dirección completa', border: OutlineInputBorder(), isDense: true),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarifa (\$ MXN/h)', border: OutlineInputBorder(), isDense: true),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _baysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cajones totales', border: OutlineInputBorder(), isDense: true),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(labelText: 'Horario disponible (ej. 07:00 - 21:00)', border: OutlineInputBorder(), isDense: true),
              ),

              const SizedBox(height: 16),

              // 2. TIPOS DE VEHÍCULOS ACEPTADOS (RESTAURADO)
              const Text('2. Tipos de Vehículos Aceptados:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: VehicleCategory.values.map((cat) {
                  final checked = _allowedVehicles.contains(cat);
                  return FilterChip(
                    avatar: Icon(cat.icon, size: 15),
                    label: Text(cat.label, style: const TextStyle(fontSize: 11)),
                    selected: checked,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _allowedVehicles.add(cat);
                        } else {
                          _allowedVehicles.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // 3. FOTOS DEL LUGAR (RESTAURADO)
              const Text('3. Galería de Fotos del Lugar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _photoUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pegar enlace URL de imagen',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _addPhotoUrl,
                    child: const Text('Añadir'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 75,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _spotImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(image: NetworkImage(_spotImages[index]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: InkWell(
                            onTap: () => setState(() => _spotImages.removeAt(index)),
                            child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 4. LIMITACIONES FÍSICAS
              const Text('4. Limitaciones y Medidas:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _heightCtrl, decoration: const InputDecoration(labelText: 'Altura máx', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _lengthCtrl, decoration: const InputDecoration(labelText: 'Largo máx', border: OutlineInputBorder(), isDense: true))),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _rulesCtrl, decoration: const InputDecoration(labelText: 'Restricciones particulares', border: OutlineInputBorder(), isDense: true)),

              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: const Color(0xFF003B5C),
                ),
                onPressed: _submit,
                child: Text(isEditing ? 'Guardar Cambios' : 'Publicar Cochera', style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 11. GESTIÓN DE RESERVAS (ANFITRIÓN)
// ============================================================================

class HostReservationsManagerPage extends StatelessWidget {
  const HostReservationsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas de Clientes')),
      body: globalReservations.isEmpty
          ? const Center(child: Text('Aún no tienes reservaciones registradas por conductores.'))
          : ListView.builder(
              itemCount: globalReservations.length,
              itemBuilder: (context, index) {
                final r = globalReservations[index];
                final isCancelled = r.status == "Cancelada";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B5C))),
                            Chip(
                              label: Text(r.status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                              backgroundColor: isCancelled ? Colors.grey : Colors.teal,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        Text('Cochera: ${r.spot.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text('Cliente: ${r.driverName} • Placas: ${r.plateNumber}', style: const TextStyle(fontSize: 12)),
                        Text('Fecha: ${r.reservationDate.day}/${r.reservationDate.month}/${r.reservationDate.year} • ${r.startTime.format(context)} a ${r.endTime.format(context)}', style: const TextStyle(fontSize: 11.5)),
                        Text('Total: \$${r.totalAmount.toStringAsFixed(2)} MXN • Pago: ${r.paymentMethod.label}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF003B5C))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 12. PERFIL DE USUARIO (CON EDITAR PERFIL Y RECARGA DE BILLETERA)
// ============================================================================

class UserProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  const UserProfilePage({super.key, required this.onLogout});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  void _openEditProfileDialog() {
    final nameCtrl = TextEditingController(text: currentUser?.name ?? '');
    final phoneCtrl = TextEditingController(text: currentUser?.phone ?? '');
    final plateCtrl = TextEditingController(text: currentUser?.defaultPlate ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre completo', isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp', isDense: true)),
            if (currentUser?.role == UserRole.conductor) ...[
              const SizedBox(height: 10),
              TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Placas predeterminadas', isDense: true)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B5C)),
            onPressed: () {
              setState(() {
                if (currentUser != null) {
                  currentUser!.name = nameCtrl.text.trim();
                  currentUser!.phone = phoneCtrl.text.trim();
                  currentUser!.defaultPlate = plateCtrl.text.trim();
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Perfil actualizado correctamente!')),
              );
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openRechargeWalletDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recargar Billetera U-Parking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona el monto de recarga prepagada:', style: TextStyle(fontSize: 12.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [50.0, 100.0, 200.0].map((amount) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (currentUser != null) currentUser!.walletBalance += amount;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('¡+\$${amount.toStringAsFixed(0)} MXN añadidos a tu Billetera!'), backgroundColor: Colors.teal),
                    );
                  },
                  child: Text('+\$${amount.toStringAsFixed(0)}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = currentUser?.role == UserRole.conductor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            tooltip: 'Editar Perfil',
            icon: const Icon(Icons.edit),
            onPressed: _openEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF003B5C),
              child: Text(
                currentUser?.name.isNotEmpty == true ? currentUser!.name.substring(0, 1).toUpperCase() : 'U',
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(currentUser?.name ?? 'Usuario', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(currentUser?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                isDriver ? 'Rol: Conductor' : 'Rol: Anfitrión / Dueño',
                style: const TextStyle(color: Colors.white, fontSize: 10.5),
              ),
              backgroundColor: isDriver ? Colors.teal : const Color(0xFF003B5C),
            ),
            const Divider(height: 24),
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Teléfono de Contacto', style: TextStyle(fontSize: 12.5)),
              subtitle: Text(currentUser?.phone ?? 'Sin registrar', style: const TextStyle(fontSize: 11.5)),
            ),
            if (isDriver)
              ListTile(
                dense: true,
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Placas Predeterminadas', style: TextStyle(fontSize: 12.5)),
                subtitle: Text(currentUser?.defaultPlate ?? 'Sin registrar', style: const TextStyle(fontSize: 11.5)),
              ),

            // Tarjeta de Billetera U-Parking
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF003B5C), size: 30),
                title: Text(isDriver ? 'Billetera U-Parking' : 'Balance de Ganancias', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '\$${currentUser?.walletBalance.toStringAsFixed(2) ?? "0.00"} MXN disponibles',
                  style: const TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold),
                ),
                trailing: isDriver
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B5C)),
                        onPressed: _openRechargeWalletDialog,
                        child: const Text('Recargar', style: TextStyle(color: Colors.white, fontSize: 11)),
                      )
                    : null,
              ),
            ),

            const Divider(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar Datos del Perfil'),
              onPressed: _openEditProfileDialog,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Cerrar Sesión / Cambiar de Rol'),
              onPressed: () {
                currentUser = null;
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}