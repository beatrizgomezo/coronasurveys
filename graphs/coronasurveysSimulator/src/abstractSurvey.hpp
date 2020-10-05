//
//  AbstractSurvey.hpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef abstractSurvey_hpp
#define abstractSurvey_hpp

#include <stdio.h>
#include <unordered_set>
#include "Snap.h"
using namespace TSnap;
using namespace std;

class SurveyResponse{
public:
    int responder;
    unordered_set<int> reach;//this includes the responder
    unordered_set<int> infected;// this is an infected subset of reach
};
class AbstractSurvey{
protected:
    const unordered_set<int>* infected=NULL;
    unordered_set<int> surveyTotalReach;//this is the set number of sampled individuals including reach in scale-up
    long positiveSamples;
    PUNGraph graph;
    TRnd rnd;
public:
    AbstractSurvey(int randomseed):rnd(randomseed){};
    virtual void setGraph(PUNGraph g) final;
    virtual void setInfectedIds(const unordered_set<int>& infected) final;
    //virtual void getSurveyResponses(int numResponders) final;
    virtual SurveyResponse getOneSurveyResponse() final;
    virtual SurveyResponse getOneSurveyResponse(int responderId)=0;
    virtual long getNumActuallySampled();
    virtual long getNumSampled()=0;
    virtual long getNumPositiveSamples();
    virtual float getPositiveRate();
    virtual void recordSampleFromResponse(SurveyResponse &r, int idToRecord) final;
    virtual void resetSurvey();
};
#endif /* AbstractSurvey_hpp */
