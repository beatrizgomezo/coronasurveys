//
//  testGraphSampler.cpp
//  coronasurveysSimulator
//
//  Created by Davide Frey on 23/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "abstractGraphBasedSurveyDiffusion.hpp"
#include "socialGraphSurveyDiffusion.hpp"
#include <filesystem>
#include <iostream>
using namespace std;
/*
int main (int argc, char *argv[]) {
    //survey forwarding fanout
    int fwdFanout=10;
    int seed=423234523;
    //number of people one knows
    int reach=150;
    // probability that someone receiving the survey answers it
    double ansProb=1;
    // probability that someone answering the survey forwards it
    double fwdProb=1;
    //topology file
    cout<<"current path is "<<std::__fs::filesystem::current_path()<<endl;
    string filename="/Users/frey/work/COVID19/coronasurveys/graphs/coronasurveysSimulator/facebook_combined.txt";
    SocialGraphSurveyDiffusion sampler (fwdFanout, seed, reach,  ansProb,  fwdProb,  filename);
    sampler.initializeGraph();
    unordered_set<int> users=sampler.correlatedSampling(1000, 5);
    cout<<"responder list has size "<<users.size()<<endl;
    for(unordered_set<int>::iterator u=users.begin();u!=users.end();u++){
        cout<<*u<<", ";
    }
    cout<<endl;
}
*/
