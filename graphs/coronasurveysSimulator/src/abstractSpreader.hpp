//
//  AbstractSpreader.hpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef abstractSpreader_hpp
#define abstractSpreader_hpp

#include <stdio.h>
#include <unordered_set>
#include "Snap.h"


using namespace TSnap;
using namespace std;

class AbstractSpreader{
protected:
    TRnd rnd;
    AbstractSpreader(int randomSeed):rnd(randomSeed){
    }
    unordered_set<int> infected;
    int numNodes=0;
public:
    virtual void computeInfectedFromGraph(const PUNGraph graph, int numToInfect){
        numNodes=graph->GetNodes();
    };
    virtual const unordered_set<int>& getInfectedIds();
    virtual float getInfectionRate() final {return getInfectedIds().size()/(float)numNodes;}
};
#endif /* AbstractSpreader_hpp */
