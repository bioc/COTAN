#' Raw sample dataset
#'
#' A subsample of a real sc-RNAseq dataset
#'
#' @format A data frame with 2000 genes and 815 cells:
#'
#' @source GEO GSM2861514
"raw"


#' COTAN object
#'
#' The COTAN object for the ERCC dataset.
#'
#' @format A structure with:
#' \describe{
#'   \item{raw}{the raw dataset: 88 fake genes for 1015 fake cells}
#'   \item{raw.norm}{raw divided for nu}
#'   \item{coex}{}
#'   \item{nu}{UDE}
#'   \item{lambda}{ average gene expression}
#'   \item{a}{}
#'   \item{hk}{genes expressed in all cells}
#'   \item{n_cells}{final number of cells}
#'   \item{meta}{meta data}
#'}
#' @source \url{https://support.10xgenomics.com/single-cell-gene-expression/datasets/1.1.0/ercc?}
"ERCC.cotan"

#' COTAN elaborated dataset
#'
#' The raw dataset elaborated
#'
#' @format The same structure as ERCC dataset
#'
#' @source GEO GSM2861514
"Obj_out_cotan_coex_not_approx"
