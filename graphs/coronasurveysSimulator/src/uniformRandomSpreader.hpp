//
//  UniformRandomSpreader.hpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef uniformRandomSpreader_hpp
#define uniformRandomSpreader_hpp

#include <stdio.h>
#include "abstractSpreader.hpp"

class UniformRandomSpreader: public AbstractSpreader{
  
public:
    UniformRandomSpreader(int randomSeed):AbstractSpreader(randomSeed){
    }
    virtual void computeInfectedFromGraph(const PUNGraph graph, int numToInfect);
    
};

#endif /* UniformRandomSpreader_hpp */
