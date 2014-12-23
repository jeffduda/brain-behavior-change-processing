library(ANTsR)
library(ggplot2)
library(RKRNS)
library(pracma)

Mode <- function(x) {
  x = as.integer(x)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

args <- commandArgs(trailingOnly = TRUE)
print( args )

mocoBOLD = args[1]
maskName = args[2]
segName = args[3]
roiName = args[4]
mocoParams = args[5]
compCorParams = args[6]
outname = args[7]


bold = antsImageRead( mocoBOLD, 4 )
mask = antsImageRead( maskName, 3 )
seg = antsImageRead( segName, 3)
seeds = antsImageRead( roiName, 3)
moco = read.csv( mocoParams )
compcor = read.csv( compCorParams )

moco = as.matrix(moco[,3:8])
moco = cbind( moco, moco*moco )
nCols = dim(moco)[2]
mocoDeriv = rbind( rep(0,nCols), diff(moco,1) )
moco = cbind( moco, mocoDeriv )
global = as.matrix(compcor[,1])
global = cbind( global, c(0, diff(global,1)))

compcor = as.matrix(compcor[,2:7])

wmMask = antsImageClone( seg )
wmMask[ wmMask != 3] = 0
wmMask[ wmMask == 3 ] = 1
ImageMath( 3, wmMask, "ME", wmMask, 1)

csfMask = antsImageClone(seg)
csfMask[ wmMask != 1] = 0
ImageMath( 3, csfMask, "ME", csfMask, 1)

wmSignal = timeseries2matrix( bold, wmMask )
wmSignal = rowMeans(wmSignal)
wmSignal = cbind( wmSignal, c(0, diff(wmSignal,1)) )

csfSignal = timeseries2matrix( bold, csfMask )
csfSignal = rowMeans(csfSignal)
csfSignal = cbind( csfSignal, c(0, diff(csfSignal,1)) )

mat = timeseries2matrix( bold, mask )

# Mode 1000 normalization
boldMode = Mode( mat )
scaling = 1000.0 / boldMode
mat = mat * scaling

# Demean and detrend
print( "Detrending data")
mat = detrend(mat)

# Assemble nuissance regressors
nuissance = cbind( global, compcor, moco, wmSignal, csfSignal)

# Get residuals
print( "Regressing out nuissance variables")
mat <- residuals( lm( mat ~ scale( nuissance ) ) )


# Frequency filtering
print( "Frequency filtering data")
mat <- frequencyFilterfMRI( mat, tr = antsGetSpacing( bold )[4],
  freqLo = 0.009, freqHi = 0.08, opt = "trig" )

# Back to image space
print( "Convert to image space")
bold <- matrix2timeseries( bold, mask, mat )

# Spatially smooth
# ImageMath(4, bold, "G", bold, "5")

print("Write output")
antsImageWrite(bold, outname)
