
## testing ##

library(devtools)
library(readr)
# setwd('~/Work/iAtlas/Subtypes/Subtype-Classifier/')
# using the package

devtools::install_github("Gibbsdavidl/ImmuneSubtypeClassifier", force = T)
reload(pkgload::inst('ImmuneSubtypeClassifier'))
library(ImmuneSubtypeClassifier)

# PanCancer batch corrected expression matrix
ebpp <- read_tsv('~/Work/PanCancer_Data/EBPlusPlusAdjustPANCAN_IlluminaHiSeq_RNASeqV2.geneExp.tsv')

geneList <- str_split(ebpp$gene_id, pattern='\\|')
geneSymbols <- unlist( lapply(geneList, function(a) a[1]) )

# add to a data dir.
reportedScores <- read.table('~/Work/PanCancer_Data/five_signature_mclust_ensemble_results.tsv.gz', sep='\t', header=T, stringsAsFactors = F)
rownames(reportedScores) <- str_replace_all(reportedScores$AliquotBarcode, pattern = '\\.', replacement = '-')

# shared barcodes
bs <- intersect(rownames(reportedScores),colnames(ebpp))

# remove duplicate gene names (mostly '?'s)
ddx <- which(duplicated(geneSymbols))

# main matrices
X <- as.data.frame(ebpp[-ddx, rownames(reportedScores)])
rownames(X) <- geneSymbols[-ddx]
Xmat <- as.matrix(X)
Y <- reportedScores[,"ClusterModel1"]

#faster to start from here#
#save(Xmat, Y, geneList, file='~/ebpp_with_subtypes.rda')
#load('~/ebpp_with_subtypes.rda')

# sample our training and testing groups
idx <- sample(1:ncol(Xmat), size = 0.2 * ncol(Xmat), replace=F)
jdx <- setdiff(1:ncol(Xmat), idx)
Xtrain <- Xmat[,jdx]
Ytrain <- Y[jdx]
Xtest  <- Xmat[,idx]
Ytest <- Y[idx]

# save memory
rm(ebpp, X, Xmat)
gc()

#fitting all models
breakVec=c(0, 0.25, 0.5, 0.75, 1.0)
#breakVec=c(0, 0.33, 0.66, 1.0)
params=list(max_depth = 5, eta = 0.5, nrounds = 100, nthread = 5, nfold=5)

# list of models
mods <- fitSubtypeModel(Xtrain, Ytrain, ptail=0.02, params=params, breakVec=breakVec)

# calling subtypes on the test set
calls <- callSubtypes(mods, Xtest, Ytest)

# model performance plots
perfs <- subtypePerf(calls, Ytest)

library(gridExtra)
grid.arrange(perfs[[1]]$plot,perfs[[2]]$plot,perfs[[3]]$plot,perfs[[4]]$plot,perfs[[5]]$plot,perfs[[6]]$plot, ncol=6, nrow=1 )

