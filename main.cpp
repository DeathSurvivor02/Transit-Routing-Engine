/***
 *  Date: July 27th, 2026
 * 	Author: Ean Bynoe
 * 	
 * Description:
 * This is the core execution file for the A* transit routing engine.
 * It initialises the the foundational data structures for the graph network,
 * including the node list (bus stops), the adjacency list (connecting roads),
 * and the dynamic hash map for live traffic multipliers. It acts as the entry 
 * point for building the map and triggering the pathfinding algorithm
 * 
 */

/***
 * Date: Aug 1st, 2026
 * Description: Broken down the different pieces of data data into their own files. "NodeData.h", "EdgeData.h", "TheEngine.h"
 * 
 * 
 *  */  

#include <iostream>
#include <vector>
#include <unordered_map>
#include <string>
#include "NodeData.h"
#include "EdgeData.h"
#include "TheEngine.h"



//Variables







// EdgeData must be defined before adj_list can use it


//2. Global Variables 
//Function

std::vector<NodeData> Nodes; // Vector to store node data
std::vector<std::vector<EdgeData>> adj_list; 	
std::unordered_map<int, double> traffic_multiplier; 
int TheEngine();



int BaseCost[]; //Description: this array will store the base cost for the edges between nodes


std::unordered_map<int, double> traffic_multiplier; //Description: this unordered map will store the traffic multiplier for each edge between nodes





