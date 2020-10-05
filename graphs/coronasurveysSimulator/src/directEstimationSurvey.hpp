//
//  DirectEstimationSurvey.hpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#ifndef directEstimationSurvey_hpp
#define directEstimationSurvey_hpp

#include <stdio.h>
#include "abstractSurvey.hpp"
class DirectEstimationSurvey: public AbstractSurvey {
public:
    DirectEstimationSurvey(int randomseed):AbstractSurvey(randomseed){};
    
    virtual SurveyResponse getOneSurveyResponse(int responderId);
    virtual long getNumSampled();
};
#endif /* DirectEstimationSurvey_hpp */
