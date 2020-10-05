//
//  networkScaleUpSurvey.hpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef networkScaleUpSurvey_hpp
#define networkScaleUpSurvey_hpp
#include "abstractSurvey.hpp"
#include <stdio.h>
#include <unordered_set>
using namespace std;
class NetworkScaleUpSurvey: public AbstractSurvey{
private:
    int prescribedReach=150;
    long numSampled=0;
    float perturbedPositiveRate;
    TRnd perturbationRnd;
    float error=0;
public:
    NetworkScaleUpSurvey(int randomseed, int perturbationSeed): AbstractSurvey(randomseed), perturbationRnd(perturbationSeed){};
    void setPrescribedReach(int reach){prescribedReach=reach;};
    int getPrescribedReach(){return prescribedReach;}
    virtual SurveyResponse getOneSurveyResponse(int responderId);
    unordered_set<int> & scaleUpToFriends(unordered_set<int> &samples, int myId, int reach);
    virtual long getNumSampled();
    virtual void resetSurvey();
    virtual float getPositiveRate();
    virtual void setError(float e){error=e;}
};
#endif /* networkScaleUpSurvey_hpp */
