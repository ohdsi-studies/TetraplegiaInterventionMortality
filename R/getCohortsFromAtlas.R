saveLocation <- "/Users/jreps/Documents/TetraplegiaInterventionMortality/optum"

targetIds <- c(18695, 18737, 18738)
outcomeId <- 6141

baseUrl <- keyring::key_get('WebAPI','jnj')
ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
  authMethod = 'windows',
  webApiUsername = keyring::key_get('webapi', 'username'),
  webApiPassword = keyring::key_get('webapi', 'password')
)

cohorts <- c(targetIds, outcomeId)
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl = baseUrl,
  cohortIds = cohorts,
  generateStats = T
)

phenotypeDefinitions <- PhenotypeLibrary::getPlCohortDefinitionSet(1152:1215)
phenotypeDefinitions$atlasId <- phenotypeDefinitions$cohortId
phenotypeDefinitions$logicDescription <- NA
phenotypeDefinitions$generateStats <- TRUE

cohortDefinitionSet <- rbind(cohortDefinitionSet, phenotypeDefinitions[,colnames(cohortDefinitionSet)])

saveRDS(phenotypeDefinitions, file.path("/Users/jreps/Documents/GitHub/TetraplegiaInterventionMortality", 'phenotypeDefinitions.rds'))
saveRDS(cohortDefinitionSet, file.path("/Users/jreps/Documents/GitHub/TetraplegiaInterventionMortality", 'cohortDefinitionSet.rds'))

