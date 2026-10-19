import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../lib/local_engine/database/sqlite_schema.dart';

/// CLI tool to generate and pre-seed the bundled offline transit database.
void main(List<String> args) {
  final dbPath = args.isNotEmpty ? args[0] : 'assets/database/transit_offline.db';
  final file = File(dbPath);
  if (file.existsSync()) {
    file.deleteSync();
  }
  file.parent.createSync(recursive: true);

  print('Generating offline transit SQLite database at: $dbPath');
  final db = sqlite3.open(dbPath);

  try {
    // 1. Create tables
    db.execute(SqliteSchema.createTablesSql);

    // Try creating R*Tree index if sqlite3 was compiled with R*Tree support
    try {
      db.execute(SqliteSchema.createRtreeSql);
      print('R*Tree extension successfully initialized.');
    } catch (e) {
      print('Note: SQLite compiled without R*Tree module, standard indices active: $e');
    }

    // 2. Insert transit routes
    db.execute('''
      INSERT INTO routes (route_id, route_short_name, route_long_name, route_type, route_color) VALUES
      ('TTC_134', '134', '134 Progress to Centennial & STC', 3, 'DA291C'),
      ('TTC_985', '985', '985 Sheppard East Express', 3, '007AFF'),
      ('TTC_939', '939', '939 Finch Express to Seneca College', 3, '00853F'),
      ('TTC_85',  '85',  '85 Sheppard East Local', 3, 'DA291C'),
      ('TTC_39',  '39',  '39 Finch East Local', 3, 'FF9500');
    ''');

    // 3. Insert stops: 200 Murison Blvd, Centennial College, STC, Seneca Newnham
    db.execute('''
      INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon) VALUES
      -- Origin
      ('stop_murison_home', 'Home (200 Murison Blvd)', 43.799500, -79.208500),
      ('stop_murison_sheppard', 'Murison Blvd at Sheppard Ave E', 43.801000, -79.208000),
      ('stop_milner_murison', 'Milner Ave at Murison Blvd', 43.795000, -79.209000),

      -- 1. Destination: School (Centennial College Progress Campus)
      ('stop_progress_markham', 'Progress Ave at Markham Rd', 43.782000, -79.231000),
      ('stop_centennial_progress', 'Centennial College (Progress Campus)', 43.785300, -79.228200),
      ('stop_centennial_morningside', 'Centennial College (Morningside Campus)', 43.786500, -79.193200),

      -- 2. Destination: STC (Scarborough Town Centre)
      ('stop_scarborough_ctr', 'Scarborough Town Centre (STC)', 43.774500, -79.257800),
      ('stop_progress_mccowan', 'Progress Ave at McCowan Rd', 43.777000, -79.248000),

      -- 3. Destination: Seneca (Newnham Campus) & Transit Hubs
      ('stop_don_mills_stn', 'Don Mills Station Terminal', 43.775500, -79.346300),
      ('stop_finch_seneca', 'Finch Ave E at Seneca Hill Dr', 43.795000, -79.349000),
      ('stop_seneca_newnham', 'Seneca Polytechnic (Newnham Campus)', 43.795500, -79.349600);
    ''');

    // 4. Insert trips & stop times for the 3 routes
    db.execute('''
      -- =========================================================
      -- ROUTE 1: Home (200 Murison) -> School (Centennial College)
      -- =========================================================
      INSERT INTO trips (trip_id, route_id, service_id, trip_headsign, direction_id) VALUES
      ('trip_to_school_134', 'TTC_134', 'WEEKDAY', 'To Centennial College', 1),
      ('trip_to_school_frequent', 'TTC_134', 'WEEKDAY', 'To Centennial College Frequent', 1);

      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_school_134', 28800, 28860, 'stop_murison_home', 1),
      ('trip_to_school_134', 29040, 29080, 'stop_milner_murison', 2),
      ('trip_to_school_134', 29400, 29440, 'stop_progress_markham', 3),
      ('trip_to_school_134', 29700, 29760, 'stop_centennial_progress', 4);

      -- Frequent all-day schedule for school
      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_school_frequent', 0, 60, 'stop_murison_home', 1),
      ('trip_to_school_frequent', 240, 280, 'stop_milner_murison', 2),
      ('trip_to_school_frequent', 600, 640, 'stop_progress_markham', 3),
      ('trip_to_school_frequent', 900, 960, 'stop_centennial_progress', 4);

      -- =========================================================
      -- ROUTE 2: Home (200 Murison) -> STC (Scarborough Town Centre)
      -- =========================================================
      INSERT INTO trips (trip_id, route_id, service_id, trip_headsign, direction_id) VALUES
      ('trip_to_stc_134', 'TTC_134', 'WEEKDAY', 'To Scarborough Town Centre', 1),
      ('trip_to_stc_frequent', 'TTC_134', 'WEEKDAY', 'To Scarborough Town Centre Frequent', 1);

      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_stc_134', 28800, 28860, 'stop_murison_home', 1),
      ('trip_to_stc_134', 29040, 29080, 'stop_milner_murison', 2),
      ('trip_to_stc_134', 29340, 29380, 'stop_progress_markham', 3),
      ('trip_to_stc_134', 29600, 29640, 'stop_progress_mccowan', 4),
      ('trip_to_stc_134', 29900, 29960, 'stop_scarborough_ctr', 5);

      -- Frequent all-day schedule for STC
      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_stc_frequent', 0, 60, 'stop_murison_home', 1),
      ('trip_to_stc_frequent', 240, 280, 'stop_milner_murison', 2),
      ('trip_to_stc_frequent', 540, 580, 'stop_progress_markham', 3),
      ('trip_to_stc_frequent', 800, 840, 'stop_progress_mccowan', 4),
      ('trip_to_stc_frequent', 1100, 1160, 'stop_scarborough_ctr', 5);

      -- =========================================================
      -- ROUTE 3: Home (200 Murison) -> Seneca (Newnham Campus)
      -- Leg 1: 985 Sheppard Express (Murison/Sheppard -> Don Mills)
      -- Leg 2: 939 Finch Express (Don Mills -> Seneca Newnham)
      -- =========================================================
      INSERT INTO trips (trip_id, route_id, service_id, trip_headsign, direction_id) VALUES
      ('trip_to_seneca_985', 'TTC_985', 'WEEKDAY', '985 Express to Don Mills', 1),
      ('trip_to_seneca_939', 'TTC_939', 'WEEKDAY', '939 Finch Express to Seneca', 1),
      ('trip_to_seneca_frequent_1', 'TTC_985', 'WEEKDAY', 'To Don Mills Frequent', 1),
      ('trip_to_seneca_frequent_2', 'TTC_939', 'WEEKDAY', 'To Seneca Frequent', 1);

      -- Leg 1: Murison/Sheppard to Don Mills Station
      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_seneca_985', 28800, 28860, 'stop_murison_sheppard', 1),
      ('trip_to_seneca_985', 29700, 29760, 'stop_don_mills_stn', 2);

      -- Leg 2: Don Mills Station to Seneca Newnham
      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_seneca_939', 29880, 29940, 'stop_don_mills_stn', 1),
      ('trip_to_seneca_939', 30400, 30460, 'stop_seneca_newnham', 2);

      -- Frequent all-day schedule for Seneca
      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_seneca_frequent_1', 0, 60, 'stop_murison_sheppard', 1),
      ('trip_to_seneca_frequent_1', 900, 960, 'stop_don_mills_stn', 2);

      INSERT INTO stop_times (trip_id, arrival_time, departure_time, stop_id, stop_sequence) VALUES
      ('trip_to_seneca_frequent_2', 1020, 1080, 'stop_don_mills_stn', 1),
      ('trip_to_seneca_frequent_2', 1540, 1600, 'stop_seneca_newnham', 2);
    ''');

    // 5. Traffic Signals with Webster Timing Plans
    db.execute('''
      INSERT INTO traffic_signals (signal_id, intersection_lat, intersection_lon, cycle_length_sec, coordination_group) VALUES
      ('SIG_MURISON_SHEPPARD', 43.801000, -79.208000, 90, 'SHEPPARD_CORRIDOR'),
      ('SIG_PROGRESS_MARKHAM', 43.782000, -79.231000, 90, 'PROGRESS_CORRIDOR'),
      ('SIG_FINCH_SENECA',     43.795000, -79.349000, 100, 'FINCH_EAST');

      INSERT INTO signal_timing_plans (signal_id, day_type, start_hour, end_hour, green_split_ratio, phase_offset_sec) VALUES
      ('SIG_MURISON_SHEPPARD', 'WEEKDAY', 0, 23, 0.50, 0),
      ('SIG_PROGRESS_MARKHAM', 'WEEKDAY', 0, 23, 0.55, 15),
      ('SIG_FINCH_SENECA',     'WEEKDAY', 0, 23, 0.45, 30);
    ''');

    // 6. Populate spatial index
    try {
      db.execute(SqliteSchema.populateRtreeSql);
    } catch (_) {}

    print('Offline transit database seeded successfully with 200 Murison Blvd, Centennial, STC, and Seneca routes.');
  } finally {
    db.dispose();
  }
}
