#pragma once

#include <string>
#include <vector>
#include "NodeData.h"
#include "EdgeData.h"

// Description: The Node Builder

inline void AddNode(std::vector<NodeData> &Nodes, std::vector<std::vector<EdgeData>> &adj_list, std::string name, double lat, double lon)
{
	// Description: Create and push the new node
	NodeData new_node = {name, lat, lon};
	Nodes.push_back(new_node);

	// Description: Immediate pushs a blank list of edges to keep the indices matched
	adj_list.push_back(std::vector<EdgeData>());
}

// Description: Helper to add a road between stops
inline void AddEdge(std::vector<std::vector<EdgeData>> &adj_list, int from_node, int to_node, int edge_id, double base_cost, double speed_limit)
{
	// Description: Create and push the new edge
	EdgeData new_edge = {to_node, edge_id, base_cost, speed_limit};
	adj_list[from_node].push_back(new_edge);
}

// Description: Main setup function
inline void BuildMap(std::vector<NodeData> &nodes, std::vector<std::vector<EdgeData>> &adj_list)
{
	// Description: This is where te physical network is to be built.
	// Description: This is the routing from 'Home' to 'School'
	AddNode(nodes, adj_list, "Home_132", 43.799640, -79.203146);
	AddNode(nodes, adj_list, "Home_85", 43.801338400129424, -79.20357334414567);
	AddNode(nodes, adj_list, "School_132", 43.798640, -79.203146);

	// Add edges to create a routing path.
	// Route Option 1: Home_132 -> Home_85 -> School_132 (Total Cost: 300)
	AddEdge(adj_list, 0, 1, 1001, 100.0, 50.0);
	AddEdge(adj_list, 1, 2, 1002, 200.0, 50.0);
	
	// Route Option 2: Home_132 directly to School_132 (Total Cost: 500)
	AddEdge(adj_list, 0, 2, 1003, 500.0, 50.0);
}