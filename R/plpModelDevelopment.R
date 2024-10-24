saveLocation <- 'location to save results'
targetIds <- c(18695, 18737, 18738)
outcomeId <- 6141

database <- 'add database'
cdmDatabaseSchema <- 'add schema'
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

phenotypeDefinitions <- readRDS(file.path("/Users/jreps/Documents/GitHub/TetraplegiaInterventionMortality", 
                                          'phenotypeDefinitions.rds')
                                )

cohortDefinitionSet <- readRDS(file.path("/Users/jreps/Documents/GitHub/TetraplegiaInterventionMortality", 
                                         'cohortDefinitionSet.rds')
                               )

populationSettings <- PatientLevelPrediction::createStudyPopulationSettings(
  firstExposureOnly = T, 
  removeSubjectsWithPriorOutcome = T, 
  riskWindowEnd = 30*6, 
  requireTimeAtRisk = F
)

covariateSettings <- list(
  FeatureExtraction::createCohortBasedCovariateSettings(
    analysisId = 168, 
    covariateCohorts = phenotypeDefinitions[, c('cohortId','cohortName')], 
    valueType = "binary", 
    startDay = -9999, 
    endDay = -1
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
  saveDirectory = saveLocation
)