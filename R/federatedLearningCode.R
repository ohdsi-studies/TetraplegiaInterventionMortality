siteId <- 'database id for federated algorithm'
outputFolder <- 'location of output folder' # json for pda should be in this location

# Database connection settings
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
  outcomeTable = cohortTableName,
  targetId = c(18695, 18737, 18738)[1], # also want the others
  outcomeId = 6141
)


# define covariateSettings:

phenotypeDefinitions <- PhenotypeLibrary::getPlCohortDefinitionSet(1152:1215)
phenotypeDefinitions$atlasId <- phenotypeDefinitions$cohortId
phenotypeDefinitions$logicDescription <- NA
phenotypeDefinitions$generateStats <- TRUE

# Note: may want to select 5-10 of the phenotype features

# below creates cohort features for each cohort in phenotypeDefinitions
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
    useDemographicsAgeGroup = T # may not want all ages!
  )
)

# get plpData
plpData <-  PatientLevelPrediction::getPlpData(
  databaseDetails = databaseDetails, 
  covariateSettings = covariateSettings, 
  restrictPlpDataSettings = PatientLevelPrediction::createRestrictPlpDataSettings()
)

# create population
labels <- PatientLevelPrediction::createStudyPopulation(
  plpData = plpData, 
  outcomeId = 6141, 
  populationSettings = PatientLevelPrediction::createStudyPopulationSettings(
    firstExposureOnly = T, 
    removeSubjectsWithPriorOutcome = T, 
    riskWindowEnd = 30, 
    requireTimeAtRisk = F
  )
)

# convert Plp Data to matrix
dataObject <- PatientLevelPrediction::toSparseM(
  plpData = plpData, 
  cohort = labels
)
#sparse matrix: dataObject$dataMatrix
#labels: dataObject$labels

columnDetails <- as.data.frame(dataObject$covariateRef)
cnames <- columnDetails$covariateName[order(columnDetails$columnId)]

ipMat <- as.matrix(dataObject$dataMatrix)
ipdata <- as.data.frame(ipMat)

# Note: may need to edit the column names to make then friendly
## colnames(ipdata) <- c(...)

# Note: get PDA control json and save it into outputFolder

# execute PDA - this will create a json with summary results 
pda::pda(
  ipdata = ipdata, 
  site_id = siteId, 
  dir = outputFolder
)