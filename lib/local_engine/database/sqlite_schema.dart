/// DDL Statements for the Transit Offline SQLite Database.
class SqliteSchema {
  static const String createTablesSql = '''
-- Core Stops & Spatial Index
CREATE TABLE IF NOT EXISTS stops (
    stop_id TEXT PRIMARY KEY,
    stop_code TEXT,
    stop_name TEXT NOT NULL,
    stop_lat REAL NOT NULL,
    stop_lon REAL NOT NULL,
    zone_id TEXT,
    location_type INTEGER DEFAULT 0,
    parent_station TEXT,
    wheelchair_boarding INTEGER DEFAULT 0
);

-- Timetable & Graph Entities
CREATE TABLE IF NOT EXISTS routes (
    route_id TEXT PRIMARY KEY,
    agency_id TEXT,
    route_short_name TEXT,
    route_long_name TEXT,
    route_type INTEGER, -- 0: Tram, 1: Subway, 2: Rail, 3: Bus
    route_color TEXT
);

CREATE TABLE IF NOT EXISTS trips (
    trip_id TEXT PRIMARY KEY,
    route_id TEXT REFERENCES routes(route_id),
    service_id TEXT NOT NULL,
    trip_headsign TEXT,
    direction_id INTEGER
);

CREATE TABLE IF NOT EXISTS stop_times (
    trip_id TEXT REFERENCES trips(trip_id),
    arrival_time INTEGER NOT NULL,   -- Seconds from midnight (can exceed 86400)
    departure_time INTEGER NOT NULL,
    stop_id TEXT REFERENCES stops(stop_id),
    stop_sequence INTEGER NOT NULL,
    PRIMARY KEY (trip_id, stop_sequence)
);

CREATE INDEX IF NOT EXISTS idx_stop_times_lookup ON stop_times (stop_id, departure_time);
CREATE INDEX IF NOT EXISTS idx_stop_times_trip ON stop_times (trip_id, stop_sequence);

-- Traffic Signal Timing & Cycle Topology
CREATE TABLE IF NOT EXISTS traffic_signals (
    signal_id TEXT PRIMARY KEY,
    intersection_lat REAL NOT NULL,
    intersection_lon REAL NOT NULL,
    cycle_length_sec INTEGER NOT NULL, -- Total cycle duration (e.g., 90s, 120s)
    coordination_group TEXT
);

CREATE TABLE IF NOT EXISTS signal_timing_plans (
    plan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    signal_id TEXT REFERENCES traffic_signals(signal_id),
    day_type TEXT NOT NULL,           -- 'WEEKDAY', 'SATURDAY', 'SUNDAY'
    start_hour INTEGER NOT NULL,      -- 0-23
    end_hour INTEGER NOT NULL,        -- 0-23
    green_split_ratio REAL NOT NULL,  -- Effective Green Time / Cycle Length (0.0 to 1.0)
    phase_offset_sec INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_signal_plans ON signal_timing_plans(signal_id, day_type, start_hour);

-- Road Network Graph Edges with Signal Associations
CREATE TABLE IF NOT EXISTS street_edges (
    edge_id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_node INTEGER NOT NULL,
    target_node INTEGER NOT NULL,
    length_meters REAL NOT NULL,
    base_speed_mps REAL NOT NULL,
    associated_signal_id TEXT REFERENCES traffic_signals(signal_id),
    approach_direction_degrees REAL
);

CREATE INDEX IF NOT EXISTS idx_street_edges_source ON street_edges (source_node);
''';

  /// SQL for R*Tree virtual table (checked dynamically as R*Tree extension must be enabled)
  static const String createRtreeSql = '''
CREATE VIRTUAL TABLE IF NOT EXISTS stops_spatial_idx USING rtree(
    id INTEGER PRIMARY KEY,   -- Maps to stops.rowid
    min_lat REAL, max_lat REAL,
    min_lon REAL, max_lon REAL
);
''';

  static const String populateRtreeSql = '''
INSERT OR REPLACE INTO stops_spatial_idx (id, min_lat, max_lat, min_lon, max_lon)
SELECT rowid, stop_lat, stop_lat, stop_lon, stop_lon FROM stops;
''';
}
