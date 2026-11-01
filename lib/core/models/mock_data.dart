import 'package:flutter/material.dart';

class MockVehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plate;
  final String city;
  final String shopName;
  final String shopAddress;
  final double rating;
  final int tripCount;
  final int dailyRate;
  final int hourlyRate1;
  final int hourlyRate3;
  final int hourlyRate6;
  final int deposit;
  final String fuelType;
  final String transmission;
  final int seats;
  final String category;
  final bool hasAC;
  final bool hasBluetooth;
  final bool hasAirbags;
  final bool hasSunroof;
  final String status; // 'Available', 'Rented', 'Maintenance'
  final String imageUrl;
  final Color brandColor;

  const MockVehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.city,
    required this.shopName,
    required this.shopAddress,
    required this.rating,
    required this.tripCount,
    required this.dailyRate,
    required this.hourlyRate1,
    required this.hourlyRate3,
    required this.hourlyRate6,
    required this.deposit,
    required this.fuelType,
    required this.transmission,
    required this.seats,
    required this.category,
    this.hasAC = true,
    this.hasBluetooth = true,
    this.hasAirbags = true,
    this.hasSunroof = false,
    this.status = 'Available',
    required this.imageUrl,
    this.brandColor = const Color(0xFFDC2626),
  });

  String get fullName => '$make $model $year';
  String get name => '$make $model';
  int get modelYear => year;
  String get plateNumber => plate;
  String get shopId => 'shop-1';
  int get selfDriveDailyRate => dailyRate;
  int get withDriverDailyRate => dailyRate + 1500;
  int get overtimeHourlyRate => 300;
  int get outstationAllowance => 2000;
  int get securityDeposit => deposit;
}

class MockShop {
  final String id;
  final String name;
  final String ownerName;
  final String ownerPhone;
  final String city;
  final String address;
  final int fleetCount;
  final double rating;
  final int reviews;
  final bool isVerified;
  final String tier; // 'Free Starter', 'Pro Garage', 'Enterprise Fleet'
  final String jazzCash;
  final String easyPaisa;
  final String bankIban;

  const MockShop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerPhone,
    required this.city,
    required this.address,
    required this.fleetCount,
    required this.rating,
    required this.reviews,
    this.isVerified = true,
    this.tier = 'Free Starter',
    this.jazzCash = '0300-1234567',
    this.easyPaisa = '0333-9876543',
    this.bankIban = 'PK45MEZN0001020304050607',
  });
}

class MockBooking {
  final String id;
  final String vehicleName;
  final String plate;
  final String renterName;
  final String renterPhone;
  final String renterCnic;
  final double renterTrust;
  final String packageTitle;
  final int totalFare;
  final int advanceToken;
  final int balanceDue;
  String status; // 'Requested', 'Approved', 'Active', 'Completed', 'Cancelled'
  final String pickupTime;
  final String returnTime;
  final int odometerStart;
  final int odometerEnd;
  final int fuelLevelStart; // 1 to 8 bars
  final int fuelLevelEnd;

  MockBooking({
    required this.id,
    required this.vehicleName,
    required this.plate,
    required this.renterName,
    required this.renterPhone,
    required this.renterCnic,
    required this.renterTrust,
    required this.packageTitle,
    required this.totalFare,
    required this.advanceToken,
    required this.balanceDue,
    this.status = 'Requested',
    required this.pickupTime,
    required this.returnTime,
    this.odometerStart = 42850,
    this.odometerEnd = 42920,
    this.fuelLevelStart = 6,
    this.fuelLevelEnd = 6,
  });
}

class MockBlacklistEntry {
  final String cnic;
  final String fullName;
  final String reportedBy;
  final String city;
  final String incidentCategory;
  final String amountDue;
  final String date;
  final bool firAttached;
  String status; // 'Active Ban', 'Under Inquest', 'Reverted'

  MockBlacklistEntry({
    required this.cnic,
    required this.fullName,
    required this.reportedBy,
    required this.city,
    required this.incidentCategory,
    required this.amountDue,
    required this.date,
    this.firAttached = true,
    this.status = 'Active Ban',
  });
}

class MockDatabase {
  static final List<MockVehicle> vehicles = [
    const MockVehicle(
      id: 'v1',
      make: 'Honda',
      model: 'Civic Oriel',
      year: 2021,
      plate: 'LEA-4820',
      city: 'Lahore',
      shopName: 'Al-Falah Rent a Car',
      shopAddress: 'Main Boulevard, Gulberg III, Lahore',
      rating: 4.9,
      tripCount: 42,
      dailyRate: 9000,
      hourlyRate1: 1500,
      hourlyRate3: 3500,
      hourlyRate6: 6000,
      deposit: 1000,
      fuelType: 'Petrol',
      transmission: 'Automatic',
      seats: 5,
      category: 'Sedan',
      hasSunroof: true,
      status: 'Available',
      imageUrl: 'assets/cars/civic.png',
      brandColor: Color(0xFFDC2626),
    ),
    const MockVehicle(
      id: 'v2',
      make: 'Toyota',
      model: 'Corolla Grande',
      year: 2022,
      plate: 'ICT-9912',
      city: 'Lahore',
      shopName: 'Al-Falah Rent a Car',
      shopAddress: 'Main Boulevard, Gulberg III, Lahore',
      rating: 4.8,
      tripCount: 38,
      dailyRate: 8500,
      hourlyRate1: 1400,
      hourlyRate3: 3200,
      hourlyRate6: 5500,
      deposit: 1000,
      fuelType: 'Petrol',
      transmission: 'Automatic',
      seats: 5,
      category: 'Sedan',
      hasSunroof: true,
      status: 'Rented',
      imageUrl: 'assets/cars/corolla.png',
      brandColor: Color(0xFF2563EB),
    ),
    const MockVehicle(
      id: 'v3',
      make: 'Suzuki',
      model: 'Alto VXL',
      year: 2023,
      plate: 'LHR-1029',
      city: 'Lahore',
      shopName: 'Capital Cruisers',
      shopAddress: 'F-10 Markaz, Islamabad',
      rating: 4.7,
      tripCount: 65,
      dailyRate: 3500,
      hourlyRate1: 800,
      hourlyRate3: 1800,
      hourlyRate6: 2800,
      deposit: 1000,
      fuelType: 'Petrol',
      transmission: 'Automatic',
      seats: 4,
      category: 'Economy',
      hasSunroof: false,
      status: 'Available',
      imageUrl: 'assets/cars/alto.png',
      brandColor: Color(0xFF059669),
    ),
    const MockVehicle(
      id: 'v4',
      make: 'Toyota',
      model: 'Fortuner Legender',
      year: 2023,
      plate: 'MN-707',
      city: 'Lahore',
      shopName: 'Crown Executive Motors',
      shopAddress: 'Clifton Block 5, Karachi',
      rating: 5.0,
      tripCount: 19,
      dailyRate: 25000,
      hourlyRate1: 4500,
      hourlyRate3: 11000,
      hourlyRate6: 18000,
      deposit: 5000,
      fuelType: 'Diesel',
      transmission: 'Automatic',
      seats: 7,
      category: 'SUV',
      hasSunroof: true,
      status: 'Available',
      imageUrl: 'assets/cars/fortuner.png',
      brandColor: Color(0xFFD97706),
    ),
  ];

  static final List<MockShop> shops = [
    const MockShop(
      id: 's1',
      name: 'Al-Falah Rent a Car',
      ownerName: 'Muhammad Bilal',
      ownerPhone: '+92 300 1234567',
      city: 'Lahore',
      address: 'Shop #4, Ground Floor, Al-Rehman Plaza, Gulberg III',
      fleetCount: 18,
      rating: 4.9,
      reviews: 148,
      isVerified: true,
      tier: 'Pro Garage',
    ),
    const MockShop(
      id: 's2',
      name: 'Capital Executive Cruisers',
      ownerName: 'Usman Shah',
      ownerPhone: '+92 333 5551234',
      city: 'Islamabad',
      address: 'Plot 12, F-10 Markaz, Islamabad',
      fleetCount: 24,
      rating: 4.8,
      reviews: 92,
      isVerified: true,
      tier: 'Pro Garage',
    ),
    const MockShop(
      id: 's3',
      name: 'Crown Executive Fleet',
      ownerName: 'Farhan Ali',
      ownerPhone: '+92 321 8889900',
      city: 'Karachi',
      address: 'Clifton Road, Block 5, Karachi',
      fleetCount: 48,
      rating: 4.95,
      reviews: 310,
      isVerified: true,
      tier: 'Enterprise Fleet',
    ),
  ];

  static final List<MockBooking> bookings = [
    MockBooking(
      id: 'RH-84920',
      vehicleName: 'Honda Civic Oriel 2021',
      plate: 'LEA-4820',
      renterName: 'Ahmed Khan',
      renterPhone: '+92 300 9876543',
      renterCnic: '35201-1234567-1',
      renterTrust: 4.9,
      packageTitle: '3-Hour QuickRide',
      totalFare: 3500,
      advanceToken: 1000,
      balanceDue: 2500,
      status: 'Active',
      pickupTime: 'Today, 02:00 PM',
      returnTime: 'Today, 05:00 PM',
      odometerStart: 42850,
      odometerEnd: 42920,
      fuelLevelStart: 6,
      fuelLevelEnd: 6,
    ),
    MockBooking(
      id: 'RH-84922',
      vehicleName: 'Toyota Corolla Grande 2022',
      plate: 'ICT-9912',
      renterName: 'Usman Ali',
      renterPhone: '+92 312 4455667',
      renterCnic: '61101-5544332-1',
      renterTrust: 4.7,
      packageTitle: 'Full Day (24 Hours)',
      totalFare: 8500,
      advanceToken: 1000,
      balanceDue: 7500,
      status: 'Requested',
      pickupTime: 'Tomorrow, 10:00 AM',
      returnTime: 'Next Day, 10:00 AM',
    ),
  ];

  static final List<MockBlacklistEntry> blacklist = [
    MockBlacklistEntry(
      cnic: '35201-9918234-1',
      fullName: 'Hamza Shafiq',
      reportedBy: 'Al-Falah Rent a Car (Lahore)',
      city: 'Lahore',
      incidentCategory: 'Absconded with vehicle / Tracker tampered',
      amountDue: 'PKR 45,000 + Vehicle Recovery',
      date: 'Oct 28, 2024',
      firAttached: true,
      status: 'Active Ban',
    ),
    MockBlacklistEntry(
      cnic: '42201-5501928-7',
      fullName: 'Zubair Ahmed',
      reportedBy: 'Rehman Motors (Karachi)',
      city: 'Karachi',
      incidentCategory: 'Unpaid balance > PKR 30,000',
      amountDue: 'PKR 38,000',
      date: 'Oct 22, 2024',
      firAttached: false,
      status: 'Under Inquest',
    ),
    MockBlacklistEntry(
      cnic: '61101-9018274-3',
      fullName: 'Kamran Tariq',
      reportedBy: 'Capital Wheels (Islamabad)',
      city: 'Islamabad',
      incidentCategory: 'Severe accident & fled scene',
      amountDue: 'PKR 120,000',
      date: 'Oct 15, 2024',
      firAttached: true,
      status: 'Active Ban',
    ),
  ];
}

