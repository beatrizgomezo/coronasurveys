//
//  util.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "util.hpp"

//retuns numSamples integers between min and max (both included) This is used by forwardToFriends to select a set of random neighbors.
unordered_set<int>& samplePositions(TRnd rnd, unordered_set<int>& samples, int numSamples, int min, int max){
    int numToAdd=std::min(numSamples, max - min + 1);
    while(samples.size() < numToAdd){
        int sampleCan=rnd.GetUniDevInt(min, max);
        if (samples.find(sampleCan)==samples.end()){
            samples.insert(sampleCan);
        }
    }
    return samples;
}
