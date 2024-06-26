
# --------------------- Uniform Clusters ----------------------

#' @details `mergeUniformCellsClusters()` takes in a **uniform**
#'   *clusterization* and iteratively checks whether merging two *near clusters*
#'   would form a **uniform** *cluster* still. Multiple thresholds will be used
#'   from \eqn{1.37} up to the given one in order to prioritize merge of the
#'   best fitting pairs.
#'
#'   This function uses the *cosine distance* to establish the *nearest clusters
#'   pairs*. It will use the [checkClusterUniformity()] function to check
#'   whether the merged *clusters* are **uniform**. The function will stop once
#'   no *tested pairs* of clusters are mergeable after testing all pairs in a
#'   single batch
#'
#' @param objCOTAN a `COTAN` object
#' @param clusters The *clusterization* to merge. If not given the last
#'   available *clusterization* will be used, as it is probably the most
#'   significant!
#' @param GDIThreshold the threshold level that discriminates uniform clusters.
#'   It defaults to \eqn{1.43}
#' @param ratioAboveThreshold the fraction of genes allowed to be above the
#'   `GDIThreshold`. It defaults to \eqn{1\%}
#' @param batchSize Number pairs to test in a single round. If none of them
#'   succeeds the merge stops. Defaults to \eqn{2 (\#cl)^{2/3}}
#' @param allCheckResults An optional `data.frame` with the results of previous
#'   checks about the merging of clusters. Useful to restart the *merging*
#'   process after an interruption.
#' @param cores number of cores to use. Default is 1.
#' @param optimizeForSpeed Boolean; when `TRUE` `COTAN` tries to use the `torch`
#'   library to run the matrix calculations. Otherwise, or when the library is
#'   not available will run the slower legacy code
#' @param deviceStr On the `torch` library enforces which device to use to run
#'   the calculations. Possible values are `"cpu"` to us the system *CPU*,
#'   `"cuda"` to use the system *GPUs* or something like `"cuda:0"` to restrict
#'   to a specific device
#' @param useDEA Boolean indicating whether to use the *DEA* to define the
#'   distance; alternatively it will use the average *Zero-One* counts, that is
#'   faster but less precise.
#' @param distance type of distance to use. Default is `"cosine"` for *DEA* and
#'   `"euclidean"` for *Zero-One*. Can be chosen among those supported by
#'   [parallelDist::parDist()]
#' @param hclustMethod It defaults is `"ward.D2"` but can be any of the methods
#'   defined by the [stats::hclust()] function.
#' @param saveObj Boolean flag; when `TRUE` saves intermediate analyses and
#'   plots to file
#' @param outDir an existing directory for the analysis output. The effective
#'   output will be paced in a sub-folder.
#'
#' @returns a `list` with:
#'   * `"clusters"` the merged cluster labels array
#'   * `"coex"` the associated `COEX` `data.frame`
#'
#' @export
#'
#' @importFrom rlang is_empty
#' @importFrom rlang set_names
#'
#' @importFrom assertthat assert_that
#'
#' @importFrom Matrix t
#'
#' @importFrom parallelDist parDist
#'
#' @importFrom stats hclust
#' @importFrom stats as.dendrogram
#' @importFrom stats cophenetic
#'
#' @importFrom stringr str_split
#' @importFrom stringr fixed
#'
#' @importFrom dendextend get_nodes_attr
#'
#' @importFrom zeallot %<-%
#' @importFrom zeallot %->%
#'
#' @examples
#' data("test.dataset")
#'
#' objCOTAN <- automaticCOTANObjectCreation(raw = test.dataset,
#'                                          GEO = "S",
#'                                          sequencingMethod = "10X",
#'                                          sampleCondition = "Test",
#'                                          cores = 6L,
#'                                          saveObj = FALSE)
#'
#' groupMarkers <- list(G1 = c("g-000010", "g-000020", "g-000030"),
#'                      G2 = c("g-000300", "g-000330"),
#'                      G3 = c("g-000510", "g-000530", "g-000550",
#'                             "g-000570", "g-000590"))
#' gdiPlot <- GDIPlot(objCOTAN, genes = groupMarkers, cond = "test")
#' plot(gdiPlot)
#'
#' ## Here we override the default GDI threshold as a way to speed-up
#' ## calculations as higher threshold implies less stringent uniformity
#' ## It real applications it might be appropriate to change the threshold
#' ## in cases of relatively low genes/cells number, or in cases when an
#' ## rough clusterization is needed in the early satges of the analysis
#' ##
#'
#' splitList <- cellsUniformClustering(objCOTAN, cores = 6L,
#'                                     optimizeForSpeed = TRUE,
#'                                     deviceStr = "cuda",
#'                                     initialResolution = 0.8,
#'                                     GDIThreshold = 1.46, saveObj = FALSE)
#'
#' clusters <- splitList[["clusters"]]
#'
#' firstCluster <- getCells(objCOTAN)[clusters %in% clusters[[1L]]]
#' firstClusterIsUniform <-
#'   checkClusterUniformity(objCOTAN, GDIThreshold = 1.46,
#'                          ratioAboveThreshold = 0.01,
#'                          cluster = clusters[[1L]], cells = firstCluster,
#'                          cores = 6L, optimizeForSpeed = TRUE,
#'                          deviceStr = "cuda", saveObj = FALSE)[["isUniform"]]
#'
#' objCOTAN <- addClusterization(objCOTAN,
#'                               clName = "split",
#'                               clusters = clusters)
#'
#' objCOTAN <- addClusterizationCoex(objCOTAN,
#'                                   clName = "split",
#'                                   coexDF = splitList[["coex"]])
#'
#' identical(reorderClusterization(objCOTAN)[["clusters"]], clusters)
#'
#' mergedList <- mergeUniformCellsClusters(objCOTAN,
#'                                         GDIThreshold = 1.43,
#'                                         ratioAboveThreshold = 0.02,
#'                                         batchSize = 2L,
#'                                         clusters = clusters,
#'                                         cores = 6L,
#'                                         optimizeForSpeed = TRUE,
#'                                         deviceStr = "cpu",
#'                                         distance = "cosine",
#'                                         hclustMethod = "ward.D2",
#'                                         saveObj = FALSE)
#'
#' objCOTAN <- addClusterization(objCOTAN,
#'                               clName = "merged",
#'                               clusters = mergedList[["clusters"]],
#'                               coexDF = mergedList[["coex"]])
#'
#' identical(reorderClusterization(objCOTAN), mergedList)
#'
#' @rdname UniformClusters
#'

mergeUniformCellsClusters <- function(objCOTAN,
                                      clusters = NULL,
                                      GDIThreshold = 1.43,
                                      ratioAboveThreshold = 0.01,
                                      batchSize = 0L,
                                      allCheckResults = data.frame(),
                                      cores = 1L,
                                      optimizeForSpeed = TRUE,
                                      deviceStr = "cuda",
                                      useDEA = TRUE,
                                      distance = NULL,
                                      hclustMethod = "ward.D2",
                                      saveObj = TRUE,
                                      outDir = ".") {
  logThis("Merging cells' uniform clustering: START", logLevel = 2L)

  assert_that(estimatorsAreReady(objCOTAN),
              msg = paste("Estimators lambda, nu, dispersion are not ready:",
                          "Use proceeedToCoex() to prepare them"))

  assert_that(isa(allCheckResults, "data.frame"),
              (is_empty(allCheckResults) ||
                 identical(colnames(allCheckResults),
                           c("isUniform", "fractionAbove", "ratioQuantile",
                             "size", "GDIThreshold", "ratioAboveThreshold",
                             "cluster_1", "cluster_2"))),
              msg = "Previous results passed in are of wrong type or columns")

  outputClusters <- clusters
  if (is_empty(outputClusters)) {
    # pick the last clusterization
    outputClusters <- getClusters(objCOTAN)
  }

  outputClusters <- factorToVector(outputClusters)

  if (batchSize == 0L) {
    # default is twice the (2/3) power of the number of clusters
    numCl <- length(unique(outputClusters))
    batchSize <- as.integer(ceiling(1.2 * numCl^(2.0 / 3.0)))
    rm(numCl)
  }

  cond <- getMetadataElement(objCOTAN, datasetTags()[["cond"]])

  outDirCond <- file.path(outDir, cond)
  if (!dir.exists(outDirCond)) {
    dir.create(outDirCond)
  }

  mergeOutDir <- file.path(outDirCond, "leafs_merge")
  if (isTRUE(saveObj) && !dir.exists(mergeOutDir)) {
    dir.create(mergeOutDir)
  }

  mergedName <- function(cl1, cl2) {
    return(paste0(min(cl1, cl2), "_", max(cl1, cl2), "-merge"))
  }

  pairIsUniform <- function(mergedClName, allCheckResults,
                            GDIThreshold, ratioAboveThreshold) {
    return(isClusterUniform(
      GDIThreshold, ratioAboveThreshold,
      allCheckResults[mergedClName, "ratioQuantile"],
      allCheckResults[mergedClName, "fractionAbove"],
      allCheckResults[mergedClName, "GDIThreshold"],
      allCheckResults[mergedClName, "ratioAboveThreshold"]))
  }

  hasBeenChecked <- function(mergedClName, allCheckResults,
                             GDIThreshold, ratioAboveThreshold) {
    if (!(mergedClName %in% rownames(allCheckResults))) {
      return(FALSE)
    } else {
      return(!is.na(pairIsUniform(mergedClName, allCheckResults,
                                  GDIThreshold, ratioAboveThreshold)))
    }
  }


  selectPairsList <- function(pList, batchSize, allCheckResults,
                              GDIThreshold, ratioAboveThreshold) {
    # drop the already tested pairs
    pNamesList <- lapply(pList, function(p) mergedName(p[[1L]], p[[2L]]))

    pNamesUntested <-
      lapply(pNamesList, function(pName, allRes,
                                  GDIThreshold, ratioAboveThreshold) {
        !hasBeenChecked(pName, allRes, GDIThreshold, ratioAboveThreshold)
      }, allCheckResults, GDIThreshold, ratioAboveThreshold)
    pNamesUntested <- unlist(pNamesUntested)

    pList <- pList[pNamesUntested]

    # take the first N remaining
    numPairsToTest <- min(batchSize, length(pList))
    return(pList[seq_len(numPairsToTest)])
  }

  testPairListMerge <- function(pList, outputClusters, allCheckResults,
                                GDIThreshold, ratioAboveThreshold) {
    logThis(paste0("New clusters pairs to be tested for merging:\n",
                   paste(pList, collapse = " ")), logLevel = 1L)

    for (p in pList) {
      logThis("*", logLevel = 1L, appendLF = FALSE)

      c(cl1, cl2) %<-% p

      if (!(any(outputClusters %in% cl1) && any(outputClusters %in% cl2))) {
        logThis(paste0("Clusters ", cl1, " or ", cl2,
                       " is now missing due to previous merges: skip."),
                logLevel = 3L)
        next
      }

      mergedClName <- mergedName(cl1, cl2)

      logThis(mergedClName, logLevel = 3L)

      if (hasBeenChecked(mergedClName, allCheckResults,
                         GDIThreshold, ratioAboveThreshold)) {
        logThis(paste("Clusters", cl1, "and", cl2, "already analyzed: skip."),
                logLevel = 3L)
        next
      }
      # else we have insufficient information about the pair [re]calculate

      mergedCluster <- names(outputClusters)[outputClusters %in% c(cl1, cl2)]

      checkResults <- tryCatch(
        checkClusterUniformity(objCOTAN,
                               clusterName = mergedClName,
                               cells = mergedCluster,
                               GDIThreshold = GDIThreshold,
                               ratioAboveThreshold = ratioAboveThreshold,
                               cores = cores,
                               optimizeForSpeed = optimizeForSpeed,
                               deviceStr = deviceStr,
                               saveObj = saveObj,
                               outDir = mergeOutDir),
        error = function(err) {
          logThis(paste("While checking cluster uniformity", err),
                  logLevel = 0L)
          logThis("Marking pair as not mergable", logLevel = 1L)
          errorCheckResults[["size"]] <- length(mergedCluster)
          errorCheckResults[["GDIThreshold"]] <- GDIThreshold
          errorCheckResults[["ratioAboveThreshold"]] <- ratioAboveThreshold
          errorCheckResults[["cluster_1"]] <- cl1
          errorCheckResults[["cluster_2"]] <- cl2
          return(errorCheckResults)
        })

      gc()

      checkResults <- append(checkResults,
                             list("cluster_1" = cl1, "cluster_2" = cl2))
      allCheckResults <- rbind(allCheckResults, checkResults)
      rownames(allCheckResults)[[nrow(allCheckResults)]] <- mergedClName

      logThis(paste("Clusters", cl1, "and", cl2,
                    if(checkResults[["isUniform"]]) { "can" } else { "cannot" },
                    "be merged"), logLevel = 1L)
    }

    return(allCheckResults)
  }

  equivFractionAbove <- function(GDIThreshold, ratioAboveThreshold,
                                 ratioQuantile, fractionAbove,
                                 usedGDIThreshold, usedRatioAbove) {
    assert_that(!is.na(GDIThreshold), !is.na(ratioAboveThreshold),
                !is.na(usedGDIThreshold), !is.na(usedRatioAbove),
                GDIThreshold >= 0.0, ratioAboveThreshold >= 0.0,
                ratioAboveThreshold <= 1.0, msg = "wrong thresholds passed in")
    if (GDIThreshold == usedGDIThreshold) {
      return(fractionAbove)
    } else if (ratioAboveThreshold == usedRatioAbove) {
      # here we assume exponential taper
      fractionAbove <- max(fractionAbove, 1.0e-4)
      if (abs(usedGDIThreshold - ratioQuantile) <= 1e-4) {
        return(NA)
      }
      exponent <- (GDIThreshold - usedGDIThreshold) /
                    (usedGDIThreshold - ratioQuantile)
      return(fractionAbove * (fractionAbove/usedRatioAbove)^exponent)
    } else {
      return(NA)
    }
  }

  mergeAllClusters <- function(outputClusters, allCheckResults,
                               GDIThreshold, ratioAboveThreshold) {
    #filter out missing clusters
    rowsToKeep <- vapply(seq_len(nrow(allCheckResults)),
                         function(r) {
                           cl1OK <- any(outputClusters %in%
                                          allCheckResults[r, "cluster_1"])
                           cl2OK <- any(outputClusters %in%
                                          allCheckResults[r, "cluster_2"])
                           return(cl1OK &&cl2OK)
                         },
                         logical(1L))
    checkRes <- allCheckResults[rowsToKeep, , drop = FALSE]

    # filter out non uniform pairs
    rowsToKeep <- vapply(seq_len(nrow(checkRes)),
                         function(r) {
                           mergedName <- rownames(checkRes)[r]
                           return(isTRUE(pairIsUniform(
                             mergedName, checkRes,
                             GDIThreshold, ratioAboveThreshold)))
                         },
                         logical(1L))
    checkRes <- checkRes[rowsToKeep, , drop = FALSE]

    perm <- seq_len(nrow(checkRes))
    if (length(unique(checkRes[, "GDIThreshold", drop = TRUE])) == 1L) {
      # order results by least fraction
      perm <- order(checkRes[, "fractionAbove", drop = TRUE])
    } else if (length(unique(checkRes[, "ratioAboveThreshold",
                                      drop = TRUE])) == 1L) {
      perm <- order(checkRes[, "ratioQuantile", drop = TRUE])
    } else {
      # mixed case: convert to least faction estimates and
      # order results by least fraction

      fractionsAbove <-
        vapply(seq_len(nrow(checkRes)),
               function(r) {
                 equivFractionAbove(GDIThreshold, ratioAboveThreshold,
                                    checkRes[r, "ratioQuantile"],
                                    checkRes[r, "fractionAbove"],
                                    checkRes[r, "GDIThreshold"],
                                    checkRes[r, "ratioAboveThreshold"])
               },
               double(1L))
      perm <- order(fractionsAbove)
    }
    checkRes <- checkRes[perm, , drop = FALSE]

    #operate the merges
    for (r in seq_len(nrow(checkRes))) {
      cl1 <- checkRes[r, "cluster_1"]
      cl2 <- checkRes[r, "cluster_2"]
      if (!(any(outputClusters %in% cl1) && any(outputClusters %in% cl2))) {
        logThis(paste0("One or both of the clusters ", cl1, ", ", cl2,
                      " is no more in the clusterization"), logLevel = 3L)
        next
      }
      logThis(paste("Clusters", cl1, "and", cl2, "will be merged"),
              logLevel = 2L)
      outputClusters <- mergeClusters(outputClusters, names = c(cl1, cl2),
                                      mergedName = mergedName(cl1, cl2))
      outputClusters <- factorToVector(outputClusters)
    }
    return(outputClusters)
  }

  iter <- 0L
  errorCheckResults <- list("isUniform" = FALSE, "fractionAbove" = NA,
                            "ratioQuantile" = NA, "size" = NA,
                            "GDIThreshold" = GDIThreshold,
                            "ratioAboveThreshold" = ratioAboveThreshold,
                            "cluster_1" = NA, "cluster_2" = NA)

  thresholdGap <- max(GDIThreshold - 1.37, 0.0)
  numThresholds <- ceiling(thresholdGap / 0.03)
  allThresholds <- 1.37 +
    c(0L, seq_len(numThresholds)) * thresholdGap / numThresholds

  for (threshold in allThresholds) {
    logThis(paste0("Start merging nearest clusters: threshold ", threshold),
            logLevel = 2L)
    repeat {
      iter <- iter + 1L
      logThis(paste0("Start merging nearest clusters: iteration ", iter),
              logLevel = 3L)

      firstBatch <- is_empty(allCheckResults)
      oldNumClusters <- length(unique(outputClusters))

      clDist <- distancesBetweenClusters(objCOTAN, clusters = outputClusters,
                                         useDEA = useDEA, distance = distance)
      gc()

      if (isTRUE(saveObj)) tryCatch({
          pdf(file.path(mergeOutDir, paste0("dend_iter_", iter, "_tau_",
                                            threshold, "_plot.pdf")))

          hcNorm <- hclust(clDist, method = hclustMethod)
          plot(as.dendrogram(hcNorm))

          dev.off()
        },
        error = function(err) {
          logThis(paste("While saving dendogram plot", err), logLevel = 0L)
        })

      # We will check whether it is possible to merge a list of cluster pairs.
      # These pairs correspond to N lowest distances as calculated before
      # If none of them can be merges, the loop stops

      allLabels <- labels(clDist)
      assert_that(length(allLabels) == oldNumClusters,
                  msg = "Internal error - distance has no labels")

      # create all pairings with different clusters
      pList <- rbind(rep((1L:oldNumClusters), each  = oldNumClusters),
                     rep((1L:oldNumClusters), times = oldNumClusters))
      pList <- pList[, pList[1L, ] < pList[2L, ], drop = FALSE]
      pList <- matrix(allLabels[pList], nrow = 2L)

      # reorder the pairings using the distance and pick only those necessary
      pList <- as.list(as.data.frame(pList))

      # reorder based on distance
      pList <- pList[order(clDist)]

      pList <- selectPairsList(pList, batchSize, allCheckResults,
                               threshold, ratioAboveThreshold)

      allCheckResults <-
        testPairListMerge(pList, outputClusters, allCheckResults,
                          threshold, ratioAboveThreshold)

      if (!firstBatch) {
        outputClusters <- mergeAllClusters(outputClusters, allCheckResults,
                                           threshold, ratioAboveThreshold)
      }

      newNumClusters <- length(unique(outputClusters))
      if (newNumClusters == 1L) {
        # nothing left to do: stop!
        break
      }

      if (isTRUE(saveObj)) tryCatch({
          outFile <- file.path(mergeOutDir,
                               paste0("merge_clusterization_", iter, ".csv"))
          write.csv(outputClusters, file = outFile)

          outFile <- file.path(mergeOutDir,
                               paste0("all_check_results_", iter, ".csv"))
          write.csv(allCheckResults, file = outFile)
        },
        error = function(err) {
          logThis(paste("While saving current clusterization", err),
                  logLevel = 0L)
        })
      if (firstBatch) {
        logThis("Finished the first batch - no merges were executed",
                logLevel = 3L)
      } else if (newNumClusters == oldNumClusters) {
        logThis(paste("None of the", nrow(allCheckResults),
                      "tested cluster pairs could be merged"), logLevel = 3L)

        # No merges happened -> too low probability of new merges...
        break
      } else {
        logThis(paste("Executed", (oldNumClusters - newNumClusters),
                      "merges out of potentially", nrow(allCheckResults)),
                logLevel = 3L)
      }
    }
    logThis(paste("Executed all merges for threshold ", threshold),
            logLevel = 3L)
  }

  logThis(paste0("The final merged clusterization contains [",
                 length(unique(outputClusters)), "] different clusters: ",
                 toString(sort(unique(outputClusters)))), logLevel = 1L)

  # replace the clusters' tags with completely new ones
  if (TRUE) {
    clTags <- sort(unique(outputClusters))

    clTagsMap <- paste0(seq_along(clTags))
    clTagsMap <- factorToVector(niceFactorLevels(clTagsMap))
    clTagsMap <- set_names(clTagsMap, clTags)

    outputClusters <- clTagsMap[outputClusters]
    outputClusters <- set_names(outputClusters, getCells(objCOTAN))

    checksTokeep <- rownames(allCheckResults) %in% clTags
    allCheckResults <- allCheckResults[checksTokeep, , drop = FALSE]
    rownames(allCheckResults) <- clTagsMap[rownames(allCheckResults)]
  }

  outputCoexDF <-
    tryCatch(DEAOnClusters(objCOTAN, clusters = outputClusters),
             error = function(err) {
               logThis(paste("Calling DEAOnClusters", err), logLevel = 0L)
               return(NULL)
             })

  c(outputClusters, outputCoexDF, permMap) %<-% tryCatch(
    reorderClusterization(objCOTAN, clusters = outputClusters,
                          coexDF = outputCoexDF, reverse = FALSE,
                          keepMinusOne = FALSE, useDEA = useDEA,
                          distance = distance, hclustMethod = hclustMethod),
    error = function(err) {
      logThis(paste("Calling reorderClusterization", err), logLevel = 0L)
      return(list(outputClusters, outputCoexDF))
    })
  rownames(allCheckResults) <- permMap[rownames(allCheckResults)]

  if (isTRUE(saveObj)) tryCatch({
    outFile <- file.path(outDirCond, "merge_check_results.csv")
    write.csv(allCheckResults, file = outFile)
  })

  logThis("Merging cells' uniform clustering: DONE", logLevel = 2L)

  return(list("clusters" = outputClusters, "coex" = outputCoexDF))
}
