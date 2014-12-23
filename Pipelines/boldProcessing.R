library(ANTsR)
library(ggplot2)
library(RKRNS)
library(pracma)

Mode <- function(x) {
  x = as.integer(x)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

#args <- commandArgs(trailingOnly = TRUE)
#print( args )

boldProcessing <- function( bold, mask=NA, segmentation=NA, moco=NA, compcor=NA,
                  outname=NA, framewise=NA, refDVARS=NA, refGlobal=NA, scaling=NA,
                  smoothing=c(5,5,5,0), frequencies=c(0.009,0.08), id="SUBJECT" ) {

frame = framewise$Mean
frame = frame[1:(length(frame)-1)]
frame = c(mean(frame), frame)

mat = timeseries2matrix( bold, mask )
if ( is.na(scaling) ) {
  scaling = 1000.0 / mean(mat)
}
mat = mat * scaling
dvars = computeDVARS(mat)
global = rowMeans(mat)

if ( length(refDVARS) < 2 ) {
  refDvars = dvars
}
if ( length(refGlobal) < 2 ) {
  refGlobal = global
}

wmMask = antsImageClone( segmentation )
wmMask[ wmMask != 3] = 0
wmMask[ wmMask == 3 ] = 1
print(length(which(wmMask==1)))
ImageMath( 3, wmMask, "ME", wmMask, 1)
print(length(which(wmMask==1)))

wmSignal = timeseries2matrix( bold, wmMask )
print(dim(wmSignal))
wmSignal = rowMeans(wmSignal)
wmDeriv = cbind( wmSignal, c(0, diff(wmSignal,1)) )
wmSignal = wmSignal * scaling
print(mean(wmSignal))


csfMask = antsImageClone(segmentation)
csfMask[ csfMask != 1 ] = 0
ImageMath( 3, csfMask, "ME", csfMask, 1)
print(length(which(csfMask==1)))
csfSignal = timeseries2matrix( bold, csfMask )
print(dim(csfSignal))
csfSignal = rowMeans(csfSignal)
csfDeriv = cbind( csfSignal, c(0, diff(csfSignal,1)) )
csfSignal = csfSignal * scaling
print(mean(csfSignal))

nTimes = length(moco$MOCOparam0)
paramNames = c("dvar_pre", "dvar_post", "global_pre","global_post", "wm_post", "csf_post", "framewise", "roll", "pitch", "yaw", "x", "y", "z", "comp1", "comp2", "comp3", "comp4", "comp5", "comp6")
paramType =  factor( rep(paramNames, each=nTimes), levels=paramNames)


paramGroup = factor(c(rep( "dvar", 2*nTimes), rep("global", 2*nTimes), rep("whitematter", nTimes), rep("csf", nTimes), rep("framewise", nTimes), rep( c("angle", "displacement"), each=3*nTimes ), rep("compcorr", 6*nTimes)), levels=c("dvar", "global", "whitematter", "csf", "framewise", "angle", "displacement", "compcorr"))
paramTimes = rep( antsGetSpacing(bold)[4]*seq(1:nTimes), length(paramNames) )

params = c(refDVARS, dvars, refGlobal, global, wmSignal, csfSignal, frame, moco$MOCOparam0,moco$MOCOparam1,moco$MOCOparam2,moco$MOCOparam3,moco$MOCOparam4,moco$MOCOparam5,compcor$CompCorrVec1,compcor$CompCorrVec2,compcor$CompCorrVec3,compcor$CompCorrVec4,compcor$CompCorrVec5,compcor$CompCorrVec6)
moco.data = data.frame(Parameter=params, Type=paramType, Time=paramTimes, Group=paramGroup)
mocoPlot = ggplot( moco.data, aes(x=Time, y=Parameter, group=Type, colour=Type) ) + geom_line() + facet_grid(Group ~ ., scales="free" )
mocoPlot = mocoPlot + ggtitle( paste( "Motion correction parameters:", id) )
mocoPlot = mocoPlot + geom_vline(xintercept=10, linetype = "longdash", alpha=0.5)

#png(filename=output, width=1200, height=800)
#print( mocoPlot )
#dev.off()

print(wmSignal)
print(csfSignal)
return (mocoPlot)


}
