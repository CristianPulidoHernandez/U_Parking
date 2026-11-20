// =============================================================================
// U-PARKING · Renta colaborativa de estacionamientos y cocheras en Puebla, MX
// -----------------------------------------------------------------------------
// Archivo único: lib/main.dart
// Dependencias: Flutter SDK + image_picker (subir fotos desde el dispositivo).
//
// Estructura:
//   1. Constantes y utilidades
//   2. Modelos de datos y enumeraciones
//   3. Estado global (AppState) + InheritedNotifier (AppScope)
//   4. Marco de smartphone para Web, tema y raíz de la app
//   5. Widgets reutilizables
//   6. Autenticación y selección de rol
//   7. Rol CONDUCTOR (explorar, detalle/apartado, mis citas)
//   8. Rol ANFITRIÓN (panel, formulario de cochera, reservas)
//   9. Perfil y billetera (compartido)
//
// Cuentas demo (contraseña 1234): conductor@uparking.mx, ignacio@uparking.mx,
// beatriz@uparking.mx, carlos@uparking.mx
//
// Notas:
//  - Las fotos usan URLs de ejemplo; si una no carga se muestra un marcador.
//  - La llamada al anfitrión es simulada (sin url_launcher).
//  - Los selectores de fecha/hora usan textos en español sin
//    flutter_localizations (no se agregan dependencias).
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const UParkingApp());

// ═════════════════════════════════════════════════════════════════════════════
// 1. CONSTANTES Y UTILIDADES
// ═════════════════════════════════════════════════════════════════════════════

const Color kNavy = Color(0xFF003B5C); // Azul Marino institucional (primario)
const Color kTeal = Color(0xFF00B4D8); // Azul Turquesa (precios/disponibilidad)
const Color kTealDark = Color(0xFF00798F); // Variante legible para texto
const Color kAlert = Colors.deepOrange; // Alta demanda / alertas
const Color kBg = Color(0xFFF2F5F8);
const Color kLine = Color(0xFFDDE3E9);

/// Recargo aplicado cuando el horario cruza una hora pico.
const double kPeakSurcharge = 0.25;

const String kAllZones = 'Todas';
const String kZoneCentro = 'Centro Histórico';
const String kZoneCU = 'Ciudad Universitaria (CU)';
const List<String> kSpotZones = [kZoneCentro, kZoneCU];
const List<String> kFilterZones = [kAllZones, kZoneCentro, kZoneCU];

/// Aclara un color con una opacidad (sin usar APIs deprecadas).
Color tint(Color c, double opacity) => c.withAlpha((opacity * 255).round());

String two(int n) => n.toString().padLeft(2, '0');

/// Minutos desde medianoche -> "HH:mm".
String fmtTime(int minutes) => '${two(minutes ~/ 60)}:${two(minutes % 60)}';

String fmtMoney(double v) => '\$${v.toStringAsFixed(2)}';

String trimNum(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

String fmtRate(double v) => '\$${trimNum(v)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const List<String> _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const List<String> _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtDateLong(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

int clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

String initialsOf(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : kNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

OutlineInputBorder _border(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

InputDecoration inputDeco(String label,
    {IconData? icon, String? hint, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: _border(kLine),
    enabledBorder: _border(kLine),
    focusedBorder: _border(kNavy, 1.6),
    errorBorder: _border(Colors.red.shade600),
    focusedErrorBorder: _border(Colors.red.shade600, 1.6),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. MODELOS Y ENUMERACIONES
// ═════════════════════════════════════════════════════════════════════════════

enum UserRole {
  conductor('Conductor', Icons.directions_car_filled),
  anfitrion('Anfitrión', Icons.home_work);

  const UserRole(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum VehicleCategory {
  bicicleta('Bicicleta', Icons.pedal_bike),
  scooter('Scooter eléctrico', Icons.electric_scooter),
  motoneta('Motoneta', Icons.moped),
  motocicleta('Motocicleta', Icons.two_wheeler),
  sedan('Sedán / Compacto', Icons.directions_car),
  camioneta('Camioneta / SUV', Icons.airport_shuttle);

  const VehicleCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum PaymentMethod {
  wallet('Billetera U-Parking (Saldo prepagado)', Icons.account_balance_wallet),
  cash('Efectivo en cochera', Icons.payments),
  spei('Transferencia SPEI / CoDi', Icons.qr_code_2),
  card('Tarjeta Débito/Crédito', Icons.credit_card);

  const PaymentMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ReservationStatus { activa, cancelada }

/// Rango horario expresado en minutos desde medianoche.
class TimeRange {
  const TimeRange(this.start, this.end);
  final int start;
  final int end;

  String get label => '${fmtTime(start)} – ${fmtTime(end)}';

  bool overlaps(int s, int e) => s < end && e > start;
}

class Review {
  Review({
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });
  final String author;
  final int rating;
  final String comment;
  final DateTime date;
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.plate = '',
    this.balance = 0,
  });
  final String id;
  String name;
  final String email;
  String phone;
  final String password;
  final UserRole role;
  String plate;
  double balance;
}

class ParkingSpot {
  ParkingSpot({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.address,
    required this.zone,
    required this.baseRate,
    required this.totalSlots,
    required this.freeSlots,
    required this.openMin,
    required this.closeMin,
    required this.hostName,
    required this.hostPhone,
    required this.hostPhotoUrl,
    required this.hostRating,
    required this.hostVerified,
    required this.vehicles,
    required this.photos,
    required this.maxHeight,
    required this.maxLength,
    required this.restrictions,
    required this.peakHours,
    List<Review>? reviews,
  }) : reviews = reviews ?? <Review>[];

  final String id;
  final String ownerId;
  String title;
  String address;
  String zone;
  double baseRate;
  int totalSlots;
  int freeSlots;
  int openMin;
  int closeMin;
  String hostName;
  String hostPhone;
  String hostPhotoUrl;
  double hostRating;
  bool hostVerified;
  Set<VehicleCategory> vehicles;
  List<String> photos;
  double maxHeight;
  double maxLength;
  String restrictions; // Una restricción por línea.
  List<TimeRange> peakHours;
  final List<Review> reviews;

  double get rating => reviews.isEmpty
      ? 0
      : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;

  String get scheduleLabel => '${fmtTime(openMin)} – ${fmtTime(closeMin)}';

  List<String> get restrictionList => restrictions
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool isPeak(int s, int e) => peakHours.any((p) => p.overlaps(s, e));

  bool isPeakNow() {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    return peakHours.any((p) => m >= p.start && m < p.end);
  }

  /// Total con recargo automático del +25% si el horario cruza una hora pico.
  double totalFor(int s, int e) {
    final hours = (e - s) / 60;
    final mult = isPeak(s, e) ? 1 + kPeakSurcharge : 1.0;
    return ((baseRate * hours * mult) * 100).round() / 100;
  }
}

class Reservation {
  Reservation({
    required this.code,
    required this.spotId,
    required this.spotTitle,
    required this.spotAddress,
    required this.hostId,
    required this.hostName,
    required this.hostPhone,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.plate,
    required this.vehicle,
    required this.date,
    required this.startMin,
    required this.endMin,
    required this.total,
    required this.surcharge,
    required this.payment,
    this.status = ReservationStatus.activa,
  });
  final String code;
  final String spotId;
  final String spotTitle;
  final String spotAddress;
  final String hostId;
  final String hostName;
  final String hostPhone;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String plate;
  final VehicleCategory vehicle;
  final DateTime date;
  final int startMin;
  final int endMin;
  final double total;
  final bool surcharge;
  final PaymentMethod payment;
  ReservationStatus status;
}

class BookingResult {
  BookingResult.ok(this.reservation) : error = null;
  BookingResult.fail(this.error) : reservation = null;
  final Reservation? reservation;
  final String? error;
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. ESTADO GLOBAL
// ═════════════════════════════════════════════════════════════════════════════

class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  final List<AppUser> users = <AppUser>[];
  final List<ParkingSpot> spots = <ParkingSpot>[];
  final List<Reservation> reservations = <Reservation>[];
  AppUser? currentUser;

  int _reservationCounter = 1002;
  int _spotCounter = 3;
  int _userCounter = 100;

  // ── Datos precargados (Puebla) ────────────────────────────────────────────
  void _seed() {
    users.addAll([
      AppUser(
        id: 'u1',
        name: 'Alejandra Torres',
        email: 'conductor@uparking.mx',
        phone: '2225550100',
        password: '1234',
        role: UserRole.conductor,
        plate: 'ABC-123-A',
        balance: 250,
      ),
      AppUser(
        id: 'h1',
        name: 'Don Ignacio Ramos',
        email: 'ignacio@uparking.mx',
        phone: '2225550141',
        password: '1234',
        role: UserRole.anfitrion,
      ),
      AppUser(
        id: 'h2',
        name: 'Beatriz Solís',
        email: 'beatriz@uparking.mx',
        phone: '2225550162',
        password: '1234',
        role: UserRole.anfitrion,
      ),
      AppUser(
        id: 'h3',
        name: 'Carlos Mendoza',
        email: 'carlos@uparking.mx',
        phone: '2225550183',
        password: '1234',
        role: UserRole.anfitrion,
      ),
    ]);

    spots.addAll([
      ParkingSpot(
        id: 's1',
        ownerId: 'h1',
        title: 'Cochera Casona 4 Poniente (Centro)',
        address: 'Calle 4 Poniente #305, Centro Histórico, 72000 Puebla, Pue.',
        zone: kZoneCentro,
        baseRate: 22,
        totalSlots: 4,
        freeSlots: 2,
        openMin: 7 * 60,
        closeMin: 22 * 60,
        hostName: 'Don Ignacio Ramos',
        hostPhone: '2225550141',
        hostPhotoUrl: 'https://i.pravatar.cc/150?img=12',
        hostRating: 4.8,
        hostVerified: true,
        vehicles: <VehicleCategory>{
          VehicleCategory.bicicleta,
          VehicleCategory.motoneta,
          VehicleCategory.motocicleta,
          VehicleCategory.sedan,
        },
        photos: [
          'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?auto=format&fit=crop&w=900&q=70',
        ],
        maxHeight: 2.10,
        maxLength: 4.80,
        restrictions:
            'Sin fugas de aceite\nNo se admiten remolques\nPortón angosto: pliega los espejos',
        peakHours: const [TimeRange(8 * 60, 10 * 60), TimeRange(17 * 60, 19 * 60)],
        reviews: [
          Review(
            author: 'Mariana L.',
            rating: 5,
            comment:
                'Casona muy bien cuidada y Don Ignacio ayuda a maniobrar. A 5 minutos del Zócalo.',
            date: DateTime(2026, 10, 28),
          ),
          Review(
            author: 'Jorge P.',
            rating: 4,
            comment: 'La entrada es algo angosta, pero es seguro y está limpio.',
            date: DateTime(2026, 10, 12),
          ),
          Review(
            author: 'Sofía R.',
            rating: 5,
            comment: 'Excelente trato y precio justo para el Centro.',
            date: DateTime(2026, 9, 30),
          ),
        ],
      ),
      ParkingSpot(
        id: 's2',
        ownerId: 'h2',
        title: 'Estación Eco & Motos Los Sapos',
        address: 'Calle 5 Oriente #604, Barrio de Los Sapos, Centro Histórico, Puebla',
        zone: kZoneCentro,
        baseRate: 16,
        totalSlots: 8,
        freeSlots: 5,
        openMin: 8 * 60,
        closeMin: 21 * 60,
        hostName: 'Beatriz Solís',
        hostPhone: '2225550162',
        hostPhotoUrl: 'https://i.pravatar.cc/150?img=47',
        hostRating: 4.9,
        hostVerified: true,
        vehicles: <VehicleCategory>{
          VehicleCategory.bicicleta,
          VehicleCategory.scooter,
          VehicleCategory.motoneta,
          VehicleCategory.motocicleta,
          VehicleCategory.sedan,
        },
        photos: [
          'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1449426468159-d96dbf08f19f?auto=format&fit=crop&w=900&q=70',
        ],
        maxHeight: 2.00,
        maxLength: 4.20,
        restrictions:
            'Solo sedanes compactos (máx. 4.20 m)\nBicicletas con candado propio\nLa carga de scooters no está incluida',
        peakHours: const [TimeRange(13 * 60, 15 * 60), TimeRange(18 * 60, 20 * 60)],
        reviews: [
          Review(
            author: 'Daniela V.',
            rating: 5,
            comment: 'Perfecto para dejar mi scooter mientras recorro Los Sapos.',
            date: DateTime(2026, 11, 2),
          ),
          Review(
            author: 'Luis H.',
            rating: 4,
            comment: 'Buen lugar y Beatriz es muy amable. Hay poco espacio para autos.',
            date: DateTime(2026, 10, 19),
          ),
        ],
      ),
      ParkingSpot(
        id: 's3',
        ownerId: 'h3',
        title: 'Cochera Techada San Claudio (Frente a CU)',
        address:
            'Calle San Claudio, frente a la Facultad de Ciencias de la Computación, Ciudad Universitaria, Puebla',
        zone: kZoneCU,
        baseRate: 18,
        totalSlots: 10,
        freeSlots: 6,
        openMin: 6 * 60 + 30,
        closeMin: 22 * 60,
        hostName: 'Carlos Mendoza',
        hostPhone: '2225550183',
        hostPhotoUrl: 'https://i.pravatar.cc/150?img=33',
        hostRating: 4.7,
        hostVerified: true,
        vehicles: <VehicleCategory>{
          VehicleCategory.bicicleta,
          VehicleCategory.scooter,
          VehicleCategory.motoneta,
          VehicleCategory.motocicleta,
          VehicleCategory.sedan,
          VehicleCategory.camioneta,
        },
        photos: [
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1621929747188-0b4dc28498d2?auto=format&fit=crop&w=900&q=70',
          'https://images.unsplash.com/photo-1604063155785-ee2fa9a89c45?auto=format&fit=crop&w=900&q=70',
        ],
        maxHeight: 2.20,
        maxLength: 5.20,
        restrictions: 'Sin fugas de aceite\nSin remolques\nNo se permite pernocta',
        peakHours: const [TimeRange(7 * 60 + 30, 10 * 60), TimeRange(12 * 60 + 30, 15 * 60)],
        reviews: [
          Review(
            author: 'Kevin A.',
            rating: 5,
            comment: 'Techada y justo enfrente de la facultad. Ideal para días de lluvia.',
            date: DateTime(2026, 11, 5),
          ),
          Review(
            author: 'Paola M.',
            rating: 4,
            comment: 'Se llena rápido antes de las 9, conviene llegar temprano.',
            date: DateTime(2026, 10, 21),
          ),
          Review(
            author: 'Andrés C.',
            rating: 5,
            comment: 'Muy seguro y Carlos siempre responde por WhatsApp.',
            date: DateTime(2026, 10, 3),
          ),
        ],
      ),
    ]);

    reservations.add(
      Reservation(
        code: 'UP-1001',
        spotId: 's1',
        spotTitle: 'Cochera Casona 4 Poniente (Centro)',
        spotAddress: 'Calle 4 Poniente #305, Centro Histórico, 72000 Puebla, Pue.',
        hostId: 'h1',
        hostName: 'Don Ignacio Ramos',
        hostPhone: '2225550141',
        driverId: 'u1',
        driverName: 'Alejandra Torres',
        driverPhone: '2225550100',
        plate: 'ABC-123-A',
        vehicle: VehicleCategory.sedan,
        date: dateOnly(DateTime.now()),
        startMin: 10 * 60,
        endMin: 12 * 60,
        total: 44,
        surcharge: false,
        payment: PaymentMethod.cash,
      ),
    );
  }

  // ── Sesión ────────────────────────────────────────────────────────────────
  String? login({
    required String email,
    required String password,
    required UserRole role,
  }) {
    final mail = email.trim().toLowerCase();
    AppUser? found;
    for (final u in users) {
      if (u.email == mail) {
        found = u;
        break;
      }
    }
    if (found == null || found.password != password) {
      return 'Correo o contraseña incorrectos.';
    }
    if (found.role != role) {
      return 'Esta cuenta está registrada como ${found.role.label}. Selecciona ese rol para entrar.';
    }
    currentUser = found;
    notifyListeners();
    return null;
  }

  String? register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) {
    final mail = email.trim().toLowerCase();
    if (users.any((u) => u.email == mail)) {
      return 'Ya existe una cuenta con ese correo.';
    }
    final user = AppUser(
      id: 'u${_userCounter++}',
      name: name.trim(),
      email: mail,
      phone: phone.trim(),
      password: password,
      role: role,
      balance: role == UserRole.conductor ? 150 : 0, // Bono de bienvenida demo
    );
    users.add(user);
    currentUser = user;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ── Consultas ─────────────────────────────────────────────────────────────
  ParkingSpot? spotById(String id) {
    for (final s in spots) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<ParkingSpot> get hostSpots {
    final u = currentUser;
    if (u == null) return <ParkingSpot>[];
    return spots.where((s) => s.ownerId == u.id).toList();
  }

  List<Reservation> get driverReservations {
    final u = currentUser;
    if (u == null) return <Reservation>[];
    return reservations.where((r) => r.driverId == u.id).toList();
  }

  List<Reservation> get hostReservations {
    final u = currentUser;
    if (u == null) return <Reservation>[];
    return reservations.where((r) => r.hostId == u.id).toList();
  }

  double get hostIncome => hostReservations
      .where((r) => r.status == ReservationStatus.activa)
      .fold<double>(0, (sum, r) => sum + r.total);

  // ── Perfil y billetera ────────────────────────────────────────────────────
  void updateProfile({
    required String name,
    required String phone,
    String? plate,
  }) {
    final u = currentUser;
    if (u == null) return;
    u.name = name.trim();
    u.phone = phone.trim();
    if (plate != null) u.plate = plate.trim().toUpperCase();
    if (u.role == UserRole.anfitrion) {
      for (final s in spots.where((s) => s.ownerId == u.id)) {
        s.hostName = u.name;
        s.hostPhone = u.phone;
      }
    }
    notifyListeners();
  }

  void topUp(double amount) {
    final u = currentUser;
    if (u == null) return;
    u.balance += amount;
    notifyListeners();
  }

  // ── Cocheras (anfitrión) ──────────────────────────────────────────────────
  void saveSpot({
    ParkingSpot? existing,
    required String title,
    required String address,
    required String zone,
    required double baseRate,
    required int totalSlots,
    required int openMin,
    required int closeMin,
    required Set<VehicleCategory> vehicles,
    required List<String> photos,
    required double maxHeight,
    required double maxLength,
    required String restrictions,
    required List<TimeRange> peakHours,
  }) {
    final user = currentUser;
    if (user == null) return;
    if (existing == null) {
      spots.insert(
        0,
        ParkingSpot(
          id: 's${++_spotCounter}',
          ownerId: user.id,
          title: title,
          address: address,
          zone: zone,
          baseRate: baseRate,
          totalSlots: totalSlots,
          freeSlots: totalSlots,
          openMin: openMin,
          closeMin: closeMin,
          hostName: user.name,
          hostPhone: user.phone,
          hostPhotoUrl: '',
          hostRating: 0,
          hostVerified: false,
          vehicles: vehicles,
          photos: photos,
          maxHeight: maxHeight,
          maxLength: maxLength,
          restrictions: restrictions,
          peakHours: peakHours,
        ),
      );
    } else {
      final occupied = existing.totalSlots - existing.freeSlots;
      existing
        ..title = title
        ..address = address
        ..zone = zone
        ..baseRate = baseRate
        ..totalSlots = totalSlots
        ..freeSlots = clampInt(totalSlots - occupied, 0, totalSlots)
        ..openMin = openMin
        ..closeMin = closeMin
        ..vehicles = vehicles
        ..photos = photos
        ..maxHeight = maxHeight
        ..maxLength = maxLength
        ..restrictions = restrictions
        ..peakHours = peakHours;
    }
    notifyListeners();
  }

  void adjustFreeSlots(ParkingSpot spot, int delta) {
    spot.freeSlots = clampInt(spot.freeSlots + delta, 0, spot.totalSlots);
    notifyListeners();
  }

  /// Elimina la cochera; cancela y reembolsa las citas activas asociadas.
  void deleteSpot(ParkingSpot spot) {
    for (final r in reservations) {
      if (r.spotId == spot.id && r.status == ReservationStatus.activa) {
        r.status = ReservationStatus.cancelada;
        _refund(r);
      }
    }
    spots.removeWhere((s) => s.id == spot.id);
    notifyListeners();
  }

  // ── Reservaciones (conductor) ─────────────────────────────────────────────
  BookingResult createReservation({
    required ParkingSpot spot,
    required VehicleCategory vehicle,
    required String plate,
    required DateTime date,
    required int startMin,
    required int endMin,
    required PaymentMethod payment,
  }) {
    final user = currentUser;
    if (user == null) {
      return BookingResult.fail('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    if (spot.freeSlots <= 0) {
      return BookingResult.fail('Esta cochera no tiene cajones libres.');
    }
    if (!spot.vehicles.contains(vehicle)) {
      return BookingResult.fail('Esta cochera no acepta ${vehicle.label}.');
    }
    if (endMin <= startMin) {
      return BookingResult.fail(
          'La hora de salida debe ser posterior a la de llegada.');
    }
    if (startMin < spot.openMin || endMin > spot.closeMin) {
      return BookingResult.fail(
          'Elige un horario dentro del servicio: ${spot.scheduleLabel}.');
    }
    final now = DateTime.now();
    if (dateOnly(date) == dateOnly(now) &&
        startMin < now.hour * 60 + now.minute) {
      return BookingResult.fail(
          'La hora de llegada ya pasó. Elige otra hora o fecha.');
    }
    final total = spot.totalFor(startMin, endMin);
    if (payment == PaymentMethod.wallet && user.balance < total) {
      return BookingResult.fail(
          'Saldo insuficiente: tienes ${fmtMoney(user.balance)} y la cita cuesta ${fmtMoney(total)}. Recarga tu billetera en Perfil.');
    }

    if (payment == PaymentMethod.wallet) user.balance -= total;
    spot.freeSlots -= 1;
    final cleanPlate = plate.trim().toUpperCase();
    if (user.plate.isEmpty && cleanPlate.isNotEmpty) user.plate = cleanPlate;

    final r = Reservation(
      code: 'UP-${_reservationCounter++}',
      spotId: spot.id,
      spotTitle: spot.title,
      spotAddress: spot.address,
      hostId: spot.ownerId,
      hostName: spot.hostName,
      hostPhone: spot.hostPhone,
      driverId: user.id,
      driverName: user.name,
      driverPhone: user.phone,
      plate: cleanPlate,
      vehicle: vehicle,
      date: dateOnly(date),
      startMin: startMin,
      endMin: endMin,
      total: total,
      surcharge: spot.isPeak(startMin, endMin),
      payment: payment,
    );
    reservations.insert(0, r);
    notifyListeners();
    return BookingResult.ok(r);
  }

  /// Cancela una cita. Devuelve true si se reembolsó a la billetera.
  bool cancelReservation(Reservation r) {
    if (r.status != ReservationStatus.activa) return false;
    r.status = ReservationStatus.cancelada;
    final spot = spotById(r.spotId);
    if (spot != null) {
      spot.freeSlots = clampInt(spot.freeSlots + 1, 0, spot.totalSlots);
    }
    final refunded = _refund(r);
    notifyListeners();
    return refunded;
  }

  bool _refund(Reservation r) {
    if (r.payment != PaymentMethod.wallet) return false;
    for (final u in users) {
      if (u.id == r.driverId) {
        u.balance += r.total;
        return true;
      }
    }
    return false;
  }

  // ── Reseñas ───────────────────────────────────────────────────────────────
  void addReview(String spotId, int rating, String comment) {
    final user = currentUser;
    final spot = spotById(spotId);
    if (user == null || spot == null) return;
    spot.reviews.insert(
      0,
      Review(
        author: user.name,
        rating: rating,
        comment: comment.trim(),
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

/// Expone el [AppState] a todo el árbol y reconstruye al notificar cambios.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. MARCO DE SMARTPHONE (WEB), TEMA Y RAÍZ
// ═════════════════════════════════════════════════════════════════════════════

/// Permite deslizar con el mouse (PageView / listas horizontales en Web).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kNavy,
    primary: kNavy,
    secondary: kTeal,
    brightness: Brightness.light,
  ).copyWith(surface: Colors.white);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: kNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: tint(kTeal, 0.28),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Marco simulado de smartphone: solo se dibuja cuando se ejecuta en Web.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  static const double _w = 395;
  static const double _h = 820;
  static const double _bezel = 10;
  static const double _radius = 42;
  static const double _statusH = 30;
  static const Color _dark = Color(0xFF0E1115);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child; // Dispositivo nativo: 100% de la pantalla.

    final now = DateTime.now();
    return Material(
      color: const Color(0xFFD9E2EA),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: _w,
            height: _h,
            padding: const EdgeInsets.all(_bezel),
            decoration: BoxDecoration(
              color: _dark,
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius - _bezel),
              child: Column(
                children: [
                  // Barra de estado simulada
                  Container(
                    height: _statusH,
                    color: _dark,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${two(now.hour)}:${two(now.minute)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2A2F36),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.signal_cellular_alt,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Icon(Icons.wifi, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Icon(Icons.battery_full,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pantalla de la app: se ajusta MediaQuery al tamaño del marco
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, c) => MediaQuery(
                        data: MediaQuery.of(ctx).copyWith(
                          size: Size(c.maxWidth, c.maxHeight),
                          padding: EdgeInsets.zero,
                          viewPadding: EdgeInsets.zero,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UParkingApp extends StatefulWidget {
  const UParkingApp({super.key});

  @override
  State<UParkingApp> createState() => _UParkingAppState();
}

class _UParkingAppState extends State<UParkingApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'U-Parking',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) =>
            PhoneFrame(child: child ?? const SizedBox.shrink()),
        home: const RootGate(),
      ),
    );
  }
}

/// Decide qué flujo mostrar según la sesión y el rol activo.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser;
    if (user == null) return const AuthScreen();
    return user.role == UserRole.conductor
        ? const DriverShell()
        : const HostShell();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. WIDGETS REUTILIZABLES
// ═════════════════════════════════════════════════════════════════════════════

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.icon,
    this.color = kNavy,
    this.filled = false,
  });
  final String text;
  final IconData? icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : tint(color, 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip seleccionable (zona, vehículo, pago).
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : kNavy;
    return Material(
      color: selected ? kNavy : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? kNavy : const Color(0xFFC5CFD8)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  const StarRating(this.rating, {super.key, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = rating - i;
        final icon = v >= 0.75
            ? Icons.star
            : (v >= 0.25 ? Icons.star_half : Icons.star_border);
        return Icon(icon, size: size, color: Colors.amber.shade700);
      }),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.icon, this.text,
      {super.key, this.color, this.bold = false});
  final IconData icon;
  final String text;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: color ?? Colors.black87,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.color = Colors.white,
    this.borderColor = kLine,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });
  final Widget child;
  final String? title;
  final IconData? icon;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: kNavy),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, this.loading = false});
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kNavy, Color(0xFF0A6C8F)],
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white70,
                ),
              )
            : const Icon(Icons.local_parking, color: Colors.white54, size: 42),
      ),
    );
  }
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  /// Caché de fotos locales ya decodificadas (evita decodificar en cada build).
  static final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const PhotoPlaceholder();
    // Foto subida desde el dispositivo (data URI en base64).
    if (url.startsWith('data:image')) {
      final bytes = _memoryCache.putIfAbsent(
        url,
        () => base64Decode(url.substring(url.indexOf(',') + 1)),
      );
      return Image.memory(
        bytes,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => const PhotoPlaceholder(),
      );
    }
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const PhotoPlaceholder(loading: true),
      errorBuilder: (context, error, stack) => const PhotoPlaceholder(),
    );
  }
}

/// Carrusel deslizable con contador "Foto 1/N" y puntos indicadores.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({
    super.key,
    required this.photos,
    this.height = 180,
    this.overlay,
    this.onTap,
  });
  final List<String> photos;
  final double height;
  final Widget? overlay;
  final VoidCallback? onTap;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.photos.length;
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (n == 0)
            GestureDetector(
              onTap: widget.onTap,
              child: const PhotoPlaceholder(),
            )
          else
            PageView.builder(
              controller: _controller,
              itemCount: n,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: widget.onTap,
                child: NetImage(widget.photos[i]),
              ),
            ),
          if (widget.overlay != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: widget.overlay!,
            ),
          if (n > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    n,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == _page ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (n > 0)
            Positioned(
              bottom: 8,
              right: 10,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xAA000000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Foto ${_page + 1}/$n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HostAvatar extends StatelessWidget {
  const HostAvatar({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.radius = 20,
  });
  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: kNavy,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.75,
        ),
      ),
    );
    if (photoUrl.isEmpty) return fallback;
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => fallback,
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tint(color, 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

Widget formField({
  required TextEditingController controller,
  required String label,
  IconData? icon,
  String? hint,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool obscure = false,
  Widget? suffix,
  int? maxLength,
  TextCapitalization capitalization = TextCapitalization.none,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      obscureText: obscure,
      textCapitalization: capitalization,
      decoration: inputDeco(label, icon: icon, hint: hint, suffix: suffix),
    ),
  );
}

String? requiredValidator(String? v, [String msg = 'Campo obligatorio']) =>
    (v == null || v.trim().isEmpty) ? msg : null;

String? emailValidator(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Ingresa tu correo';
  if (!s.contains('@') || !s.contains('.')) return 'Correo no válido';
  return null;
}

String? phoneValidator(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Ingresa tu teléfono';
  if (!RegExp(r'^\d{10}$').hasMatch(s)) {
    return 'Debe tener exactamente 10 dígitos (solo números)';
  }
  return null;
}

/// Llamada simulada (sin url_launcher).
void showCallDialog(BuildContext context, String name, String phone) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.phone_in_talk, color: kTealDark, size: 36),
      title: Text('Llamar a $name', textAlign: TextAlign.center),
      content: Text(
        phone,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: kNavy,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(ctx).pop();
            showSnack(context, 'Marcando a $phone… (llamada simulada en esta demo)');
          },
          icon: const Icon(Icons.call, size: 18),
          label: const Text('Llamar'),
        ),
      ],
    ),
  );
}

/// Tarjeta de reservación reutilizada por conductor y anfitrión.
class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.forHost,
    this.onCancel,
  });
  final Reservation reservation;
  final bool forHost;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final active = r.status == ReservationStatus.activa;
    final hours = ((r.endMin - r.startMin) / 60).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(r.code,
                  icon: Icons.confirmation_number_outlined,
                  color: kNavy,
                  filled: true),
              const Spacer(),
              Pill(
                active ? 'Activa' : 'Cancelada',
                icon: active ? Icons.check_circle : Icons.cancel,
                color: active ? kTealDark : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.spotTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            r.spotAddress,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          InfoRow(Icons.event, fmtDateLong(r.date)),
          InfoRow(Icons.schedule,
              '${fmtTime(r.startMin)} a ${fmtTime(r.endMin)} ($hours h)'),
          if (forHost) ...[
            InfoRow(Icons.person, 'Cliente: ${r.driverName}'),
            InfoRow(Icons.phone, 'Teléfono: ${r.driverPhone}'),
          ] else ...[
            InfoRow(Icons.home_work, 'Anfitrión: ${r.hostName}'),
            InfoRow(Icons.phone, 'Contacto: ${r.hostPhone}'),
          ],
          InfoRow(
            r.vehicle.icon,
            '${r.vehicle.label}, placas: ${r.plate.isEmpty ? "sin placas" : r.plate}',
          ),
          InfoRow(r.payment.icon, r.payment.label),
          const Divider(height: 22),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                fmtMoney(r.total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: active ? kTealDark : Colors.grey,
                  decoration: active ? null : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          if (r.surcharge)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.whatshot, size: 15, color: kAlert),
                  SizedBox(width: 4),
                  Text(
                    'Incluye recargo de hora pico (+25%)',
                    style: TextStyle(fontSize: 12, color: kAlert),
                  ),
                ],
              ),
            ),
          if (active && onCancel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                icon: const Icon(Icons.event_busy, size: 18),
                label: const Text('Cancelar cita'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> confirmCancelReservation(
    BuildContext context, Reservation r) async {
  final app = AppScope.of(context);
  final String refundNote;
  switch (r.payment) {
    case PaymentMethod.wallet:
      refundNote =
          'Se reembolsarán ${fmtMoney(r.total)} a tu Billetera U-Parking.';
    case PaymentMethod.cash:
      refundNote = 'No hay cobro que reembolsar (pago en cochera).';
    case PaymentMethod.spei:
    case PaymentMethod.card:
      refundNote =
          'El reembolso de pagos por tarjeta o SPEI se gestiona con el anfitrión.';
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cancelar cita?'),
      content: Text(
        'Se cancelará la cita ${r.code} en "${r.spotTitle}" y se liberará el cajón.\n\n$refundNote',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Conservar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Cancelar cita'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final refunded = app.cancelReservation(r);
  showSnack(
    context,
    refunded
        ? 'Cita cancelada. Reembolso aplicado a tu billetera.'
        : 'Cita cancelada. El cajón fue liberado.',
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// 6. AUTENTICACIÓN
// ═════════════════════════════════════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();

  UserRole? _role;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regPass.dispose();
    super.dispose();
  }

  void _submitLogin() {
    FocusScope.of(context).unfocus();
    final role = _role;
    if (role == null) {
      setState(() => _error = 'Selecciona tu rol para continuar.');
      return;
    }
    if (!_loginKey.currentState!.validate()) return;
    final err = AppScope.of(context).login(
      email: _loginEmail.text,
      password: _loginPass.text,
      role: role,
    );
    if (err != null) setState(() => _error = err);
  }

  void _submitRegister() {
    FocusScope.of(context).unfocus();
    final role = _role;
    if (role == null) {
      setState(() => _error = 'Selecciona tu rol para continuar.');
      return;
    }
    if (!_registerKey.currentState!.validate()) return;
    final err = AppScope.of(context).register(
      name: _regName.text,
      email: _regEmail.text,
      phone: _regPhone.text,
      password: _regPass.text,
      role: role,
    );
    if (err != null) setState(() => _error = err);
  }

  void _fillDemo(String email, UserRole role) {
    _tab.animateTo(0);
    setState(() {
      _role = role;
      _loginEmail.text = email;
      _loginPass.text = '1234';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _tab.index == 0;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kNavy, Color(0xFF00547D)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tint(Colors.white, 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.local_parking, color: kTeal, size: 44),
                ),
                const SizedBox(height: 12),
                const Text(
                  'U-Parking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Renta colaborativa de cocheras en Puebla',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '¿Cómo vas a usar U-Parking?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: kNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleTile(
                              role: UserRole.conductor,
                              subtitle: 'Busco dónde estacionar',
                              selected: _role == UserRole.conductor,
                              onTap: () => setState(() {
                                _role = UserRole.conductor;
                                _error = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RoleTile(
                              role: UserRole.anfitrion,
                              subtitle: 'Rento mi cochera',
                              selected: _role == UserRole.anfitrion,
                              onTap: () => setState(() {
                                _role = UserRole.anfitrion;
                                _error = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        controller: _tab,
                        onTap: (_) => setState(() => _error = null),
                        labelColor: kNavy,
                        unselectedLabelColor: Colors.black45,
                        indicatorColor: kTeal,
                        dividerColor: kLine,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                        tabs: const [
                          Tab(text: 'Iniciar sesión'),
                          Tab(text: 'Registrarse'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isLogin) _loginForm() else _registerForm(),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 18, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      FilledButton(
                        onPressed: isLogin ? _submitLogin : _submitRegister,
                        child: Text(isLogin ? 'Entrar' : 'Crear mi cuenta'),
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 16),
                        _demoHint(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        children: [
          formField(
            controller: _loginEmail,
            label: 'Correo electrónico',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          formField(
            controller: _loginPass,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            obscure: _obscure,
            validator: (v) => requiredValidator(v, 'Ingresa tu contraseña'),
            suffix: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _registerKey,
      child: Column(
        children: [
          formField(
            controller: _regName,
            label: 'Nombre completo',
            icon: Icons.person_outline,
            capitalization: TextCapitalization.words,
            validator: (v) => requiredValidator(v, 'Ingresa tu nombre'),
          ),
          formField(
            controller: _regEmail,
            label: 'Correo electrónico',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          formField(
            controller: _regPhone,
            label: 'Teléfono / WhatsApp',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '2221234567',
            maxLength: 10,
            validator: phoneValidator,
          ),
          formField(
            controller: _regPass,
            label: 'Contraseña (mín. 6 caracteres)',
            icon: Icons.lock_outline,
            obscure: _obscure,
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            suffix: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint(kTeal, 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuentas de prueba (contraseña: 1234)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ActionChip(
                avatar: const Icon(Icons.directions_car_filled, size: 16),
                label: const Text('Conductor'),
                onPressed: () =>
                    _fillDemo('conductor@uparking.mx', UserRole.conductor),
              ),
              ActionChip(
                avatar: const Icon(Icons.home_work, size: 16),
                label: const Text('Don Ignacio'),
                onPressed: () =>
                    _fillDemo('ignacio@uparking.mx', UserRole.anfitrion),
              ),
              ActionChip(
                avatar: const Icon(Icons.home_work, size: 16),
                label: const Text('Beatriz'),
                onPressed: () =>
                    _fillDemo('beatriz@uparking.mx', UserRole.anfitrion),
              ),
              ActionChip(
                avatar: const Icon(Icons.home_work, size: 16),
                label: const Text('Carlos'),
                onPressed: () =>
                    _fillDemo('carlos@uparking.mx', UserRole.anfitrion),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final UserRole role;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? tint(kNavy, 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kNavy : kLine,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(role.icon, size: 30, color: selected ? kNavy : Colors.black45),
            const SizedBox(height: 6),
            Text(
              role.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: selected ? kNavy : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 7. ROL CONDUCTOR
// ═════════════════════════════════════════════════════════════════════════════

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DriverExplorePage(),
          DriverReservationsPage(),
          UserProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Mis citas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── Explorar ────────────────────────────────────────────────────────────────
class DriverExplorePage extends StatefulWidget {
  const DriverExplorePage({super.key});

  @override
  State<DriverExplorePage> createState() => _DriverExplorePageState();
}

class _DriverExplorePageState extends State<DriverExplorePage> {
  String _zone = kAllZones;
  VehicleCategory? _vehicle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser;
    final firstName = (user?.name ?? '').trim().split(' ').first;
    final results = app.spots
        .where((s) =>
            (_zone == kAllZones || s.zone == _zone) &&
            (_vehicle == null || s.vehicles.contains(_vehicle)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.local_parking, color: kTeal),
            SizedBox(width: 8),
            Text('U-Parking', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Pill(
                fmtMoney(user?.balance ?? 0),
                icon: Icons.account_balance_wallet,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${firstName.isEmpty ? "conductor" : firstName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '¿Dónde vas a estacionar hoy en Puebla?',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const _FilterLabel('Zona'),
          _ChipScroller(
            children: [
              for (final z in kFilterZones)
                OptionChip(
                  label: z,
                  icon: z == kAllZones ? Icons.apps : Icons.place,
                  selected: _zone == z,
                  onTap: () => setState(() => _zone = z),
                ),
            ],
          ),
          const _FilterLabel('Tipo de vehículo'),
          _ChipScroller(
            children: [
              OptionChip(
                label: 'Todos',
                icon: Icons.apps,
                selected: _vehicle == null,
                onTap: () => setState(() => _vehicle = null),
              ),
              for (final v in VehicleCategory.values)
                OptionChip(
                  label: v.label,
                  icon: v.icon,
                  selected: _vehicle == v,
                  onTap: () => setState(() => _vehicle = v),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text(
              results.length == 1
                  ? '1 cochera encontrada'
                  : '${results.length} cocheras encontradas',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 56, color: Colors.black26),
                  SizedBox(height: 8),
                  Text(
                    'No hay cocheras con esos filtros.\nPrueba otra zona o tipo de vehículo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            for (final s in results)
              SpotCard(
                spot: s,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SpotDetailPage(spotId: s.id),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _ChipScroller extends StatelessWidget {
  const _ChipScroller({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final c in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }
}

class SpotCard extends StatelessWidget {
  const SpotCard({super.key, required this.spot, required this.onTap});
  final ParkingSpot spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final peakNow = spot.isPeakNow();
    final hasFree = spot.freeSlots > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoCarousel(
              photos: spot.photos,
              height: 170,
              onTap: onTap,
              overlay: Row(
                children: [
                  Pill(
                    hasFree
                        ? '${spot.freeSlots} de ${spot.totalSlots} libres'
                        : 'Lleno',
                    icon: Icons.local_parking,
                    color: hasFree ? kTealDark : Colors.grey.shade700,
                    filled: true,
                  ),
                  const Spacer(),
                  if (peakNow)
                    const Pill(
                      'Alta demanda +25%',
                      icon: Icons.whatshot,
                      color: kAlert,
                      filled: true,
                    ),
                ],
              ),
            ),
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            spot.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kNavy,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmtRate(spot.baseRate),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: kTealDark,
                                height: 1,
                              ),
                            ),
                            const Text(
                              'por hora',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    InfoRow(Icons.place_outlined, spot.address),
                    InfoRow(Icons.schedule, 'Horario de servicio: ${spot.scheduleLabel}'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Pill(spot.zone, icon: Icons.map_outlined, color: kNavy),
                        for (final v in VehicleCategory.values)
                          if (spot.vehicles.contains(v))
                            Icon(v.icon, size: 20, color: kTeal),
                      ],
                    ),
                    const Divider(height: 22),
                    Row(
                      children: [
                        HostAvatar(
                          name: spot.hostName,
                          photoUrl: spot.hostPhotoUrl,
                          radius: 17,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot.hostName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 14, color: Colors.amber.shade700),
                                  const SizedBox(width: 3),
                                  Text(
                                    spot.reviews.isEmpty
                                        ? 'Sin reseñas'
                                        : '${spot.rating.toStringAsFixed(1)} (${spot.reviews.length})',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (spot.hostVerified)
                          const Icon(Icons.verified, size: 18, color: kTeal),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (spot.peakHours.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.whatshot, size: 16, color: kAlert),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              peakNow
                                  ? 'Hora pico en este momento: tarifa +25%'
                                  : 'Horas pico: ${spot.peakHours.map((p) => p.label).join(", ")}',
                              style: TextStyle(
                                fontSize: 12,
                                color: kAlert,
                                fontWeight:
                                    peakNow ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detalle y apartado ──────────────────────────────────────────────────────
class SpotDetailPage extends StatefulWidget {
  const SpotDetailPage({super.key, required this.spotId});
  final String spotId;

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  final TextEditingController _plate = TextEditingController();
  VehicleCategory? _vehicle;
  DateTime _date = dateOnly(DateTime.now());
  int? _startMin;
  int? _endMin;
  PaymentMethod _payment = PaymentMethod.wallet;
  bool _plateInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_plateInit) {
      _plateInit = true;
      _plate.text = AppScope.of(context).currentUser?.plate ?? '';
    }
  }

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Fecha de tu cita',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime(ParkingSpot spot, {required bool isStart}) async {
    final current = isStart ? _startMin : _endMin;
    var base = current ??
        (isStart ? spot.openMin : (_startMin ?? spot.openMin) + 120);
    if (base >= 1440) base = 1439;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base ~/ 60, minute: base % 60),
      helpText: isStart ? 'Hora de llegada' : 'Hora de salida',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (isStart) {
        _startMin = minutes;
      } else {
        _endMin = minutes;
      }
    });
  }

  void _confirm(ParkingSpot spot) {
    final app = AppScope.of(context);
    final v = _vehicle;
    final s = _startMin;
    final e = _endMin;
    if (v == null) {
      showSnack(context, 'Elige el tipo de vehículo.', error: true);
      return;
    }
    if (v != VehicleCategory.bicicleta && _plate.text.trim().isEmpty) {
      showSnack(context, 'Escribe las placas de tu vehículo.', error: true);
      return;
    }
    if (s == null || e == null) {
      showSnack(context, 'Selecciona hora de llegada y de salida.', error: true);
      return;
    }
    final result = app.createReservation(
      spot: spot,
      vehicle: v,
      plate: _plate.text,
      date: _date,
      startMin: s,
      endMin: e,
      payment: _payment,
    );
    final err = result.error;
    final r = result.reservation;
    if (err != null || r == null) {
      showSnack(context, err ?? 'No se pudo apartar el lugar.', error: true);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: kTealDark, size: 48),
        title: const Text('¡Cita confirmada!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              r.code,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kNavy,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${fmtDateLong(r.date)}\n${fmtTime(r.startMin)} a ${fmtTime(r.endMin)}\nTotal: ${fmtMoney(r.total)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Encuentra tu código en la pestaña Mis citas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  void _openReviewSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReviewSheet(spotId: widget.spotId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final spot = app.spotById(widget.spotId);
    if (spot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cochera')),
        body: const Center(child: Text('Esta cochera ya no está disponible.')),
      );
    }
    final user = app.currentUser;

    // Cálculo de duración, recargo y total
    final s = _startMin;
    final e = _endMin;
    var hours = 0.0;
    var peak = false;
    var total = 0.0;
    var baseCost = 0.0;
    if (s != null && e != null && e > s) {
      hours = (e - s) / 60;
      peak = spot.isPeak(s, e);
      total = spot.totalFor(s, e);
      baseCost = spot.baseRate * hours;
    }
    final quoteReady = hours > 0;
    final noPlateNeeded = _vehicle == VehicleCategory.bicicleta;

    return Scaffold(
      appBar: AppBar(
        title: Text(spot.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          PhotoCarousel(photos: spot.photos, height: 240),

          // ── Encabezado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        spot.title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: kNavy,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtRate(spot.baseRate),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: kTealDark,
                            height: 1,
                          ),
                        ),
                        const Text('por hora',
                            style: TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InfoRow(Icons.place_outlined, spot.address),
                InfoRow(Icons.schedule, 'Horario de servicio: ${spot.scheduleLabel}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pill(spot.zone, icon: Icons.map_outlined),
                    Pill(
                      spot.freeSlots > 0
                          ? '${spot.freeSlots} de ${spot.totalSlots} cajones libres'
                          : 'Sin cajones libres',
                      icon: Icons.local_parking,
                      color: spot.freeSlots > 0 ? kTealDark : Colors.grey.shade700,
                    ),
                    if (spot.reviews.isNotEmpty)
                      Pill(
                        '${spot.rating.toStringAsFixed(1)} · ${spot.reviews.length} reseñas',
                        icon: Icons.star,
                        color: Colors.amber.shade800,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Ficha del anfitrión
          SectionCard(
            title: 'Tu anfitrión',
            icon: Icons.home_work,
            child: Row(
              children: [
                HostAvatar(
                  name: spot.hostName,
                  photoUrl: spot.hostPhotoUrl,
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.hostName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (spot.hostRating > 0)
                        Row(
                          children: [
                            StarRating(spot.hostRating, size: 15),
                            const SizedBox(width: 5),
                            Text(
                              spot.hostRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      else
                        const Text('Anfitrión nuevo',
                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      if (spot.hostVerified)
                        const Row(
                          children: [
                            Icon(Icons.verified, size: 15, color: kTeal),
                            SizedBox(width: 4),
                            Text(
                              'Anfitrión verificado',
                              style: TextStyle(
                                fontSize: 12,
                                color: kTealDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: kTealDark),
                  tooltip: 'Llamar al anfitrión',
                  onPressed: () =>
                      showCallDialog(context, spot.hostName, spot.hostPhone),
                  icon: const Icon(Icons.call),
                ),
              ],
            ),
          ),

          // ── Limitaciones físicas
          SectionCard(
            title: 'Limitaciones físicas del lugar',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFFFF7E6),
            borderColor: const Color(0xFFFFD58A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(Icons.height,
                    'Altura máxima: ${spot.maxHeight.toStringAsFixed(2)} m',
                    bold: true),
                InfoRow(Icons.straighten,
                    'Longitud máxima: ${spot.maxLength.toStringAsFixed(2)} m',
                    bold: true),
                for (final r in spot.restrictionList)
                  InfoRow(Icons.block, r, color: Colors.red.shade800),
              ],
            ),
          ),

          // ── Horas pico
          SectionCard(
            title: 'Horas de alta demanda',
            icon: Icons.whatshot,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (spot.peakHours.isEmpty)
                  const Text('Esta cochera no tiene horas pico configuradas.',
                      style: TextStyle(color: Colors.black54))
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in spot.peakHours)
                        Pill(p.label, icon: Icons.whatshot, color: kAlert),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Si tu horario coincide con una hora pico se aplica un recargo del +25% sobre la tarifa base.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),

          // ── Apartado
          SectionCard(
            title: 'Aparta tu lugar',
            icon: Icons.event_available,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Tipo de vehículo'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in VehicleCategory.values)
                      if (spot.vehicles.contains(v))
                        OptionChip(
                          label: v.label,
                          icon: v.icon,
                          selected: _vehicle == v,
                          onTap: () => setState(() => _vehicle = v),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: inputDeco(
                    noPlateNeeded ? 'Placas (opcional)' : 'Placas',
                    icon: Icons.pin_outlined,
                    hint: 'ABC-123-A',
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Fecha y horario'),
                _PickerTile(
                  icon: Icons.event,
                  label: 'Fecha',
                  value: fmtDateLong(_date),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.login,
                        label: 'Llegada',
                        value: s == null ? 'Elegir hora' : fmtTime(s),
                        onTap: () => _pickTime(spot, isStart: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.logout,
                        label: 'Salida',
                        value: e == null ? 'Elegir hora' : fmtTime(e),
                        onTap: () => _pickTime(spot, isStart: false),
                      ),
                    ),
                  ],
                ),
                if (s != null && e != null && e <= s)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'La salida debe ser posterior a la llegada.',
                      style: TextStyle(fontSize: 12.5, color: Colors.red.shade700),
                    ),
                  ),
                if (peak) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tint(kAlert, 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tint(kAlert, 0.5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.whatshot, color: kAlert),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tu horario cruza una hora de alta demanda. Se aplicó un recargo del +25% al total.',
                            style: TextStyle(
                              color: kAlert,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tint(kTeal, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: quoteReady
                      ? Column(
                          children: [
                            _SummaryRow('Duración', '${hours.toStringAsFixed(1)} h'),
                            _SummaryRow('Tarifa base', '${fmtRate(spot.baseRate)}/h'),
                            _SummaryRow('Subtotal', fmtMoney(baseCost)),
                            if (peak)
                              _SummaryRow(
                                'Recargo hora pico (+25%)',
                                '+${fmtMoney(total - baseCost)}',
                                color: kAlert,
                              ),
                            const Divider(height: 18),
                            _SummaryRow('Total a pagar', fmtMoney(total),
                                big: true),
                          ],
                        )
                      : const Text(
                          'Selecciona la hora de llegada y de salida para calcular tu total.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Método de pago'),
                for (final m in PaymentMethod.values)
                  _PaymentTile(
                    method: m,
                    selected: _payment == m,
                    subtitle: switch (m) {
                      PaymentMethod.wallet =>
                        'Saldo disponible: ${fmtMoney(user?.balance ?? 0)}',
                      PaymentMethod.cash => 'Pagas al llegar a la cochera',
                      PaymentMethod.spei => 'Transfiere antes de tu llegada',
                      PaymentMethod.card => 'Cobro seguro al confirmar',
                    },
                    onTap: () => setState(() => _payment = m),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: spot.freeSlots > 0 ? () => _confirm(spot) : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      spot.freeSlots > 0
                          ? (quoteReady
                              ? 'Confirmar y apartar · ${fmtMoney(total)}'
                              : 'Confirmar y apartar')
                          : 'Sin cajones disponibles',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Reseñas
          SectionCard(
            title: 'Reseñas',
            icon: Icons.reviews_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      spot.reviews.isEmpty ? '–' : spot.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRating(spot.rating, size: 18),
                          Text(
                            '${spot.reviews.length} opiniones',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openReviewSheet,
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Escribir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (spot.reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Aún no hay reseñas. Cuenta cómo te fue y ayuda a otros conductores.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  for (final r in spot.reviews) _ReviewTile(review: r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kNavy),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.big = false, this.color});
  final String label;
  final String value;
  final bool big;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: big ? 15 : 13,
                fontWeight: big ? FontWeight.w800 : FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: big ? 22 : 13,
              fontWeight: FontWeight.w800,
              color: color ?? (big ? kTealDark : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.subtitle,
    required this.onTap,
  });
  final PaymentMethod method;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? tint(kNavy, 0.06) : Colors.white,
            border: Border.all(
              color: selected ? kNavy : kLine,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(method.icon, color: selected ? kNavy : Colors.black45),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? kTealDark : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HostAvatar(name: review.author, radius: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(fmtDate(review.date),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
              StarRating(review.rating.toDouble(), size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: const TextStyle(fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}

/// Modal para publicar reseña; recalcula el promedio en tiempo real.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.spotId});
  final String spotId;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 0;
  final TextEditingController _comment = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating < 1) {
      setState(() => _error = 'Elige de 1 a 5 estrellas.');
      return;
    }
    if (_comment.text.trim().length < 5) {
      setState(() => _error = 'Escribe un comentario de al menos 5 caracteres.');
      return;
    }
    AppScope.of(context).addReview(widget.spotId, _rating, _comment.text);
    showSnack(context, '¡Gracias! Tu reseña fue publicada.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu reseña',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text('¿Cómo fue tu experiencia en esta cochera?',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() {
                    _rating = i;
                    _error = null;
                  }),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade700,
                    size: 38,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 240,
            decoration: inputDeco('Comentario'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Publicar reseña'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mis citas ───────────────────────────────────────────────────────────────
class DriverReservationsPage extends StatelessWidget {
  const DriverReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = app.driverReservations;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis citas')),
      body: list.isEmpty
          ? const _EmptyState(
              icon: Icons.event_busy,
              title: 'Aún no tienes citas',
              message: 'Explora cocheras y aparta tu primer lugar.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              children: [
                for (final r in list)
                  ReservationCard(
                    reservation: r,
                    forHost: false,
                    onCancel: () => confirmCancelReservation(context, r),
                  ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 8. ROL ANFITRIÓN
// ═════════════════════════════════════════════════════════════════════════════

class HostShell extends StatefulWidget {
  const HostShell({super.key});

  @override
  State<HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<HostShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HostDashboardPage(),
          HostReservationsManagerPage(),
          UserProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── Panel de control ────────────────────────────────────────────────────────
class HostDashboardPage extends StatelessWidget {
  const HostDashboardPage({super.key});

  void _openForm(BuildContext context, [ParkingSpot? spot]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpotFormPage(spot: spot)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState app, ParkingSpot spot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cochera?'),
        content: Text(
          'Se eliminará "${spot.title}". Las citas activas se cancelarán y los pagos con billetera se reembolsarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    app.deleteSpot(spot);
    showSnack(context, 'Cochera eliminada.');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final spots = app.hostSpots;
    final free = spots.fold<int>(0, (sum, s) => sum + s.freeSlots);
    final occupied =
        spots.fold<int>(0, (sum, s) => sum + (s.totalSlots - s.freeSlots));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del anfitrión',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: kTeal,
        foregroundColor: kNavy,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Publicar cochera',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        icon: Icons.payments,
                        label: 'Ingresos por citas (MXN)',
                        value: fmtMoney(app.hostIncome),
                        color: kTealDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricTile(
                        icon: Icons.directions_car,
                        label: 'Cajones ocupados',
                        value: '$occupied',
                        color: kAlert,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        icon: Icons.local_parking,
                        label: 'Cajones libres',
                        value: '$free',
                        color: kTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricTile(
                        icon: Icons.home_work,
                        label: 'Cocheras activas',
                        value: '${spots.length}',
                        color: kNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Text(
              'Mis cocheras publicadas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
          ),
          if (spots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: _EmptyState(
                icon: Icons.add_home_work_outlined,
                title: 'Aún no publicas cocheras',
                message:
                    'Renta tus cajones vacíos y genera ingresos extra con conductores de tu zona.',
                action: FilledButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar mi primera cochera'),
                ),
              ),
            )
          else
            for (final s in spots)
              _HostSpotTile(
                spot: s,
                onEdit: () => _openForm(context, s),
                onDelete: () => _confirmDelete(context, app, s),
              ),
        ],
      ),
    );
  }
}

class _HostSpotTile extends StatelessWidget {
  const _HostSpotTile({
    required this.spot,
    required this.onEdit,
    required this.onDelete,
  });
  final ParkingSpot spot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: NetImage(
                        spot.photos.isEmpty ? '' : spot.photos.first),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kNavy,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(spot.zone,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        '${fmtRate(spot.baseRate)}/h · ${spot.scheduleLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Cajones libres',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  tooltip: 'Quitar un cajón libre',
                  onPressed: spot.freeSlots > 0
                      ? () => app.adjustFreeSlots(spot, -1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tint(kTeal, 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${spot.freeSlots} / ${spot.totalSlots}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Agregar un cajón libre',
                  onPressed: spot.freeSlots < spot.totalSlots
                      ? () => app.adjustFreeSlots(spot, 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formulario crear / editar ───────────────────────────────────────────────
class SpotFormPage extends StatefulWidget {
  const SpotFormPage({super.key, this.spot});

  /// Si es null se crea una cochera nueva; si no, se edita la existente.
  final ParkingSpot? spot;

  @override
  State<SpotFormPage> createState() => _SpotFormPageState();
}

class _SpotFormPageState extends State<SpotFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _address;
  late final TextEditingController _rate;
  late final TextEditingController _slots;
  late final TextEditingController _height;
  late final TextEditingController _length;
  late final TextEditingController _restrictions;
  final TextEditingController _photoUrl = TextEditingController();

  late String _zone;
  late int _openMin;
  late int _closeMin;
  late Set<VehicleCategory> _vehicles;
  late List<String> _photos;
  late List<TimeRange> _peaks;
  String? _photoError;
  String? _vehicleError;
  final ImagePicker _picker = ImagePicker();
  static const int _maxPhotos = 10;

  bool get _isEdit => widget.spot != null;

  @override
  void initState() {
    super.initState();
    final s = widget.spot;
    _title = TextEditingController(text: s?.title ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _rate = TextEditingController(text: s == null ? '' : trimNum(s.baseRate));
    _slots = TextEditingController(text: s == null ? '' : '${s.totalSlots}');
    _height = TextEditingController(text: s == null ? '' : trimNum(s.maxHeight));
    _length = TextEditingController(text: s == null ? '' : trimNum(s.maxLength));
    _restrictions = TextEditingController(text: s?.restrictions ?? '');
    _zone = s?.zone ?? kZoneCentro;
    _openMin = s?.openMin ?? 8 * 60;
    _closeMin = s?.closeMin ?? 20 * 60;
    _vehicles = Set<VehicleCategory>.of(s?.vehicles ?? <VehicleCategory>{});
    _photos = List<String>.of(s?.photos ?? <String>[]);
    _peaks = List<TimeRange>.of(s?.peakHours ?? <TimeRange>[]);
  }

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _rate.dispose();
    _slots.dispose();
    _height.dispose();
    _length.dispose();
    _restrictions.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<int?> _askTime(int initial, String help) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      helpText: help,
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  Future<void> _pickOpen() async {
    final m = await _askTime(_openMin, 'Hora de apertura');
    if (m != null && mounted) setState(() => _openMin = m);
  }

  Future<void> _pickClose() async {
    final m = await _askTime(_closeMin, 'Hora de cierre');
    if (m != null && mounted) setState(() => _closeMin = m);
  }

  Future<void> _addPeak() async {
    final start = await _askTime(8 * 60, 'Inicio de la hora pico');
    if (start == null || !mounted) return;
    final end = await _askTime(
        start + 120 >= 1440 ? 1439 : start + 120, 'Fin de la hora pico');
    if (end == null || !mounted) return;
    if (end <= start) {
      showSnack(context, 'El fin debe ser posterior al inicio.', error: true);
      return;
    }
    setState(() {
      _peaks.add(TimeRange(start, end));
      _peaks.sort((a, b) => a.start.compareTo(b.start));
    });
  }

  /// Abre la galería del dispositivo (selección múltiple) y agrega las fotos.
  Future<void> _pickFromDevice() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      showSnack(context, 'Máximo $_maxPhotos fotos por cochera.', error: true);
      return;
    }
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1280,
        imageQuality: 75,
      );
      if (files.isEmpty) return;
      final encoded = <String>[];
      for (final f in files.take(remaining)) {
        final bytes = await f.readAsBytes();
        encoded.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }
      if (!mounted) return;
      setState(() {
        _photos.addAll(encoded);
        _photoError = null;
      });
      showSnack(
        context,
        files.length > remaining
            ? 'Se agregaron $remaining fotos (máximo $_maxPhotos).'
            : '${encoded.length} foto(s) agregada(s).',
      );
    } catch (_) {
      if (!mounted) return;
      showSnack(context, 'No se pudo abrir la galería. Revisa los permisos.',
          error: true);
    }
  }

  void _addPhoto() {
    final url = _photoUrl.text.trim();
    final valid = (url.startsWith('http://') || url.startsWith('https://')) &&
        url.length > 10;
    if (!valid) {
      setState(() => _photoError = 'Ingresa una URL válida (http o https).');
      return;
    }
    setState(() {
      _photos.add(url);
      _photoUrl.clear();
      _photoError = null;
    });
  }

  void _save() {
    final valid = _formKey.currentState!.validate();
    setState(() {
      _vehicleError =
          _vehicles.isEmpty ? 'Selecciona al menos un tipo de vehículo.' : null;
    });
    if (!valid || _vehicles.isEmpty) return;
    if (_closeMin <= _openMin) {
      showSnack(context, 'El horario de cierre debe ser posterior al de apertura.',
          error: true);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    AppScope.of(context).saveSpot(
      existing: widget.spot,
      title: _title.text.trim(),
      address: _address.text.trim(),
      zone: _zone,
      baseRate: parseNum(_rate.text) ?? 0,
      totalSlots: int.tryParse(_slots.text.trim()) ?? 1,
      openMin: _openMin,
      closeMin: _closeMin,
      vehicles: _vehicles,
      photos: _photos,
      maxHeight: parseNum(_height.text) ?? 0,
      maxLength: parseNum(_length.text) ?? 0,
      restrictions: _restrictions.text.trim(),
      peakHours: _peaks,
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(_isEdit ? 'Cambios guardados.' : '¡Cochera publicada!'),
          backgroundColor: kNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _positiveNumber(String? v) {
    final n = parseNum(v ?? '');
    if (n == null || n <= 0) return 'Ingresa un valor mayor a 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar cochera' : 'Publicar cochera'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: Icon(_isEdit ? Icons.save : Icons.publish),
            label: Text(_isEdit ? 'Guardar cambios' : 'Publicar cochera'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Datos generales
            SectionCard(
              margin: const EdgeInsets.only(top: 12),
              title: 'Datos generales',
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Zona'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final z in kSpotZones)
                        OptionChip(
                          label: z,
                          icon: Icons.place,
                          selected: _zone == z,
                          onTap: () => setState(() => _zone = z),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  formField(
                    controller: _title,
                    label: 'Título de la publicación',
                    icon: Icons.title,
                    capitalization: TextCapitalization.sentences,
                    validator: (v) => requiredValidator(v, 'Ingresa un título'),
                  ),
                  formField(
                    controller: _address,
                    label: 'Dirección',
                    icon: Icons.place_outlined,
                    maxLines: 2,
                    capitalization: TextCapitalization.sentences,
                    validator: (v) => requiredValidator(v, 'Ingresa la dirección'),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: formField(
                          controller: _rate,
                          label: 'Tarifa base (\$/h)',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _positiveNumber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: formField(
                          controller: _slots,
                          label: 'Cajones totales',
                          icon: Icons.local_parking,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n < 1) return 'Mínimo 1';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horario
            SectionCard(
              title: 'Horario disponible',
              icon: Icons.schedule,
              child: Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Apertura',
                      value: fmtTime(_openMin),
                      onTap: _pickOpen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.nights_stay_outlined,
                      label: 'Cierre',
                      value: fmtTime(_closeMin),
                      onTap: _pickClose,
                    ),
                  ),
                ],
              ),
            ),

            // Vehículos
            SectionCard(
              title: 'Vehículos aceptados',
              icon: Icons.directions_car,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final v in VehicleCategory.values)
                        FilterChip(
                          avatar: Icon(v.icon, size: 18),
                          label: Text(v.label),
                          selected: _vehicles.contains(v),
                          selectedColor: tint(kTeal, 0.3),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _vehicles.add(v);
                            } else {
                              _vehicles.remove(v);
                            }
                            _vehicleError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_vehicleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_vehicleError!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12.5)),
                    ),
                ],
              ),
            ),

            // Fotografías
            SectionCard(
              title: 'Fotografías',
              icon: Icons.photo_library_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _pickFromDevice,
                      icon: const Icon(Icons.upload),
                      label: const Text('Subir fotos desde el dispositivo'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'O agrega una foto con su URL:',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _photoUrl,
                          keyboardType: TextInputType.url,
                          decoration: inputDeco(
                            'https://…/foto.jpg',
                            icon: Icons.link,
                          ).copyWith(errorText: _photoError),
                          onSubmitted: (_) => _addPhoto(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Agregar foto',
                        style: IconButton.styleFrom(backgroundColor: kNavy),
                        onPressed: _addPhoto,
                        icon: const Icon(Icons.add_a_photo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_photos.isEmpty)
                    const Text(
                      'Aún no agregas fotos. Una buena galería consigue más reservas.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    )
                  else
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 88,
                                height: 88,
                                child: NetImage(_photos[i]),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _photos.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xCC000000),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Limitaciones
            SectionCard(
              title: 'Limitaciones físicas',
              icon: Icons.warning_amber_rounded,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: formField(
                          controller: _height,
                          label: 'Altura máx. (m)',
                          icon: Icons.height,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _positiveNumber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: formField(
                          controller: _length,
                          label: 'Largo máx. (m)',
                          icon: Icons.straighten,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _positiveNumber,
                        ),
                      ),
                    ],
                  ),
                  formField(
                    controller: _restrictions,
                    label: 'Restricciones particulares',
                    hint: 'Una por línea. Ej.: Sin fugas de aceite',
                    maxLines: 4,
                    capitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),

            // Horas pico
            SectionCard(
              title: 'Horas pico (+25%)',
              icon: Icons.whatshot,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Si el horario de un cliente cruza estos rangos, se cobra un recargo automático del 25%.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < _peaks.length; i++)
                        Chip(
                          avatar: const Icon(Icons.whatshot,
                              size: 16, color: kAlert),
                          label: Text(_peaks[i].label),
                          onDeleted: () => setState(() => _peaks.removeAt(i)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _addPeak,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar hora pico'),
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

// ── Gestión de reservas ─────────────────────────────────────────────────────
class HostReservationsManagerPage extends StatelessWidget {
  const HostReservationsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = app.hostReservations;
    final active =
        list.where((r) => r.status == ReservationStatus.activa).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas de clientes',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: list.isEmpty
          ? const _EmptyState(
              icon: Icons.event_note_outlined,
              title: 'Sin reservas por ahora',
              message:
                  'Cuando un conductor aparte uno de tus cajones, la cita aparecerá aquí.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          icon: Icons.event_available,
                          label: 'Citas activas',
                          value: '$active',
                          color: kTealDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricTile(
                          icon: Icons.event_busy,
                          label: 'Canceladas',
                          value: '${list.length - active}',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final r in list)
                  ReservationCard(reservation: r, forHost: true),
              ],
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 9. PERFIL Y BILLETERA (COMPARTIDO)
// ═════════════════════════════════════════════════════════════════════════════

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  void _openRecharge(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recargar saldo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige el monto a abonar a tu Billetera U-Parking. (Simulación: no se realiza ningún cargo real.)',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final amount in const [50, 100, 200])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kTealDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          app.topUp(amount.toDouble());
                          Navigator.of(ctx).pop();
                          showSnack(context,
                              'Recargaste +\$$amount MXN a tu billetera.');
                        },
                        child: Text('+\$$amount',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser;
    if (user == null) return const SizedBox.shrink();
    final isDriver = user.role == UserRole.conductor;
    final activeCount = (isDriver ? app.driverReservations : app.hostReservations)
        .where((r) => r.status == ReservationStatus.activa)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              children: [
                HostAvatar(name: user.name, radius: 42),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                Pill('Rol activo: ${user.role.label}',
                    icon: user.role.icon, color: kNavy, filled: true),
              ],
            ),
          ),
          SectionCard(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            title: 'Mis datos',
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                InfoRow(Icons.phone, 'Teléfono / WhatsApp: ${user.phone}'),
                if (isDriver)
                  InfoRow(
                    Icons.pin_outlined,
                    'Placas predeterminadas: ${user.plate.isEmpty ? "sin registrar" : user.plate}',
                  ),
                InfoRow(Icons.event_available, 'Citas activas: $activeCount'),
              ],
            ),
          ),
          // Tarjeta de billetera / ganancias
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kNavy, Color(0xFF007A94)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDriver
                          ? Icons.account_balance_wallet
                          : Icons.trending_up,
                      color: kTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDriver ? 'Billetera U-Parking' : 'Balance de ganancias',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  fmtMoney(isDriver ? user.balance : app.hostIncome),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isDriver
                      ? 'Saldo prepagado en MXN'
                      : 'Ingresos de citas activas en MXN',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                if (isDriver) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kNavy,
                    ),
                    onPressed: () => _openRecharge(context, app),
                    icon: const Icon(Icons.add_card),
                    label: const Text('Recargar saldo',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => EditProfileDialog(user: user),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar perfil'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: app.logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión / Cambiar de rol'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.user});
  final AppUser user;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _plate;

  bool get _isDriver => widget.user.role == UserRole.conductor;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
    _plate = TextEditingController(text: widget.user.plate);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    AppScope.of(context).updateProfile(
      name: _name.text,
      phone: _phone.text,
      plate: _isDriver ? _plate.text : null,
    );
    showSnack(context, 'Perfil actualizado.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              formField(
                controller: _name,
                label: 'Nombre completo',
                icon: Icons.person_outline,
                capitalization: TextCapitalization.words,
                validator: (v) => requiredValidator(v, 'Ingresa tu nombre'),
              ),
              formField(
                controller: _phone,
                label: 'Teléfono / WhatsApp',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: phoneValidator,
              ),
              if (_isDriver)
                formField(
                  controller: _plate,
                  label: 'Placas predeterminadas',
                  icon: Icons.pin_outlined,
                  capitalization: TextCapitalization.characters,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}