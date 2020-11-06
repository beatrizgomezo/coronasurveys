#include "breadthFirstExploration.hpp"
//#include<iostream>
//using namespace std;
void BreadthFirstExploration::doBFS(int levels){
   int startNode=graph->GetRndNId(rnd);
   list<int> toVisit;
   toVisit.push_back(startNode);
   int level=0;
   while (!toVisit.empty() && level<=levels){
     int levelSize=toVisit.size();
     while (levelSize-- > 0 ){
       int curNode=toVisit.front();       
       toVisit.pop_front();
       //if not already visited
       if (bfsNodes.find(curNode)==bfsNodes.end()){//this is inefficient, an array of booleans would be better, but I do not care for now.
	 bfsNodes.insert(curNode);
	 TUNGraph::TNodeI myNode=graph->GetNI(curNode);
	 // get node's neighbors
	 int degree=myNode.GetDeg();	 
	 for (int i=0; i<degree;i++){
	   toVisit.push_back(myNode.GetNbrNId(i));
	 }
       }       
     }
     level++;     
   }
 }

