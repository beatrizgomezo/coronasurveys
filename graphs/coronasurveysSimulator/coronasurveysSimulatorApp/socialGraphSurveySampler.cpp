//
//  coronasurveysSNSampler.cpp
//  snap-xcode
//
//  Created by Davide Frey on 21/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "socialGraphSurveySampler.hpp"




void SocialGraphSurveySampler::initializeGraph(){
    //string topologyFile="/Users/frey/work/COVID19/coronasurveys/graphs/coronasurveysSimulator/facebook_combined.txt";
  
    cout << "reading topology file "<<topologyFile<<endl;
    graph=LoadEdgeList<PUNGraph>(topologyFile.c_str());
    cout << "loaded graph with "<<graph->GetNodes()<<" nodes and "<<graph->GetEdges()<<" edges"<<endl;
      
      
}

SocialGraphSurveySampler::SocialGraphSurveySampler(int fwdFanout, int rndSeed, int reach, double ansProb, double fwdProb, std::string filename):AbstractGraphBasedSurveySampler(fwdFanout,rndSeed, reach,  ansProb,  fwdProb), topologyFile(filename) {
}




