//
//  sampleGraph.cpp
//  graphSampler
//
//  Created by Davide Frey on 6/11/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include <iostream>
#include <filesystem>
#include <vector>
#include "Snap.h"
#include "shash.h"
#include "CLI11.hpp"
#include <fstream>
#include <math.h>
#include <string>
#include "breadthFirstExploration.hpp"

using namespace std;
using namespace TSnap;

void readSeedsFromFile(vector<int>& seeds, const string& filename){
    ifstream seedfile(filename);
    int seed;
    while (seedfile >> seed )
    {
      //        cout<<"reading seed"<<seed<<endl;
        seeds.push_back(seed);
    }
    seedfile.close();
}

int main (int argc, char *argv[]) {
    CLI::App app{"Survey simulator: this simulator compares a direct-estimation survey with a network-scale-up survey on a social graph provided as input."};
    // Define options
    string seedFileName;
    string outfilename;
    string topologyFile;
    string graphModel;
    int level;
    app.add_option("-g,--graph", topologyFile, "name of the file containing the network topology")->check(CLI::ExistingFile);
    app.add_option("-G,--generate", graphModel, "generate graph instead of loading it");
    app.add_option("-s,--seeds", seedFileName, "name of the file containing the seeds for the random number generator. The simulator needs 3 seeds per run. It will run as many runs as there are seeds.")->required()->check(CLI::ExistingFile);
    app.add_option("-l,--level", level, "number of levels of BFS (hops): 0 returns only the root; 1 goes 1 hop, and so on.")->required();
    app.add_option("-o,--out", outfilename, "output filename")->required();

    CLI11_PARSE(app, argc, argv);
  
    if (graphModel=="" && topologyFile==""){
        cerr<<"At least one between -g and -G is required"<<endl;
        exit(-1);
    }
    
  
    vector<int> seeds;
    cout<<"reading seed file"<<seedFileName<<endl;
    readSeedsFromFile(seeds, seedFileName);
    
    TRnd rndGen(seeds[1]);
    PUNGraph graph;
    if (!topologyFile.empty()){
        graph=LoadEdgeList<PUNGraph>(topologyFile.c_str());
    } else {
        if (graphModel.find("PrefA")!=string::npos){
            string parameters=graphModel.substr(5);
            int commaPos=parameters.find("-");
            int nodes=stoi(parameters.substr(0, commaPos));
            int degree=stoi(parameters.substr(commaPos+1));
            graph=GenPrefAttach (nodes,degree, rndGen );
        } else if (graphModel.find("RndG")!=string::npos){
            string parameters=graphModel.substr(4);
            int commaPos=parameters.find("-");
            int nodes=stoi(parameters.substr(0, commaPos));
            int edges=stoi(parameters.substr(commaPos+1));
            graph=GenRndGnm<PUNGraph>(nodes,edges,false,rndGen);
        }
    }

    cout<<"loaded graph with "<<graph->GetNodes()<<" nodes and "<<graph->GetEdges()<<" edges."<<endl;
   
    BreadthFirstExploration explorer(seeds[0], graph);
    explorer.doBFS(level);
    const unordered_set<int>& nodeSet = explorer.getBFSNodes();
    TIntV idV;
    for (const auto& elem: nodeSet) {
      idV.Add(elem);
    }
    PUNGraph subGraph=GetSubGraph (graph, idV, false);
    
    cout<<"computed sample with "<<subGraph->GetNodes()<<" nodes and "<<subGraph->GetEdges()<<" edges. Saving to "<<outfilename<<"."<<endl;
    SaveEdgeList	(subGraph, TStr(outfilename.c_str()));
	
}
//int main(int argc, const char * argv[]) {
//    
//    // insert code here...
//    string topologyFile="/Users/frey/work/COVID19/coronasurveys/graphs/coronasurveysSimulator/facebook_combined.txt";
//  /*  if (argc>0){
//        cout<<"updating topology file to "<<argv[0]<<endl;
//        topologyFile=argv[0];
//    }*/
//    cout << "reading topology file "<<topologyFile<<endl;
//    PUNGraph graph=LoadEdgeList<PUNGraph>(topologyFile.c_str());
//    cout << "loaded graph with "<<graph->GetNodes()<<" nodes and "<<graph->GetEdges()<<" edges"<<endl;
//    
//    
//    return 0;
//}
