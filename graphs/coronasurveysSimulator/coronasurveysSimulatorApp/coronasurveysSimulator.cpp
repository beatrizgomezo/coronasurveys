//
//  main.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 20/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include <iostream>
#include <filesystem>
#include "Snap.h"
#include "shash.h"

using namespace std;
using namespace TSnap;




int main(int argc, const char * argv[]) {
    
    // insert code here...
    string topologyFile="/Users/frey/work/COVID19/coronasurveys/graphs/coronasurveysSimulator/facebook_combined.txt";
  /*  if (argc>0){
        cout<<"updating topology file to "<<argv[0]<<endl;
        topologyFile=argv[0];
    }*/
    cout << "reading topology file "<<topologyFile<<endl;
    PUNGraph graph=LoadEdgeList<PUNGraph>(topologyFile.c_str());
    cout << "loaded graph with "<<graph->GetNodes()<<" nodes and "<<graph->GetEdges()<<" edges"<<endl;
    
    
    return 0;
}
