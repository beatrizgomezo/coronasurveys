//
//  main.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 20/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include <iostream>
#include <filesystem>
#include <vector>
#include "Snap.h"
#include "shash.h"
#include "uniformRandomSpreader.hpp"
#include "directEstimationSurvey.hpp"
#include "networkScaleUpSurvey.hpp"
#include "CLI11.hpp"
#include <fstream>
#include <math.h>
#include <string>
using namespace std;
using namespace TSnap;

float squareError(float a, float b){
    return (a-b)*(a-b);
}

class SimulationParameters{
public:
   
    float error=0;
    string topologyFile="";
    string graphModel="";
    int prescribedReach=150;
    float infectedFraction=0.02;
    int numToSample=100;
    int spreaderSeed=0;
    int surveySeed=0;
    int perturbationSeed=0;
    int graphgenSeed=0;
    int runId=0;
    
};

class PerSurveySimulationResults{
public:
    vector<float> estimations;
    vector<float> squaredErrors;
    vector<int> numRuns;
    vector<float> actualInfectionRates;
    float finalEstimation;
    float finalActualInfectionRate;
    float finalSquaredError;
    int finalNumRuns=0;
    void recordEstimation(int runIndex, int sampleIndex, float estimation, float trueValue){
        cout<<"recording with sampleIndex="<<sampleIndex<<endl;
        if (runIndex==0){//this is the first recording for this index
            estimations.push_back(0);
            squaredErrors.push_back(0);
            numRuns.push_back(0);
            actualInfectionRates.push_back(0);
            if (estimations.size()!=sampleIndex+1){
                cerr<<"something is wrong";
                exit(-1);
            }
        }
        estimations[sampleIndex]+=estimation;
        squaredErrors[sampleIndex]+=squareError(estimation,trueValue);
        numRuns[sampleIndex]++;
        actualInfectionRates[sampleIndex]+=trueValue;
        
    }
    
    void recordFinalEstimation(int runIndex, float estimation, float trueValue){
        if (runIndex==0){
            finalEstimation=0;
            finalActualInfectionRate=0;
            finalSquaredError=0;
            finalNumRuns=0;
        }
        finalEstimation+=estimation;
        finalActualInfectionRate+=trueValue;
        finalSquaredError+=squareError(estimation, trueValue);
        finalNumRuns+=1;
    }
       
    float getFinalMeanActualInfectionRate(){
        return finalActualInfectionRate/(float)getFinalNumRuns();
    }
    float getFinalMeanEstimation(){
        return finalEstimation/(float)getFinalNumRuns();
    }
    float getFinalRootMeanSquaredError(){
        return sqrt(finalSquaredError/(float)getFinalNumRuns());
    }
    int getFinalNumRuns(){
        return finalNumRuns;
    }
    int getNumRuns(int sampleIndex){
        return numRuns[sampleIndex];
    }
    float getMeanEstimation(int sampleIndex){
        return estimations[sampleIndex]/(float)numRuns[sampleIndex];
    }
    float getRootMeanSquaredError(int sampleIndex){
        return sqrt(squaredErrors[sampleIndex]/(float)numRuns[sampleIndex]);
    }
    float getMeanActualInfectionRate(int sampleIndex){
        return actualInfectionRates[sampleIndex]/(float)numRuns[sampleIndex];
    }
};

SimulationParameters p;
PerSurveySimulationResults directRes;
PerSurveySimulationResults scaleUpRes;

std::ostream& operator<<(std::ostream& os, const std::unordered_set<int> &s)
{
    for (auto const& i: s) {
        os << i << " ";
    }
    return os;
}


void readSeedsFromFile(vector<int>& seeds, const string& filename){
    ifstream seedfile(filename);
    int seed;
    while (seedfile >> seed )
    {
        cout<<"reading seed"<<seed<<endl;
        seeds.push_back(seed);
    }
    seedfile.close();
}


void doSimulationRun(const SimulationParameters& p){
    UniformRandomSpreader spreader(p.spreaderSeed);
    TRnd rndGen(p.graphgenSeed);
    PUNGraph graph;
    if (!p.topologyFile.empty()){
        graph=LoadEdgeList<PUNGraph>(p.topologyFile.c_str());
    } else {
        if (p.graphModel.find("PrefA")!=string::npos){
            string parameters=p.graphModel.substr(5);
            int commaPos=parameters.find("-");
            int nodes=stoi(parameters.substr(0, commaPos));
            int degree=stoi(parameters.substr(commaPos+1));
            graph=GenPrefAttach (nodes,degree, rndGen );
        } else if (p.graphModel.find("RndG")!=string::npos){
            string parameters=p.graphModel.substr(4);
            int commaPos=parameters.find("-");
            int nodes=stoi(parameters.substr(0, commaPos));
            int edges=stoi(parameters.substr(commaPos+1));
            graph=GenRndGnm<PUNGraph>(nodes,edges,false,rndGen);
        }  else if (p.graphModel.find("CRing")!=string::npos){
            bool biased=false;
            string parameters;
            if (p.graphModel[5]=='B'){
                biased=true;
                parameters=p.graphModel.substr(6);
            } else {
                parameters=p.graphModel.substr(5);
            }
            int commaPos=parameters.find("-");
            int nodes=stoi(parameters.substr(0, commaPos));
            string remainder=parameters.substr(commaPos+1);
            int commaPos2=remainder.find("-");
            int outDeg=stoi(remainder.substr(0,commaPos2));
            double connProb=stod(remainder.substr(commaPos+1));
            cout<<"got parameters for CRing: "<<biased<<" "<<nodes<< " "<< outDeg<<" "<< connProb<<endl;
            graph=GenCircle<PUNGraph>(nodes,outDeg,false);
            TIntV allCircle;
            graph->GetNIdV(allCircle);
            int centerNode=graph->AddNode();
            for (TIntV::TIter it=allCircle.BegI(); it!=allCircle.EndI(); it++){
                if (rndGen.GetUniDev()<connProb){
                    graph->AddEdge(*it,centerNode);
                }
            }
            if (biased){
                spreader.setCenterNode(centerNode);
            }
        } else if (p.graphModel.find("Ring")!=string::npos){
            string parameters=p.graphModel.substr(4);
            int commaPos=parameters.find("-");
            int nodes=stoi(parameters.substr(0, commaPos));
            int outDeg=stoi(parameters.substr(commaPos+1));
            graph=GenCircle<PUNGraph>(nodes,outDeg,false);
        }
    }
    cout<<"loaded graph with "<<graph->GetNodes()<<" nodes and "<<graph->GetEdges()<<" edges."<<endl;
    int numToInfect=(int)(p.infectedFraction*graph->GetNodes());
    cout<<"numToInfect="<<numToInfect<<endl;
    spreader.computeInfectedFromGraph(graph, numToInfect);
    cout<<"infected"<<endl;
    DirectEstimationSurvey directSurvey(p.surveySeed);
    cout<<"created survey"<<endl;
    directSurvey.setGraph(graph);
    directSurvey.setInfectedIds(spreader.getInfectedIds());
   
    cout<<"starting run "<<p.runId<<endl;
    
    while (directSurvey.getNumSampled()<p.numToSample){
        SurveyResponse r=directSurvey.AbstractSurvey::getOneSurveyResponse();
        cout<<"TRACE-D "<<p.runId<<" "<<directSurvey.getNumSampled()-1<<" Direct: sampled: "<<r.responder<<" reach "<<r.reach.size()<<" ["<<r.reach<<"] infected "<<r.infected.size()<<" ["<<r.infected<<"]"<<endl;
        
        cout<<"TRACE-D-RES "<<p.runId<<" "<<directSurvey.getNumSampled()-1<<"     "
        <<p.infectedFraction<<" "
        <<spreader.getInfectionRate()<<" "
        <<directSurvey.getPositiveRate()<<" "
        <<r.infected.size()/(float)r.reach.size()<<" "<<endl;
        
        
        directRes.recordEstimation(p.runId, (int)directSurvey.getNumSampled()-1,directSurvey.getPositiveRate(), spreader.getInfectionRate());
    }
    directRes.recordFinalEstimation(p.runId, directSurvey.getPositiveRate(), spreader.getInfectionRate());
    cout<<"TRACE-D-RES "<<p.runId<<" Direct: pct_cli: "<<directSurvey.getPositiveRate()<<endl;
    
    NetworkScaleUpSurvey scaleUpSurvey(p.surveySeed, p.perturbationSeed);
    scaleUpSurvey.setError(p.error);
    scaleUpSurvey.setGraph(graph);
    scaleUpSurvey.setInfectedIds(spreader.getInfectedIds());
    scaleUpSurvey.setPrescribedReach(p.prescribedReach);

    while (scaleUpSurvey.getNumSampled()<p.numToSample){
        SurveyResponse r=scaleUpSurvey.AbstractSurvey::getOneSurveyResponse();
        cout<<"TRACE-S "<<p.runId<<" "<<scaleUpSurvey.getNumSampled()-1<<" ScaleUp: sampled: "<<r.responder<<" reach "<<r.reach.size()<<" ["<<r.reach<<"] infected "<<r.infected.size()<<" ["<<r.infected<<"]"<<endl;
        cout<<"TRACE-S-RES "<<p.runId<<" "<<scaleUpSurvey.getNumSampled()-1<<"     "
            <<p.infectedFraction<<" "
            <<spreader.getInfectionRate()<<" "
            <<scaleUpSurvey.getPositiveRate()<<" "
            <<r.infected.size()/(float)r.reach.size()<<" "<<endl;
            scaleUpRes.recordEstimation(p.runId, (int)scaleUpSurvey.getNumSampled()-1,scaleUpSurvey.getPositiveRate(), spreader.getInfectionRate());
    }
    scaleUpRes.recordFinalEstimation(p.runId, scaleUpSurvey.getPositiveRate(), spreader.getInfectionRate());
    cout<<"TRACE-S-RES "<<p.runId<<" ScaleUp: pct_cli: "<<scaleUpSurvey.getPositiveRate()<<endl;
   // cout<<"current path is "<<std::__fs::filesystem::current_path()<<endl;
    cout<<"RESULT "<<p.runId<<" "<<p.infectedFraction
    <<" "<<spreader.getInfectionRate()
    <<" "<<directSurvey.getPositiveRate()
    <<" "<<squareError(directSurvey.getPositiveRate(),spreader.getInfectionRate())
    <<" "<<scaleUpSurvey.getPositiveRate()
    <<" "<<squareError(scaleUpSurvey.getPositiveRate(),spreader.getInfectionRate())
    <<endl;
}

void printAggregateStats(){
    for (int index=0; index<directRes.estimations.size();index++){
        cout<<"AGG-RES "<<setw(12)<<index+1<<" "
            <<setw(12)<<setprecision(6)<<p.infectedFraction<<"    "
            
            <<setw(12)<<setprecision(6)<<directRes.getMeanActualInfectionRate(index)<<" "
            <<setw(12)<<setprecision(6)<<directRes.getNumRuns(index)<<" "
            <<setw(12)<<setprecision(6)<<directRes.getMeanEstimation(index)<<" "
            <<setw(12)<<setprecision(6)<<directRes.getRootMeanSquaredError(index)<<"   "
        
            <<setw(12)<<setprecision(6)<<scaleUpRes.getMeanActualInfectionRate(index)<<" "
            <<setw(12)<<setprecision(6)<<scaleUpRes.getNumRuns(index)<<" "
            <<setw(12)<<setprecision(6)<<scaleUpRes.getMeanEstimation(index)<<" "
            <<setw(12)<<setprecision(6)<<scaleUpRes.getRootMeanSquaredError(index)<<endl;
    }
    cout<<"AGG-RES "<<setw(12)<<"FINAL"<<" "
        <<setw(12)<<setprecision(6)<<p.infectedFraction<<"    "
        <<setw(12)<<setprecision(6)<<directRes.getFinalMeanActualInfectionRate()<<" "
        <<setw(12)<<setprecision(6)<<directRes.getFinalNumRuns()<<" "
        <<setw(12)<<setprecision(6)<<directRes.getFinalMeanEstimation()<<" "
        <<setw(12)<<setprecision(6)<<directRes.getFinalRootMeanSquaredError()<<"   "
        <<setw(12)<<setprecision(6)<<scaleUpRes.getFinalMeanActualInfectionRate()<<" "
        <<setw(12)<<setprecision(6)<<scaleUpRes.getFinalNumRuns()<<" "
        <<setw(12)<<setprecision(6)<<scaleUpRes.getFinalMeanEstimation()<<" "
        <<setw(12)<<setprecision(6)<<scaleUpRes.getFinalRootMeanSquaredError()<<endl;

}
                        
int main (int argc, char *argv[]) {
    CLI::App app{"Survey simulator: this simulator compares a direct-estimation survey with a network-scale-up survey on a social graph provided as input."};

    string seedFileName;
        // Define options
      
    
    app.add_option("-g,--graph", p.topologyFile, "name of the file containing the network topology")->check(CLI::ExistingFile);
    app.add_option("-G,--generate", p.graphModel, "generate graph instead of loading it");
    app.add_option("-s,--seeds", seedFileName, "name of the file containing the seeds for the random number generator. The simulator needs 3 seeds per run. It will run as many runs as there are seeds.")->required()->check(CLI::ExistingFile);
    app.add_option("-f,--fracInfected", p.infectedFraction, "fraction of infected individuals in the social network")->required();
    app.add_option("-S,--sampleSize", p.numToSample, "number of survey respondents")->required();
    app.add_option("-e,--error", p.error, "std deviation of error perturbation in scale-up estimation: default no error");
    app.add_option("-r,--reach", p.prescribedReach, "prescribed reach for scale up. The simulator takes the minimmum between this value and the actual number of friends a user has. Default value: 150");
    CLI11_PARSE(app, argc, argv);
  
    if (p.graphModel=="" && p.topologyFile==""){
        cerr<<"At least one between -g and -G is required"<<endl;
        exit(-1);
    }
    
  
    vector<int> seeds;
    cout<<"reading seed file"<<seedFileName<<endl;
    readSeedsFromFile(seeds, seedFileName);
    
 
    
   
    
    cout<<"doing runs with "<<p.topologyFile<<" and "<<seeds.size()<<" seeds"<<endl;
    int doneRuns=0;
    while (doneRuns <=seeds.size()-4){//we need three seeds per run
        p.spreaderSeed=seeds[doneRuns++];
        p.surveySeed=seeds[doneRuns++];
        p.perturbationSeed=seeds[doneRuns++];
        p.graphgenSeed=seeds[doneRuns++];
        doSimulationRun(p);
        p.runId++;
    }
   
    printAggregateStats();
    
   
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
