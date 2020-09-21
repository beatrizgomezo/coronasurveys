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
#include <unordered_set>

using namespace std;
// selects random node ids from the graph and returns them
unordered_set<int>& AbstractGraphBasedSurveySampler::selectRandomSeedResponders(unordered_set<int>& seeds, int num){
    if (!seeds.empty()){
        cout<<"seeds is not empty in selectRandomSeedResponders"<<endl;
        seeds.clear();
    }
    for (int i=0; i<num; i++){
        int id=graph->GetRndNId(rnd);
        seeds.insert(id);
    }
    return seeds;
}

//retuns numSamples integers between min and max (both included) This is used by forwardToFriends to select a set of random neighbors.
unordered_set<int>& AbstractGraphBasedSurveySampler::samplePositions(unordered_set<int>& samples, int numSamples, int min, int max){
    int numToAdd=std::min(numSamples, max - min + 1);
    while(samples.size() < numToAdd){
        int sampleCan=rnd.GetUniDevInt(min, max);
        if (samples.find(sampleCan)==samples.end()){
            cout<<"adding sample candidate "<<sampleCan<<endl;
            samples.insert(sampleCan);
        }
    }
    return samples;
}

// returns the identifiers of numSamples random friends. returned value is in appended to samples
list<int> & AbstractGraphBasedSurveySampler::forwardToFriends(list<int> &samples, int myId, int numSamples) {
    
    TUNGraph::TNodeI myNode=graph->GetNI(myId);
    int toSample=min(numSamples, myNode.GetDeg());
    unordered_set<int> sampledPositions;
    samplePositions(sampledPositions, toSample, 0, toSample -1 );
   
    for (unordered_set<int>::iterator pos=sampledPositions.begin(); pos!=sampledPositions.end(); pos++){
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




list<int>  AbstractGraphBasedSurveySampler::correlatedSampling(int requiredSize, int numSeeds){//} <- function(popSize, requiredSize, reach, numSeeds, ansProb, fwdProb, fwdFanout){
  // select seeds randomly
    if (!recipients.empty()){
        cout<<"recipients is not empty, emptying it"<<endl;
        recipients.clear();
    }
    selectRandomSeedResponders(responders, numSeeds);
    
    if (reach >1){//TODO check if this condition is right
        //iterate through all the seed responders
        for (unordered_set<int>::iterator seed=responders.begin(); seed!=responders.end(); seed++){
            forwardToFriends(recipients, *seed, fwdFanout);
            // TODO check reach -1
                //surveyRecipients <- forwardToFriends(surveyRecipients, popSize, p, reach - 1, fwdProb, fwdFanout)
        }
    }
 
  /* note to myself and to whoever reads this code ;) : recipients is a list and must remain a list!
     we start with the set of users that received the survey from the seeds. We iterate thorough this set,
        if the recipient answers the survey we add it to respondents, then we give it the option of forwarding.
        If it forwards, then we append a subset of its friends to recipients. So these friends will be processed
        after the users that are currently in recipients. This means that this is a breadth-first exploration of the social graph.
   */
    list<int>::iterator myId=recipients.begin();
    while (myId!=recipients.end() && responders.size() < requiredSize){
        if (rnd.GetUniDev()<ansProb){// if the recipiens answers the survey
            responders.insert(*myId); // we count its answer
            if (reach >1 && rnd.GetUniDev()< fwdProb){// this reach>1 condition is not necessary because we will never get here if reach=1 because of line 71. Check if condition on reach is right.
                //here we forward
                forwardToFriends(recipients, *myId, fwdFanout);
            }
        }
        myId++;
    }
    
    // now recipients contains the ids of everyone who received the survey
    return recipients;
}

