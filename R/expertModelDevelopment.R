saveLocation <- 'location to save results'
targetIds <- c(18695, 18737, 18738)
outcomeId <- 6141
expertCohortIds <-  c(1791148, 1791143, 1791144, 1791145, 1791140)

# end stage renal disease: 12480
# pressure injury: 18740
# COPD: 11171
# peripheral vascular disease: 6218 
# Failure to thrive: 18741 
expertCohortIds <-  c(12480,18740,11171,6218, 18741)

database <- 'optum ehr'
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = keyring::key_get('dbms', 'all'),
  server = keyring::key_get('server', database),
  user = keyring::key_get('user', 'all'),
  password = keyring::key_get('pw', 'all'),
  port = keyring::key_get('port', 'all')#,
)
cohortDatabaseSchema <- keyring::key_get('cohortDatabaseSchema', 'all')
cdmDatabaseSchema <- keyring::key_get('cdmDatabaseSchema',  database)
cohortTableName <- 'tetra_inter'

databaseDetails <- PatientLevelPrediction::createDatabaseDetails(
  connectionDetails = connectionDetails, 
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema =  cohortDatabaseSchema, 
  cohortTable = cohortTableName, 
  outcomeDatabaseSchema = cohortDatabaseSchema, 
  outcomeTable = cohortTableName
)


cohortDefinitionSet <- readRDS(file.path("/Users/jreps/Documents/GitHub/TetraplegiaInterventionMortality", 
                                         'cohortDefinitionSet.rds')
                               )

cohortDefinitionSetExtras <- cohortDefinitionSet[cohortDefinitionSet$cohortId %in% expertCohortIds, c('cohortId','cohortName')]

# time-at-risk
populationSettings <- PatientLevelPrediction::createStudyPopulationSettings(
  firstExposureOnly = T, 
  removeSubjectsWithPriorOutcome = T, 
  riskWindowEnd = 30*6, # 6 month
  requireTimeAtRisk = F
)

covariateSettings <- list(
  FeatureExtraction::createCohortBasedCovariateSettings(
    analysisId = 168, 
    covariateCohorts = cohortDefinitionSetExtras, 
    valueType = "binary", 
    startDay = -9999, 
    endDay = -1, 
    covariateCohortDatabaseSchema = cohortDatabaseSchema, 
    covariateCohortTable = cohortTableName# add extras
  ), 
  FeatureExtraction::createCovariateSettings(
    useDemographicsGender = T, 
    useDemographicsAgeGroup = T
  )
)

modelDesigns <- lapply(1:3, function(i){
  PatientLevelPrediction::createModelDesign(
    targetId = targetIds[i], 
    outcomeId = outcomeId, 
    restrictPlpDataSettings = PatientLevelPrediction::createRestrictPlpDataSettings(), 
    populationSettings = populationSettings, 
    covariateSettings = covariateSettings, 
    featureEngineeringSettings = PatientLevelPrediction::createFeatureEngineeringSettings(), 
    sampleSettings = PatientLevelPrediction::createSampleSettings(), 
    preprocessSettings = PatientLevelPrediction::createPreprocessSettings(), 
    modelSettings = PatientLevelPrediction::setLassoLogisticRegression(), 
    splitSettings = PatientLevelPrediction::createDefaultSplitSetting(splitSeed = 123), 
    runCovariateSummary = T
  )
})

PatientLevelPrediction::runMultiplePlp(
  databaseDetails = databaseDetails, 
  modelDesignList = modelDesigns, 
  cohortDefinitions = cohortDefinitionSet, 
  saveDirectory = file.path(saveLocation,'expert')
)

PatientLevelPrediction::viewMultiplePlp(file.path(saveLocation,'expert'))
  
  
