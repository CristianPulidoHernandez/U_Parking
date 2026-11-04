import 'package:flutter/material.dart';

void main() {
  runApp(const UParkingApp());
}

// ============================================================================
// 1. MODELOS DE DATOS
// ============================================================================

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
  efectivo,
  spei,
  tarjeta,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.efectivo:
        return 'Efectivo al anfitrión';
      case PaymentMethod.spei:
        return 'Transferencia SPEI / CoDi';
      case PaymentMethod.tarjeta:
        return 'Tarjeta Débito/Crédito';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.efectivo:
        return Icons.payments_outlined;
      case PaymentMethod.spei:
        return Icons.account_balance_outlined;
      case PaymentMethod.tarjeta:
        return Icons.credit_card;
    }
  }
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
  final String name;
  final String phone;
  final double rating;
  final String avatarUrl;

  HostProfile({
    required this.name,
    required this.phone,
    required this.rating,
    required this.avatarUrl,
  });
}

class DriverProfile {
  final String name;
  final String phone;
  final String plateNumber;

  DriverProfile({
    required this.name,
    required this.phone,
    required this.plateNumber,
  });
}

class ParkingSpot {
  final String id;
  final String title;
  final String address;
  final String zone;
  final double basePricePerHour;
  double rating;
  final List<VehicleCategory> allowedVehicles;
  final String availableHoursLabel;
  final List<PeakHourRange> peakHours;
  final List<String> tags;
  final List<String> images; // Galería con varias fotos
  final HostProfile host;
  final double latitude;
  final double longitude;
  final String howToGetThere;
  final String accessRules;
  final String heightLimit;
  final List<Review> reviews;

  ParkingSpot({
    required this.id,
    required this.title,
    required this.address,
    required this.zone,
    required this.basePricePerHour,
    required this.rating,
    required this.allowedVehicles,
    required this.availableHoursLabel,
    required this.peakHours,
    required this.tags,
    required this.images,
    required this.host,
    required this.latitude,
    required this.longitude,
    required this.howToGetThere,
    required this.accessRules,
    required this.heightLimit,
    required this.reviews,
  });
}

class Reservation {
  final String id;
  final ParkingSpot spot;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double durationHours;
  final double totalAmount;
  final bool hasPeakSurge;
  final VehicleCategory vehicleUsed;
  final DriverProfile driver;
  final PaymentMethod paymentMethod;
  final String status;

  Reservation({
    required this.id,
    required this.spot,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalAmount,
    required this.hasPeakSurge,
    required this.vehicleUsed,
    required this.driver,
    required this.paymentMethod,
    this.status = "Confirmada",
  });
}

// ============================================================================
// 2. ESTADO GLOBAL SIMULADO (Con múltiples fotos por lugar)
// ============================================================================

final List<ParkingSpot> globalSpots = [
  // --- 1. CENTRO HISTÓRICO: 4 PONIENTE ---
  ParkingSpot(
    id: 'up-centro-1',
    title: 'Cochera Casona 4 Poniente (Centro)',
    address: 'Calle 4 Poniente #518, Centro Histórico, Puebla',
    zone: 'Centro Histórico',
    basePricePerHour: 22.0,
    rating: 4.9,
    allowedVehicles: [
      VehicleCategory.sedan,
      VehicleCategory.camioneta,
      VehicleCategory.motoneta,
    ],
    availableHoursLabel: '07:30 - 21:30 (Portón cerrado después de hora)',
    peakHours: [
      PeakHourRange(startDecimal: 13.0, endDecimal: 16.0, label: '13:00 - 16:00 (Afluencia gastronómica)'),
      PeakHourRange(startDecimal: 18.0, endDecimal: 20.5, label: '18:00 - 20:30 (Comercio centro)'),
    ],
    tags: ['Techado Colonial', 'Cámaras', 'Zócalo a 3 calles'],
    images: [
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=700',
    ],
    host: HostProfile(
      name: 'Don Ignacio Ramos',
      phone: '222-211-9080',
      rating: 4.9,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
    ),
    latitude: 19.0465,
    longitude: -98.2012,
    howToGetThere: 'Bajar por Calle 4 Poniente hacia la 5 Norte. Pasando el Templo de Santo Domingo, ubicarás un zaguán verde oscuro colonial número 518 con placa de piedra.',
    accessRules: 'Apagar el motor de inmediato al ingresar. No obstruir el pasillo peatonal interior. Se solicita tocar el interfón con timbre de campana.',
    heightLimit: '2.30 metros',
    reviews: [
      Review(authorName: 'Ana Lucía M.', rating: 5.0, comment: 'Súper céntrico y seguro, dejé mi camioneta y llegué al Zócalo caminando en 4 minutos.', date: 'Ayer'),
      Review(authorName: 'Rodrigo P.', rating: 4.8, comment: 'Lugar techado muy fresco y Don Ignacio es muy atento.', date: 'Hace 3 días'),
    ],
  ),

  // --- 2. CENTRO HISTÓRICO: LOS SAPOS & ANALCO ---
  ParkingSpot(
    id: 'up-centro-2',
    title: 'Estación Eco & Motos Los Sapos',
    address: 'Calle 5 Oriente #604, Barrio de los Sapos, Puebla',
    zone: 'Centro Histórico',
    basePricePerHour: 16.0,
    rating: 4.8,
    allowedVehicles: [
      VehicleCategory.bicicleta,
      VehicleCategory.scooter,
      VehicleCategory.motoneta,
      VehicleCategory.motocicleta,
      VehicleCategory.sedan,
    ],
    availableHoursLabel: '08:00 - 23:00 (Acceso libre con código)',
    peakHours: [
      PeakHourRange(startDecimal: 14.0, endDecimal: 17.5, label: '14:00 - 17:30 (Zona de Restaurantes/Cafés)'),
    ],
    tags: ['Especial Bicis/Motos', 'Cámaras 24/7', 'Junto a Cafeterías'],
    images: [
      'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=700',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
    ],
    host: HostProfile(
      name: 'Beatriz Solís',
      phone: '222-456-1122',
      rating: 4.8,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120',
    ),
    latitude: 19.0418,
    longitude: -98.1965,
    howToGetThere: 'Sobre 5 Oriente justo al cruzar la 6 Sur, a 50 metros de la plazuela de Los Sapos, reja negra con letrero de herrería artesanal.',
    accessRules: 'Área delimitada con racks metálicos para anclar bicicletas y motonetas. Traer candado personal en dos ruedas.',
    heightLimit: '2.10 metros',
    reviews: [
      Review(authorName: 'Carlos G.', rating: 4.8, comment: 'Excelente para dejar la motoneta mientras trabajas en los cafés de Los Sapos.', date: 'Hace 5 días'),
    ],
  ),

  // --- 3. ZONA CIUDAD UNIVERSITARIA: SAN CLAUDIO ---
  ParkingSpot(
    id: 'up-cu-1',
    title: 'Cochera Techada San Claudio (Frente a CU)',
    address: 'Av. San Claudio #1402 (Frente a Fac. Computación), Puebla',
    zone: 'Ciudad Universitaria (CU)',
    basePricePerHour: 18.0,
    rating: 4.9,
    allowedVehicles: [
      VehicleCategory.sedan,
      VehicleCategory.camioneta,
      VehicleCategory.motoneta,
      VehicleCategory.motocicleta,
    ],
    availableHoursLabel: '06:45 - 21:15 (Lunes a Sábado)',
    peakHours: [
      PeakHourRange(startDecimal: 7.5, endDecimal: 10.0, label: '07:30 - 10:00 (Entrada a clases matutinas)'),
      PeakHourRange(startDecimal: 13.0, endDecimal: 15.0, label: '13:00 - 15:00 (Cambio de turno)'),
    ],
    tags: ['Techado', 'Portón Eléctrico', 'Cámaras CU'],
    images: [
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=700',
      'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
    ],
    host: HostProfile(
      name: 'Carlos Mendoza',
      phone: '222-345-6789',
      rating: 4.9,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
    ),
    latitude: 19.0025,
    longitude: -98.2014,
    howToGetThere: 'Sobre Av. San Claudio con dirección a 24 Sur, justo frente a la puerta vehicular de la Facultad de Ciencias de la Computación, portón blanco #1402.',
    accessRules: 'Apertura con control que se entrega si estás más de 4 horas o tocando el timbre marcado como "Cochera". Tolerancia de 15 minutos.',
    heightLimit: '2.25 metros',
    reviews: [
      Review(authorName: 'Gabriel S.', rating: 5.0, comment: 'Cruzas la calle y ya estás en la facultad. Muy práctico.', date: 'Hace 2 días'),
      Review(authorName: 'Valeria T.', rating: 4.9, comment: 'Siempre limpio, cerrado con sombra todo el día.', date: 'Hace 1 semana'),
    ],
  ),

  // --- 4. ZONA CIUDAD UNIVERSITARIA: SAN MANUEL ---
  ParkingSpot(
    id: 'up-cu-2',
    title: 'Estación Eco-Movilidad San Manuel',
    address: 'Calle 18 Sur #2105, Col. San Manuel, Puebla',
    zone: 'Ciudad Universitaria (CU)',
    basePricePerHour: 8.0,
    rating: 4.8,
    allowedVehicles: [
      VehicleCategory.bicicleta,
      VehicleCategory.scooter,
      VehicleCategory.motoneta,
    ],
    availableHoursLabel: '06:30 - 22:00 (Vigilante permanente)',
    peakHours: [
      PeakHourRange(startDecimal: 8.0, endDecimal: 11.0, label: '08:00 - 11:00 (Pico matutino)'),
    ],
    tags: ['Toma Eléctrica', 'Candado Anclado', 'Vigilante'],
    images: [
      'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
      'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=700',
      'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?w=700',
    ],
    host: HostProfile(
      name: 'Mariana Flores',
      phone: '222-987-6543',
      rating: 4.8,
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120',
    ),
    latitude: 19.0068,
    longitude: -98.2045,
    howToGetThere: 'Desde Circuito Juan Pablo II ingresar a 18 Sur hacia CU, 2 calles antes de San Claudio a mano derecha, reja blanca con lona azul.',
    accessRules: 'Carga gratuita para scooters y bicis eléctricas incluida en la tarifa. Presentar identificación al ingresar.',
    heightLimit: 'Sin límite',
    reviews: [
      Review(authorName: 'Esteban H.', rating: 4.8, comment: 'Cargué mi scooter durante mis clases, súper útil y económico.', date: 'Hace 4 días'),
    ],
  ),
];

final List<Reservation> globalReservations = [];

// ============================================================================
// 3. APLICACIÓN PRINCIPAL
// ============================================================================

class UParkingApp extends StatelessWidget {
  const UParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U-Parking Puebla',
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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTabIndex = 0;

  void _onSpotCreated() {
    setState(() {
      _currentTabIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const ExplorePage(),
      PublishSpotPage(onSpotCreated: _onSpotCreated),
      const MyReservationsPage(),
    ];

    return Scaffold(
      body: pages[_currentTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Color(0xFF003B5C)),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_business_outlined),
            selectedIcon: Icon(Icons.add_business, color: Color(0xFF003B5C)),
            label: 'Publicar Cochera',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark, color: Color(0xFF003B5C)),
            label: 'Mis Reservas',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. PANTALLA: EXPLORAR ESTACIONAMIENTOS
// ============================================================================

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
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
            Icon(Icons.local_parking, size: 28),
            SizedBox(width: 8),
            Text('U-Parking Puebla', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de Zona
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.blue.shade50.withOpacity(0.4),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, size: 20, color: Color(0xFF003B5C)),
                const SizedBox(width: 8),
                const Text('Zona:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todas', 'Centro Histórico', 'Ciudad Universitaria (CU)'].map((zone) {
                        final isSelected = _selectedZone == zone;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(zone, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: const Color(0xFF003B5C),
                            onSelected: (_) => setState(() => _selectedZone = zone),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtros de Vehículos
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _filterCategory == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterCategory = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...VehicleCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        avatar: Icon(cat.icon, size: 16),
                        label: Text(cat.label, style: const TextStyle(fontSize: 12)),
                        selected: _filterCategory == cat,
                        onSelected: (selected) {
                          setState(() {
                            _filterCategory = selected ? cat : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Lista de cocheras
          Expanded(
            child: filteredSpots.isEmpty
                ? const Center(
                    child: Text('No hay estacionamientos disponibles con estos filtros.'),
                  )
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2.5,
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
                    spot.images.first,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.garage, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003B5C).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      spot.zone,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${spot.images.length} fotos',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
                        child: Text(
                          spot.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(' ${spot.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(' (${spot.reviews.length})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.address,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Horario de disposición en la tarjeta
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 15, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Horario: ${spot.availableHoursLabel}',
                          style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Vehículos aceptados y tarifa base
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: spot.allowedVehicles.map((v) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Tooltip(
                              message: v.label,
                              child: CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFF003B5C).withOpacity(0.1),
                                child: Icon(v.icon, size: 15, color: const Color(0xFF003B5C)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${spot.basePricePerHour.toStringAsFixed(2)} MXN',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          const Text('por hora base', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
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
// 5. PANTALLA: DETALLE (Carrusel de Fotos, Horario, Vehículos y Cómo Llegar)
// ============================================================================

class SpotDetailPage extends StatefulWidget {
  final ParkingSpot spot;
  const SpotDetailPage({super.key, required this.spot});

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  late VehicleCategory _selectedVehicle;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  int _currentPhotoIndex = 0;

  final _driverNameCtrl = TextEditingController(text: 'Estudiante BUAP');
  final _driverPhoneCtrl = TextEditingController(text: '222-765-4321');
  final _driverPlateCtrl = TextEditingController(text: 'UAP-102-B');

  final _newReviewCommentCtrl = TextEditingController();
  double _newReviewRating = 5.0;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.spot.allowedVehicles.first;
  }

  bool _checkIsPeak(TimeOfDay start, TimeOfDay end) {
    double s = start.hour + (start.minute / 60.0);
    double e = end.hour + (end.minute / 60.0);

    for (var peak in widget.spot.peakHours) {
      if (s < peak.endDecimal && e > peak.startDecimal) {
        return true;
      }
    }
    return false;
  }

  double _calculateDuration() {
    double start = _startTime.hour + (_startTime.minute / 60.0);
    double end = _endTime.hour + (_endTime.minute / 60.0);
    double diff = end - start;
    return diff > 0 ? diff : (diff + 24);
  }

  double _calculateTotal(double duration, bool isPeak) {
    double base = widget.spot.basePricePerHour * duration;
    return isPeak ? (base * 1.25) : base;
  }

  Future<void> _selectTime(bool isStart) async {
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
                  const Text('Tu calificación general:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 2, 3, 4, 5].map((star) {
                      return IconButton(
                        icon: Icon(
                          star <= _newReviewRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => _newReviewRating = star.toDouble());
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newReviewCommentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '¿Cómo fue tu experiencia?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003B5C)),
                  onPressed: () {
                    if (_newReviewCommentCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        widget.spot.reviews.insert(
                          0,
                          Review(
                            authorName: 'Usuario U-Parking',
                            rating: _newReviewRating,
                            comment: _newReviewCommentCtrl.text.trim(),
                            date: 'Hoy',
                          ),
                        );
                        double sum = widget.spot.reviews.fold(0, (prev, r) => prev + r.rating);
                        widget.spot.rating = sum / widget.spot.reviews.length;
                      });
                      _newReviewCommentCtrl.clear();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Reseña publicada!')),
                      );
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

  void _showBookingSheet() {
    final duration = _calculateDuration();
    final isPeak = _checkIsPeak(_startTime, _endTime);
    final total = _calculateTotal(duration, isPeak);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Confirmar Reserva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Verifica tus datos y método de pago con el anfitrión.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _driverNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del Conductor', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _driverPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _driverPlateCtrl,
                      decoration: const InputDecoration(labelText: 'Placas o serie del vehículo / Marca bicicleta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Método de pago al llegar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...PaymentMethod.values.map((method) {
                      return RadioListTile<PaymentMethod>(
                        value: method,
                        groupValue: _selectedPayment,
                        dense: true,
                        secondary: Icon(method.icon, color: const Color(0xFF003B5C)),
                        title: Text(method.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => _selectedPayment = val);
                            setState(() => _selectedPayment = val);
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total (${duration.toStringAsFixed(1)} hrs):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (isPeak)
                                const Text('⚡ Incluye tarifa de hora pico', style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text('\$${total.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF003B5C))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF003B5C),
                      ),
                      onPressed: () {
                        final reservation = Reservation(
                          id: 'res-${DateTime.now().millisecondsSinceEpoch}',
                          spot: widget.spot,
                          startTime: _startTime,
                          endTime: _endTime,
                          durationHours: duration,
                          totalAmount: total,
                          hasPeakSurge: isPeak,
                          vehicleUsed: _selectedVehicle,
                          paymentMethod: _selectedPayment,
                          driver: DriverProfile(
                            name: _driverNameCtrl.text.trim(),
                            phone: _driverPhoneCtrl.text.trim(),
                            plateNumber: _driverPlateCtrl.text.trim(),
                          ),
                        );

                        globalReservations.insert(0, reservation);
                        Navigator.pop(sheetContext);

                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('¡Reserva Confirmada!'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lugar: ${widget.spot.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Vehículo: ${_selectedVehicle.label}'),
                                Text('Anfitrión: ${widget.spot.host.name} (${widget.spot.host.phone})'),
                                Text('Método de Pago: ${_selectedPayment.label}'),
                                const Divider(),
                                Text('Total a pagar: \$${total.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003B5C))),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dCtx);
                                  Navigator.pop(context);
                                },
                                child: const Text('Aceptar'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Confirmar y Apartar', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration();
    final isPeak = _checkIsPeak(_startTime, _endTime);
    final total = _calculateTotal(duration, isPeak);

    return Scaffold(
      appBar: AppBar(title: Text(widget.spot.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARRUSEL INTERACTIVO DE FOTOS
            Stack(
              children: [
                SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: widget.spot.images.length,
                    onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                    itemBuilder: (context, i) {
                      return Image.network(
                        widget.spot.images[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.garage, size: 60, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      'Foto ${_currentPhotoIndex + 1} de ${widget.spot.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF003B5C), borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.spot.zone, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(' ${widget.spot.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(' (${widget.spot.reviews.length} reseñas)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.spot.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.spot.address, style: TextStyle(color: Colors.grey.shade700))),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // BLOQUE DE HORARIO DE DISPOSICIÓN
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock, color: Color(0xFF003B5C), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Horario de servicio y disposición:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF003B5C))),
                              Text(widget.spot.availableHoursLabel, style: TextStyle(fontSize: 13, color: Colors.grey.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BLOQUE DE VEHÍCULOS ACEPTADOS
                  const Text('Vehículos permitidos en esta cochera:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.spot.allowedVehicles.map((v) {
                      return Chip(
                        avatar: Icon(v.icon, size: 18, color: const Color(0xFF003B5C)),
                        label: Text(v.label, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // ANFITRIÓN
                  Card(
                    elevation: 1,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 26, backgroundImage: NetworkImage(widget.spot.host.avatarUrl)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.spot.host.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Anfitrión • ${widget.spot.host.rating} ★', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                Text('Tel: ${widget.spot.host.phone}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.phone),
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

                  const SizedBox(height: 16),

                  // DESCRIPCIÓN DETALLADA DE CÓMO LLEGAR
                  const Text('Ubicación y Cómo Llegar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alt_route, color: Color(0xFF003B5C), size: 20),
                            const SizedBox(width: 8),
                            const Text('Indicaciones viales precisas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Maps', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Abriendo Maps en Puebla: ${widget.spot.latitude}, ${widget.spot.longitude}')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.spot.howToGetThere, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // REGLAS Y ALTURA
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Altura máx:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                              Text(widget.spot.heightLimit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reglas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                              Text(widget.spot.accessRules, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // CONFIGURACIÓN DE TU VEHÍCULO Y HORARIO DE RESERVA
                  const Text('Configurar tu Estancia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('¿En cuál de tus vehículos llegarás?:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: widget.spot.allowedVehicles.map((cat) {
                      final isSelected = _selectedVehicle == cat;
                      return ChoiceChip(
                        avatar: Icon(cat.icon, size: 18, color: isSelected ? Colors.white : Colors.black87),
                        label: Text(cat.label),
                        selected: isSelected,
                        selectedColor: const Color(0xFF003B5C),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          if (val) setState(() => _selectedVehicle = cat);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                  const Text('Horario requerido:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(true),
                          icon: const Icon(Icons.login),
                          label: Text('De: ${_startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectTime(false),
                          icon: const Icon(Icons.logout),
                          label: Text('A: ${_endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),

                  if (isPeak) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Horario de alta demanda en este estacionamiento (+25% aplicado).',
                              style: TextStyle(color: Colors.deepOrange, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 32),

                  // SECCIÓN DE RESEÑAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reseñas (${widget.spot.reviews.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Calificar'),
                        onPressed: _openAddReviewDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...widget.spot.reviews.map((r) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0.5,
                      color: Colors.grey.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    Text(' ${r.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(' • ${r.date}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(r.comment, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, -3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total (${duration.toStringAsFixed(1)} hrs):', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '\$${total.toStringAsFixed(2)} MXN',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003B5C)),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B5C),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _showBookingSheet,
              child: const Text('Apartar Lugar', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. PANTALLA: REGISTRAR COCHERA (Con Fotos, Vehículos y Horarios)
// ============================================================================

class PublishSpotPage extends StatefulWidget {
  final VoidCallback onSpotCreated;
  const PublishSpotPage({super.key, required this.onSpotCreated});

  @override
  State<PublishSpotPage> createState() => _PublishSpotPageState();
}

class _PublishSpotPageState extends State<PublishSpotPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _directionsCtrl = TextEditingController();
  final _scheduleHoursCtrl = TextEditingController(text: '07:00 - 21:00 (Lunes a Viernes)');
  final _photoUrlCtrl = TextEditingController();
  final _hostNameCtrl = TextEditingController(text: 'Dueño Particular');
  final _hostPhoneCtrl = TextEditingController(text: '222-123-4567');

  String _zone = 'Centro Histórico';
  final List<VehicleCategory> _allowedVehicles = [VehicleCategory.sedan, VehicleCategory.camioneta];

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_allowedVehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos un tipo de vehículo permitido.')),
        );
        return;
      }

      // Si el anfitrión no ingresó URL de foto, usamos un set por defecto
      final List<String> spotPhotos = _photoUrlCtrl.text.trim().isNotEmpty
          ? [_photoUrlCtrl.text.trim(), 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700']
          : [
              'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=700',
              'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=700',
            ];

      final newSpot = ParkingSpot(
        id: 'up-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        zone: _zone,
        basePricePerHour: double.parse(_priceCtrl.text.trim()),
        rating: 5.0,
        allowedVehicles: List.from(_allowedVehicles),
        availableHoursLabel: _scheduleHoursCtrl.text.trim(),
        peakHours: [
          PeakHourRange(startDecimal: 13.0, endDecimal: 15.5, label: '13:00 - 15:30 (Hora de comida y comercio)'),
        ],
        tags: ['Espacio Privado', 'Nuevo'],
        images: spotPhotos,
        host: HostProfile(
          name: _hostNameCtrl.text.trim(),
          phone: _hostPhoneCtrl.text.trim(),
          rating: 5.0,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        ),
        latitude: 19.0435,
        longitude: -98.2000,
        howToGetThere: _directionsCtrl.text.trim().isEmpty ? 'Tocar timbre al llegar al portón principal.' : _directionsCtrl.text.trim(),
        accessRules: 'Respetar el espacio delimitado y no dejar objetos en pasillos.',
        heightLimit: '2.20 metros',
        reviews: [],
      );

      globalSpots.insert(0, newSpot);
      widget.onSpotCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cochera publicada con fotos y horarios!'), backgroundColor: Colors.teal),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Cochera')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Datos del Anfitrión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hostNameCtrl,
                decoration: const InputDecoration(labelText: 'Tu nombre completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hostPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),

              const Divider(height: 28),

              const Text('2. Datos de la Cochera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _zone,
                decoration: const InputDecoration(labelText: 'Zona en Puebla', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                items: const [
                  DropdownMenuItem(value: 'Centro Histórico', child: Text('Centro Histórico de Puebla')),
                  DropdownMenuItem(value: 'Ciudad Universitaria (CU)', child: Text('Ciudad Universitaria (CU) / San Manuel')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _zone = val);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título del espacio', hintText: 'Ej. Cochera Techada en 4 Poniente', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Dirección completa', hintText: 'Ej. Calle 4 Poniente #518', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tarifa base (\$ MXN / hora)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),

              const Divider(height: 28),

              const Text('3. Horario de Disposición y Fotos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _scheduleHoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Horario en que está disponible el lugar',
                  hintText: 'Ej. 07:00 a 21:00 (Lunes a Viernes)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                validator: (v) => v!.isEmpty ? 'Ingresa el horario de apertura y cierre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _photoUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de foto de tu cochera (opcional)',
                  hintText: 'https://ejemplo.com/micochera.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_photo_alternate_outlined),
                ),
              ),

              const Divider(height: 28),

              const Text('4. Vehículos que aceptas en tu cochera:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: VehicleCategory.values.map((cat) {
                  final checked = _allowedVehicles.contains(cat);
                  return FilterChip(
                    avatar: Icon(cat.icon, size: 16),
                    label: Text(cat.label),
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

              const Divider(height: 28),

              const Text('5. Instrucciones de Cómo Llegar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _directionsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Referencias viales y fachadas',
                  hintText: 'Ej. Bajando por la 4 Poniente, casa de zaguán verde frente al restaurante...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alt_route),
                ),
              ),

              const SizedBox(height: 22),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF003B5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                label: const Text('Publicar Cochera', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. PANTALLA: MIS RESERVAS
// ============================================================================

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: globalReservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No tienes reservaciones activas', style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: globalReservations.length,
              itemBuilder: (context, index) {
                final r = globalReservations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.spot.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            Chip(
                              label: Text(r.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        Text(r.spot.address, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(r.paymentMethod.icon, size: 16, color: const Color(0xFF003B5C)),
                                const SizedBox(width: 4),
                                Text(r.paymentMethod.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              '${r.startTime.format(context)} → ${r.endTime.format(context)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.hasPeakSurge ? '⚡ Tarifa dinámica (Alta demanda)' : 'Horario regular',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: r.hasPeakSurge ? Colors.deepOrange : Colors.grey.shade600,
                                fontWeight: r.hasPeakSurge ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              'Total: \$${r.totalAmount.toStringAsFixed(2)} MXN',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF003B5C)),
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