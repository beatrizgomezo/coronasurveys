//
//  networkScaleUpSurvey.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "networkScaleUpSurvey.hpp"
#include "util.hpp"



SurveyResponse  NetworkScaleUpSurvey::getOneSurveyResponse(int responderId){
    SurveyResponse r;
    unordered_set<int> socialCircle;
    perturbedPositiveRate=-10000;
    r.responder=responderId;
    recordSampleFromResponse(r, r.responder);
    numSampled++;
    scaleUpToFriends(socialCircle, r.responder, prescribedReach);
    for (unordered_set<int>::iterator f=socialCircle.begin(); f!=socialCircle.end(); f++){
        recordSampleFromResponse(r, *f);
    }
    return r;
}


// returns the identifiers of reach random friends. returned value is in appended to samples
unordered_set<int> & NetworkScaleUpSurvey::scaleUpToFriends(unordered_set<int> &samples, int myId, int reach) {
    
    TUNGraph::TNodeI myNode=graph->GetNI(myId);
    int toSample=min(reach, myNode.GetDeg());
    unordered_set<int> sampledPositions;
    samplePositions(rnd, sampledPositions, toSample, 0, toSample -1 );
   
    for (unordered_set<int>::iterator pos=sampledPositions.begin(); pos!=sampledPositions.end(); pos++){
        samples.insert(myNode.GetNbrNId(*pos));
    }
    return samples;
}

long NetworkScaleUpSurvey::getNumSampled(){
    return numSampled;
}

void NetworkScaleUpSurvey::resetSurvey(){
    AbstractSurvey::resetSurvey();
    numSampled=0;
}
/*
double TRnd::GetNrmDev    (    const double &     Mean,
 const double &     SDev,
 const double &     Mn,
 const double &     Mx
 )
 */
float NetworkScaleUpSurvey::getPositiveRate(){
    if (perturbedPositiveRate<0){
        perturbedPositiveRate=AbstractSurvey::getPositiveRate();
        perturbedPositiveRate=perturbedPositiveRate+perturbedPositiveRate*perturbationRnd.GetNrmDev()*error;
    }
    return perturbedPositiveRate;
}
