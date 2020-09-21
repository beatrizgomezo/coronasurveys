//
//  abstractSimulator.hpp
//  coronasurveysSimulator
//
//  Created by Davide Frey on 21/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef abstractGraphBasedSurveySampler_hpp
#define abstractGraphBasedSurveySampler_hpp

#include <stdio.h>
#include "Snap.h"
#include "shash.h"
#include <list>

using namespace TSnap;
using namespace std;

class AbstractGraphBasedSurveySampler{
protected:
    TSparseSet<int> responders;
    list<int> recipients;
    
    PUNGraph graph;
    TRnd rnd;
    int fwdFanout;
    int numSeeds;
    int reach;
    double ansProb;
    double fwdProb;
    
public:
    AbstractGraphBasedSurveySampler(int fwdFanout, int rndSeed, int reach, double ansProb, double fwdProb);

    virtual TSparseSet<int>& selectRandomSeedResponders (TSparseSet<int>& seeds, int num) final;
    virtual void forwardToFriends(int myId) final;
    virtual TSparseSet<int>& samplePositions(TSparseSet<int>& samples, int numSamples, int min, int max) final;
    virtual list<int>& forwardToFriends(list<int> &samples, int myId, int numSamples) final;
    virtual void correlatedSampling(int requiredSize) final;
    virtual void initializeGraph()=0;
};
#endif /* abstractGraphBasedSurveySampler_hpp */
