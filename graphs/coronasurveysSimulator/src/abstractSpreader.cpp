//
//  AbstractSpreader.cpp
//  coronasurveysSimulatorApp
//  This class is an interface for an infection spreader. It basically decides which nodes in the topology are infected.
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "abstractSpreader.hpp"
#include <unordered_set>

using namespace std;

const unordered_set<int>&  AbstractSpreader::getInfectedIds(){
    return infected;
}
