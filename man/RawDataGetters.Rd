% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/COTAN-getters.R
\name{RawDataGetters}
\alias{RawDataGetters}
\alias{getRawData,COTAN-method}
\alias{getRawData}
\alias{getNumCells,COTAN-method}
\alias{getNumCells}
\alias{getNumGenes,COTAN-method}
\alias{getNumGenes}
\alias{getCells,COTAN-method}
\alias{getCells}
\alias{getGenes,COTAN-method}
\alias{getGenes}
\alias{getZeroOneProj,COTAN-method}
\alias{getZeroOneProj}
\alias{getCellsSize,COTAN-method}
\alias{getCellsSize}
\alias{getNumExpressedGenes,COTAN-method}
\alias{getNumExpressedGenes}
\alias{getGenesSize,COTAN-method}
\alias{getGenesSize}
\alias{getNumOfExpressingCells,COTAN-method}
\alias{getNumOfExpressingCells}
\title{Raw data \code{COTAN} accessors}
\usage{
\S4method{getRawData}{COTAN}(objCOTAN)

\S4method{getNumCells}{COTAN}(objCOTAN)

\S4method{getNumGenes}{COTAN}(objCOTAN)

\S4method{getCells}{COTAN}(objCOTAN)

\S4method{getGenes}{COTAN}(objCOTAN)

\S4method{getZeroOneProj}{COTAN}(objCOTAN)

\S4method{getCellsSize}{COTAN}(objCOTAN)

\S4method{getNumExpressedGenes}{COTAN}(objCOTAN)

\S4method{getGenesSize}{COTAN}(objCOTAN)

\S4method{getNumOfExpressingCells}{COTAN}(objCOTAN)
}
\arguments{
\item{objCOTAN}{a \code{COTAN} object}
}
\value{
\code{getRawData()} returns the raw count sparse matrix

\code{getNumCells()} returns the number of cells in the sample (\eqn{m})

\code{getNumGenes()} returns the number of genes in the sample (\eqn{n})

\code{getCells()} returns a character array with the cells' names

\code{getGenes()} returns a character array with the genes' names

\code{getZeroOneProj()} returns the raw count matrix projected to \code{0} or
\code{1}

\code{getCellsSize()} returns an array with the library sizes

\code{getNumExpressedGenes()} returns an array with the library sizes

\code{getGenesSize()} returns an array with the library sizes

\code{getNumOfExpressingCells()} returns an array with the library sizes
}
\description{
These methods extract information out of a just created \code{COTAN}
object. The accessors have \strong{read-only} access to the object.
}
\details{
\code{getRawData()} extracts the raw count table.

\code{getNumCells()} extracts the number of cells in the sample (\eqn{m})

\code{getNumGenes()} extracts the number of genes in the sample (\eqn{n})

\code{getCells()} extract all cells in the dataset.

\code{getGenes()} extract all genes in the dataset.

\code{getZeroOneProj()} extracts the raw count table where any
positive number has been replaced with \code{1}

\code{getCellsSize()} extracts the cell raw library size.

\code{getNumExpressedGenes()} extracts the number of genes expressed for
each cell. Exploits a feature of \link[Matrix:CsparseMatrix-class]{Matrix::CsparseMatrix}

\code{getGenesSize()} extracts the genes raw library size.

\code{getNumOfExpressingCells()} extracts, for each gene, the number of
cells that are expressing it. Exploits a feature of
\link[Matrix:CsparseMatrix-class]{Matrix::CsparseMatrix}
}
\examples{
data("test.dataset")
objCOTAN <- COTAN(raw = test.dataset)

rawData <- getRawData(objCOTAN)

numCells <- getNumCells(objCOTAN)

numGenes <- getNumGenes(objCOTAN)

cellsNames <- getCells(objCOTAN)

genesNames <- getGenes(objCOTAN)

zeroOne <- getZeroOneProj(objCOTAN)

cellsSize <- getCellsSize(objCOTAN)

numExpGenes <- getNumExpressedGenes(objCOTAN)

genesSize <- getGenesSize(objCOTAN)

numExpCells <- getNumOfExpressingCells(objCOTAN)

}
