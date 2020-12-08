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
    int centerId=-1;
public:
    UniformRandomSpreader(int randomSeed):AbstractSpreader(randomSeed){
    }
    virtual void computeInfectedFromGraph(const PUNGraph graph, int numToInfect);
    void setCenterNode(int cId){this->centerId=cId;}
    
};

#endif /* UniformRandomSpreader_hpp */
