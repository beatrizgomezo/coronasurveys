//
//  DirectEstimationSurvey.cpp
//  coronasurveysSimulatorApp
//
//  Created by Davide Frey on 02/10/2020.
//  Copyright © 2020 Davide Frey. All rights reserved.
//

#include "directEstimationSurvey.hpp"
using namespace std;

SurveyResponse  DirectEstimationSurvey::getOneSurveyResponse(int responderId){
    SurveyResponse r;
    r.responder=responderId;
    recordSampleFromResponse(r, r.responder);
    return r;
}

long DirectEstimationSurvey::getNumSampled(){
    return getNumActuallySampled();
}
