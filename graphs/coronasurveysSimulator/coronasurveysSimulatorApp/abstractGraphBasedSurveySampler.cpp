//
//  abstractSimulator.cpp
//  coronasurveysSimulator
//
//  Created by Davide Frey on 21/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "abstractGraphBasedSurveySampler.hpp"
#include <algorithm>
#include <iostream>
using namespace std;
// selects random node ids from the graph and returns them
TSparseSet<int>& AbstractGraphBasedSurveySampler::selectRandomSeedResponders(TSparseSet<int>& seeds, int num){
    if (!seeds.Empty()){
        cout<<"seeds is not empty in selectRandomSeedResponders"<<endl;
        seeds.Clr();
    }
    for (int i=0; i<num; i++){
        int id=graph->GetRndNId(rnd);
        seeds.AddKey(id);
    }
    return seeds;
}

//retuns numSamples integers between min and max (both included) This is used by forwardToFriends to select a set of random neighbors.
TSparseSet<int>& AbstractGraphBasedSurveySampler::samplePositions(TSparseSet<int>& samples, int numSamples, int min, int max){
    int numToAdd=std::min(numSamples, max - min + 1);
    while(samples.Len() < numToAdd){
        int sampleCan=rnd.GetUniDevInt(min, max);
        if (!samples.IsKey(sampleCan)){
            samples.AddKey(sampleCan);
        }
    }
    return samples;
}

// returns the identifiers of numSamples random friends in samples
list<int> & AbstractGraphBasedSurveySampler::forwardToFriends(list<int> &samples, int myId, int numSamples) {
    
    TUNGraph::TNodeI myNode=graph->GetNI(myId);
    int toSample=min(numSamples, myNode.GetDeg());
    TSparseSet<int> sampledPositions;
    samplePositions(sampledPositions, toSample, 0, toSample -1 );
   
    for (TSparseSet<int>::TIter pos=sampledPositions.BegI(); pos!=sampledPositions.EndI(); pos++){
        samples.push_back(myNode.GetNbrNId(*pos));
    }
    return samples;
}

AbstractGraphBasedSurveySampler::AbstractGraphBasedSurveySampler(int fwdFanout, int rndSeed, int reach, double ansProb, double fwdProb){
    this->fwdFanout=fwdFanout;
    rnd.PutSeed(rndSeed);
    this->reach=reach;
    this->ansProb=ansProb;
    this->fwdProb=fwdProb;
}




void  AbstractGraphBasedSurveySampler::correlatedSampling(int requiredSize){//} <- function(popSize, requiredSize, reach, numSeeds, ansProb, fwdProb, fwdFanout){
  // select seeds randomly
    if (!recipients.empty()){
        cout<<"recipients is not empty, emptying it"<<endl;
        recipients.clear();
    }
    selectRandomSeedResponders(responders, numSeeds);
    
    if (reach >1){
        //iterate through all the seed responders
        for (TSparseSet<int>::TIter seed=responders.BegI(); seed!=responders.EndI(); seed++){
            forwardToFriends(recipients, *seed, fwdFanout);
            // TODO check reach -1
                //surveyRecipients <- forwardToFriends(surveyRecipients, popSize, p, reach - 1, fwdProb, fwdFanout)
        }
    }
 
  
    list<int>::iterator myId=recipients.begin();
    while (myId!=recipients.end() && responders.Len() < requiredSize){
        if (rnd.GetUniDev()<ansProb){// if the recipiens answers the survey
            responders.AddKey(*myId); // we count its answer
            if (reach >1 && rnd.GetUniDev()< fwdProb){// this reach>1 condition is not necessary because we will never get here if reach=1 because of line 64
                //here we forward
                forwardToFriends(recipients, *myId, fwdFanout);
            }
        }
        myId++;
    }
    // now recipients contains the ids of everyone who received the survey
}

