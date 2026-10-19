import '../../core/geometry/coordinate.dart';
import '../models/stop.dart';

/// Bounding rectangle in latitude/longitude coordinates.
class GeoBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  bool contains(Coordinate coord) {
    return coord.latitude >= minLat &&
        coord.latitude <= maxLat &&
        coord.longitude >= minLon &&
        coord.longitude <= maxLon;
  }

  bool intersects(GeoBounds other) {
    return !(other.minLon > maxLon ||
        other.maxLon < minLon ||
        other.minLat > maxLat ||
        other.maxLat < minLat);
  }
}

/// Quadtree node for fast spatial clustering and range queries of GTFS stops.
class Quadtree {
  static const int defaultCapacity = 32;
  static const int maxDepth = 12;

  final GeoBounds bounds;
  final int capacity;
  final int depth;

  final List<Stop> _stops = [];
  bool _divided = false;

  Quadtree? _northWest;
  Quadtree? _northEast;
  Quadtree? _southWest;
  Quadtree? _southEast;

  Quadtree({
    required this.bounds,
    this.capacity = defaultCapacity,
    this.depth = 0,
  });

  /// Inserts a stop into the quadtree.
  bool insert(Stop stop) {
    if (!bounds.contains(stop.coordinate)) {
      return false;
    }

    if (_stops.length < capacity || depth >= maxDepth) {
      _stops.add(stop);
      return true;
    }

    if (!_divided) {
      _subdivide();
    }

    return (_northWest!.insert(stop) ||
        _northEast!.insert(stop) ||
        _southWest!.insert(stop) ||
        _southEast!.insert(stop));
  }

  void _subdivide() {
    final midLat = (bounds.minLat + bounds.maxLat) / 2.0;
    final midLon = (bounds.minLon + bounds.maxLon) / 2.0;

    _northWest = Quadtree(
      bounds: GeoBounds(minLat: midLat, maxLat: bounds.maxLat, minLon: bounds.minLon, maxLon: midLon),
      capacity: capacity,
      depth: depth + 1,
    );
    _northEast = Quadtree(
      bounds: GeoBounds(minLat: midLat, maxLat: bounds.maxLat, minLon: midLon, maxLon: bounds.maxLon),
      capacity: capacity,
      depth: depth + 1,
    );
    _southWest = Quadtree(
      bounds: GeoBounds(minLat: bounds.minLat, maxLat: midLat, minLon: bounds.minLon, maxLon: midLon),
      capacity: capacity,
      depth: depth + 1,
    );
    _southEast = Quadtree(
      bounds: GeoBounds(minLat: bounds.minLat, maxLat: midLat, minLon: midLon, maxLon: bounds.maxLon),
      capacity: capacity,
      depth: depth + 1,
    );

    _divided = true;

    // Redistribute existing stops to children
    for (final s in _stops) {
      _northWest!.insert(s) ||
          _northEast!.insert(s) ||
          _southWest!.insert(s) ||
          _southEast!.insert(s);
    }
    _stops.clear();
  }

  /// Queries all stops within a target bounding box.
  List<Stop> query(GeoBounds range) {
    final List<Stop> found = [];
    _queryRecursive(range, found);
    return found;
  }

  void _queryRecursive(GeoBounds range, List<Stop> results) {
    if (!bounds.intersects(range)) {
      return;
    }

    for (final s in _stops) {
      if (range.contains(s.coordinate)) {
        results.add(s);
      }
    }

    if (_divided) {
      _northWest!._queryRecursive(range, results);
      _northEast!._queryRecursive(range, results);
      _southWest!._queryRecursive(range, results);
      _southEast!._queryRecursive(range, results);
    }
  }

  /// Clusters stops within a bounding box at a given grid resolution.
  List<StopCluster> cluster(GeoBounds range, double clusterDistanceDegrees) {
    final stops = query(range);
    final List<StopCluster> clusters = [];

    for (final stop in stops) {
      bool merged = false;
      for (final cluster in clusters) {
        if ((cluster.center.latitude - stop.coordinate.latitude).abs() < clusterDistanceDegrees &&
            (cluster.center.longitude - stop.coordinate.longitude).abs() < clusterDistanceDegrees) {
          cluster.addStop(stop);
          merged = true;
          break;
        }
      }
      if (!merged) {
        clusters.add(StopCluster(initialStop: stop));
      }
    }

    return clusters;
  }
}

/// A cluster of nearby stops for performance-optimized rendering.
class StopCluster {
  final List<Stop> stops = [];
  double _sumLat = 0.0;
  double _sumLon = 0.0;

  StopCluster({required Stop initialStop}) {
    addStop(initialStop);
  }

  void addStop(Stop stop) {
    stops.add(stop);
    _sumLat += stop.coordinate.latitude;
    _sumLon += stop.coordinate.longitude;
  }

  Coordinate get center => Coordinate(
        _sumLat / stops.length,
        _sumLon / stops.length,
      );

  bool get isSingle => stops.length == 1;
  int get count => stops.length;
}
