//
//  AbstractSurvey.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "abstractSurvey.hpp"
#include "Snap.h"

using namespace TSnap;
void AbstractSurvey::setGraph(PUNGraph g){
    this->graph=g;
}

void AbstractSurvey::setInfectedIds(const unordered_set<int> &infSet){
    this->infected=&infSet;
    resetSurvey();
}

void AbstractSurvey::resetSurvey(){
    positiveSamples=0;
    surveyTotalReach.clear();
}
long AbstractSurvey::getNumActuallySampled(){
    return surveyTotalReach.size();
}

long AbstractSurvey::getNumPositiveSamples(){
    return positiveSamples;
}

float AbstractSurvey::getPositiveRate(){
    return ((float)getNumPositiveSamples())/getNumActuallySampled();
}

/*
void AbstractSurvey::getSurveyResponses(int numResponders){
    //first empty current sample if existing
    
    // select random nodes
    while (surveyTotalReach.size()<min(numResponders,  graph->GetNodes())){
        getOneSurveyResponse();
    }
}*/

SurveyResponse AbstractSurvey::getOneSurveyResponse(){
    int responderId;
    do {
        responderId=graph->GetRndNId(rnd);
    } while (surveyTotalReach.find(responderId)!=surveyTotalReach.end());
    
    return getOneSurveyResponse(responderId);
}

void AbstractSurvey::recordSampleFromResponse(SurveyResponse &r, int idToRecord){
    surveyTotalReach.insert(idToRecord);
    r.reach.insert(idToRecord);
        if (infected!=NULL && infected->find(idToRecord)!=infected->end()){
            positiveSamples++;
            r.infected.insert(idToRecord);
        }
}
