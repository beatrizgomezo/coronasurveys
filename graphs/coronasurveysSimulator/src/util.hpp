//
//  util.hpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef util_hpp
#define util_hpp

#include <stdio.h>
#include <unordered_set>
#include "Snap.h"
using namespace TSnap;

using namespace std;
unordered_set<int>& samplePositions(TRnd rnd,  unordered_set<int>& samples, int numSamples, int min, int max);

#endif /* util_hpp */
