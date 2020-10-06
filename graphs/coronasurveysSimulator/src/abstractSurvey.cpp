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
    surveyTotalReach=0;
    sampled.clear();
}
long AbstractSurvey::getNumActuallySampled(){
    return surveyTotalReach;
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
    } while (sampled.find(responderId)!=sampled.end());
    sampled.insert(responderId);
    return getOneSurveyResponse(responderId);
}

void AbstractSurvey::recordSampleFromResponse(SurveyResponse &r, int idToRecord){
    //this is called for each user inthe reach so we must not update sampled
    surveyTotalReach++;
    r.reach.insert(idToRecord);
        if (infected!=NULL && infected->find(idToRecord)!=infected->end()){
            //if this guy is infected
            positiveSamples++;
            r.infected.insert(idToRecord);
        }
}
