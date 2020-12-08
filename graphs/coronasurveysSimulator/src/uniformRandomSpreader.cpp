//
//  UniformRandomSpreader.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "uniformRandomSpreader.hpp"
#include <algorithm>
using namespace std;

void UniformRandomSpreader::computeInfectedFromGraph(const PUNGraph graph, int numToInfect){
    AbstractSpreader::computeInfectedFromGraph(graph,numToInfect);
    TIntV nodeIds;
    //graph->GetNIdV(nodeIds); // get the vector of node ids
    infected.clear();
    if (centerId>0){
        infected.insert(centerId);
    }
    while (infected.size() < min(numToInfect, graph->GetNodes())){
        infected.insert(graph->GetRndNId(rnd));
    }
    //now infected contains a random set of node ids. 

};
