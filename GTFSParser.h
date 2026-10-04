#pragma once
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <unordered_map>
#include "NodeData.h"
#include "EdgeData.h"

// Phase 1: Basic GTFS Ingestion Pipeline
inline void LoadGTFSStops(const std::string& filepath, std::vector<NodeData>& nodes, std::unordered_map<std::string, int>& stop_id_map, std::vector<std::vector<EdgeData>>& adj_list) {
    std::ifstream file(filepath);
    if (!file.is_open()) {
        std::cout << "[Warning] Could not open GTFS file: " << filepath << ". Relying on fallback mock data.\n";
        return;
    }

    std::string line;
    // Skip the CSV header row
    std::getline(file, line); 

    int loaded_count = 0;
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string id, name, lat_str, lon_str;
        
        // Parsing basic comma-delimited GTFS file (stop_id, stop_name, stop_lat, stop_lon)
        std::getline(ss, id, ',');
        std::getline(ss, name, ',');
        std::getline(ss, lat_str, ',');
        std::getline(ss, lon_str, ',');

        if(id.empty() || lat_str.empty() || lon_str.empty()) continue;

        try {
            double lat = std::stod(lat_str);
            double lon = std::stod(lon_str);

            int node_index = nodes.size();
            stop_id_map[id] = node_index;
            
            NodeData n;
            n.name = name;
            n.latitude = lat;
            n.longitude = lon;
            
            nodes.push_back(n);
            adj_list.push_back(std::vector<EdgeData>()); // Empty edge list to match indices
            loaded_count++;
        } catch (...) {
            // Soft failure: skip lines that cannot be parsed mathematically
        }
    }
    std::cout << "[Success] Loaded " << loaded_count << " transit stops from GTFS data pipeline.\n";
}
