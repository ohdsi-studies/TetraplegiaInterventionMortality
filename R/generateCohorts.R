cohortDefinitionSet <- loadRDS(file.path("/Users/jreps/Documents/GitHub/TetraplegiaInterventionMortality", 
                                         'cohortDefinitionSet.rds'
                                         ))

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


# generate the cohort table
CohortGenerator::createCohortTables(
  connectionDetails = connectionDetails, 
  cohortDatabaseSchema = cohortDatabaseSchema, 
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTableName)
)

# execute the cohorts into the table
CohortGenerator::generateCohortSet(
  connectionDetails = connectionDetails, 
  cdmDatabaseSchema = cdmDatabaseSchema, 
  cohortDatabaseSchema = cohortDatabaseSchema, 
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTableName), 
  cohortDefinitionSet = cohortDefinitionSet
)
