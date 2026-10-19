/***
 * Transit Routing Engine Entry
 */
#include <iostream>
#include <vector>
#include <unordered_map>
#include <string>
#include "NodeData.h"
#include "EdgeData.h"
#include "TheEngine.h"
#include "BuildMapp.h"
#include "GTFSParser.h"

int main()
{
    std::vector<NodeData> nodes;
    std::vector<std::vector<EdgeData>> adj_list;
    std::unordered_map<int, double> traffic_multiplier;
    std::unordered_map<std::string, int> stop_id_map;

    std::cout << "=========================================\n";
    std::cout << "   Transit Routing Engine Initialized    \n";
    std::cout << "=========================================\n\n";

    // Phase 1: Attempt to Load GTFS Data
    LoadGTFSStops("stops.txt", nodes, stop_id_map, adj_list);

    // Fallback logic: If no GTFS stops are found, build the hardcoded mock map
    if (nodes.empty()) {
        std::cout << "[Info] Building map using hardcoded fallback routing points...\n";
        BuildMap(nodes, adj_list);
    }

    std::cout << "[Info] Engine compiled and map structures populated. Total Nodes: " << nodes.size() << "\n\n";

    // Phase 2: Run the A* Routing Engine
    if (nodes.size() >= 3) {
        int start_node = 0;
        int end_node = 2; // Targeting Home_132 to School_132
        
        std::cout << "Calculating optimal route from '" << nodes[start_node].name << "' to '" << nodes[end_node].name << "'...\n";
        
        std::vector<int> path = RunAStar(start_node, end_node, nodes, adj_list);

        if (path.empty()) {
            std::cout << "-> No route found!\n";
        } else {
            std::cout << "-> Route successfully found! Path sequence:\n";
            for (size_t i = 0; i < path.size(); ++i) {
                std::cout << "   " << (i + 1) << ". " << nodes[path[i]].name << "\n";
            }
        }
    }

    return 0;
}
