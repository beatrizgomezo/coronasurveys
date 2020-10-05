//
//  coronasurveysSNSampler.hpp
//  snap-xcode
//
//  Created by Davide Frey on 21/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef socialGraphSurveyDiffusion_hpp
#define socialGraphSurveyDiffusion_hpp

#include <stdio.h>

#include <iostream>
#include <filesystem>
#include "Snap.h"
#include "shash.h"
#include "abstractGraphBasedSurveyDiffusion.hpp"
using namespace std;
using namespace TSnap;

class SocialGraphSurveyDiffusion: public AbstractGraphBasedSurveyDiffusion {
private:
    string topologyFile;
public:
    SocialGraphSurveyDiffusion(int fwdFanout, int rndSeed, int reach, double ansProb, double fwdProb, string filename);
    void initializeGraph();
    
};

#endif /* coronasurveysSNSampler_hpp */
