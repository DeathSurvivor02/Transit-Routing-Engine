#pragma once

#include <string>

struct EdgeData{
	int to_node; //Description: representing the integer ID of the bus stop this road leads to
	int edge_id; //Description: holding the random road ID. Your engine will use this to query the @traffic_multiplier unordered map to get the traffic multiplier for this edge
	double base_cost; //Description: holding the raw, empty-road travel time
	double speed_limit; //Description: holding the speed limit for this edge
	
};