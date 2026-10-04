#pragma once
#include <iostream>
#include <vector>
#include <queue>
#include <cmath>
#include <limits>
#include <algorithm>
#include "NodeData.h"
#include "EdgeData.h"

// Phase 2: Heuristic function for A* (Simplified Distance calculation)
inline double Heuristic(const NodeData& a, const NodeData& b) {
    double dx = a.latitude - b.latitude;
    double dy = a.longitude - b.longitude;
    // Multiplication scales degree approx to meters
    return std::sqrt(dx * dx + dy * dy) * 111000.0;
}

// Struct to track nodes during traversal in the priority queue
struct AStarNode {
    int id;
    double g_cost;
    double f_cost;
    
    // Invert the > operator to create a min-heap (lowest f_cost has highest priority)
    bool operator>(const AStarNode& other) const {
        return f_cost > other.f_cost;
    }
};

// Phase 2: The Core A* Engine Algorithm
inline std::vector<int> RunAStar(int start_id, int goal_id, const std::vector<NodeData>& nodes, const std::vector<std::vector<EdgeData>>& adj_list) {
    int n = nodes.size();
    if (n == 0 || start_id >= n || goal_id >= n) return {};

    std::vector<double> g_score(n, std::numeric_limits<double>::infinity());
    std::vector<int> came_from(n, -1);
    
    // Min-heap to explore the node with the lowest expected total cost first
    std::priority_queue<AStarNode, std::vector<AStarNode>, std::greater<AStarNode>> pq;
    
    g_score[start_id] = 0;
    pq.push({start_id, 0, Heuristic(nodes[start_id], nodes[goal_id])});
    
    while (!pq.empty()) {
        AStarNode current = pq.top();
        pq.pop();
        
        // We've reached the destination
        if (current.id == goal_id) {
            std::vector<int> path;
            int curr = goal_id;
            while (curr != -1) {
                path.push_back(curr);
                curr = came_from[curr];
            }
            std::reverse(path.begin(), path.end());
            return path;
        }
        
        // Skip if we already found a better path to this node
        if (current.g_cost > g_score[current.id]) continue;
        
        // Evaluate all connecting roads/transit edges
        for (const auto& edge : adj_list[current.id]) {
            // Calculate new cost: Cost so far + Time/Cost to traverse this road segment
            double tentative_g = g_score[current.id] + edge.base_cost;
            
            if (tentative_g < g_score[edge.to_node]) {
                came_from[edge.to_node] = current.id;
                g_score[edge.to_node] = tentative_g;
                
                // f_score is the total estimated cost (actual taken + guessed remaining)
                double f_score = tentative_g + Heuristic(nodes[edge.to_node], nodes[goal_id]);
                pq.push({edge.to_node, tentative_g, f_score});
            }
        }
    }
    
    return {}; // No valid path found
}