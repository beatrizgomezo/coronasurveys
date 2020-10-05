//
//  abstractSimulator.hpp
//  coronasurveysSimulator
//
//  Created by Davide Frey on 21/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef abstractGraphBasedSurveyDiffusion_hpp
#define abstractGraphBasedSurveyDiffusion_hpp

#include <stdio.h>
#include "Snap.h"
#include "shash.h"
#include <list>
#include <unordered_set>

using namespace TSnap;
using namespace std;

class AbstractGraphBasedSurveyDiffusion{
protected:
    unordered_set<int> responders;
    list<int> recipients;
    
    PUNGraph graph;
    TRnd rnd;
    int fwdFanout;
    int reach;
    double ansProb;
    double fwdProb;
    
public:
    AbstractGraphBasedSurveyDiffusion(int fwdFanout, int rndSeed, int reach, double ansProb, double fwdProb);

    virtual unordered_set<int>& selectRandomSeedResponders (unordered_set<int>& seeds, int num) final;
    //virtual void forwardToFriends(int myId) final;
    //virtual unordered_set<int>& samplePositions(unordered_set<int>& samples, int numSamples, int min, int max) final;
    virtual list<int>& forwardToFriends(list<int> &samples, int myId, int numSamples) final;
    virtual unordered_set<int> correlatedSampling(int requiredSize, int numSeeds) final;
    virtual void initializeGraph()=0;
};
#endif /* abstractGraphBasedSurveySampler_hpp */
