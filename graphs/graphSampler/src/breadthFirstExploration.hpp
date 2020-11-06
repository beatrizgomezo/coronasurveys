//
//  breadthFirstExploration.hpp
//  coronasurveysSimulator
//
//  Created by Davide Frey on 21/07/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef breadthFirstExploration_hpp
#define breadthFirstExploration_hpp

#include <stdio.h>
#include "Snap.h"
#include "shash.h"
#include <list>
#include <unordered_set>
#include <string>
using namespace TSnap;
using namespace std;

class BreadthFirstExploration{
protected:

  PUNGraph graph;
  unordered_set<int> bfsNodes;
  TRnd rnd;
public:
  BreadthFirstExploration(int seed, PUNGraph g){
    graph=g;
    rnd.PutSeed(seed);
  }
  
  void doBFS(int levels);
  const unordered_set<int>& getBFSNodes() const {return bfsNodes;}
  
  
};

#endif;
