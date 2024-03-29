library(dplyr)
library(sleuth)
library(topGO)

newFuncadelicGo <- function(x, database, mode, intGenes, cutoff = 0.01) {
  myGOdata <- new("topGOdata", 
                  description = '', ontology = database,
                  allGenes=x,
                  geneSel=selector,
                  annot=annFUN.gene2GO, gene2GO=full_mapping, nodeSize=10)
  resultFisher <- runTest(myGOdata, algorithm = "weight01", statistic = "fisher")

  allRes <- GenTable(myGOdata, weight01Fisher = resultFisher,
                     orderBy = "weight01Fisher", ranksOf = "weight01Fisher", topNodes = 35)
  allRes$weight01Fisher <- as.double(allRes$weight01Fisher)
  allRes[is.na(allRes)] <- 0
  if (mode=='table') {
    allRes$Percentage_of_Differentially_Expressed_Genes_from_number_of_DEGs <- ((allRes$Significant / nrow(intGenes))*100) %>% round(2)
    allRes$Percentage_of_Differentially_Expressed_Genes_from_Number_Of_Annotated_Genes <- ((allRes$Significant / allRes$Annotated)*100) %>% round(2)
    allRes <- allRes %>% filter(weight01Fisher < cutoff)
    return(allRes)
  } else if (mode=='pvals'){
    retlist <- (allRes %>% filter(weight01Fisher < 0.01))$weight01Fisher
    names(retlist) <- (allRes %>% filter(weight01Fisher < 0.01))$GO.ID
    return(retlist)
  }
  else if(mode=='graph') {
    GoGraph <- showSigOfNodes(myGOdata, score(resultFisher), firstSigNodes = allRes %>% filter(weight01Fisher < 0.01) %>% nrow(), useInfo = "all")$dag
    return(GoGraph)
  }
}

### full_mapping stores mapping data frame as shown in http://avrilomics.blogspot.com/2015/07/using-topgo-to-test-for-go-term.html?m=1
### the latter operations are equivalent to those used by Avrilomics

geneUniverse <- full_mapping %>% names()
geneList <- factor(as.integer(geneUniverse %in% GO_dummy))
names(geneList_up) <- geneUniverse

iterating_function_GO <- function(subset, ont, cutoff){
  dummy <- subset %>% dplyr::select(target_id) %>% mutate(target_id = as.character(target_id)) %>% unlist()
  geneList <- factor(as.integer(geneUniverse %in% dummy))
  names(geneList) <- geneUniverse
  name_val <- paste(ont, substitute(subset) %>% as.character(), sep = '_')
  assign(name_val, newFuncadelicGo(geneList, ont, mode = 'table', intGenes=subset, cutoff = cutoff), envir = .GlobalEnv)
  }
  
  ### $sleuth_subset stores a sleuth dataset being annotated
  ontologies <- c('BP', 'CC', 'MF')
  sapply(ontologies, function(x) iterating_function_GO(sleuth_subset))
  
