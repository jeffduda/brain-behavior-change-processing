library(ANTsR)
library(ggplot2)
library(RKRNS)

args <- commandArgs(trailingOnly = TRUE)
boldName = args[1]
boldPostName = args[2]
maskName = args[3]
mocoFile = args[4]
compcorrFile = args[5]
mocostatsFile = args[6]
id = args[7]
output = args[8]

print (id)

moco = read.csv(mocoFile)
corr = read.csv(compcorrFile)
fd = read.csv(mocostatsFile)

frame = fd$Mean
frame = frame[1:(length(frame)-1)]
frame = c(mean(frame), frame)

mask = antsImageRead( maskName, 3 )
bold = antsImageRead( boldName, 4)
mat = timeseries2matrix( bold, mask )
dvars = computeDVARS(mat)

boldPost = antsImageRead( boldPostName, 4)
matPost = timeseries2matrix( boldPost, mask )
dvarsPost = computeDVARS(matPost)

g1 = rowMeans(mat)
g2 = rowMeans(matPost)

nTimes = length(moco$MOCOparam0)
paramNames = c("dvar_pre", "dvar_post", "global_pre","global_post", "framewise", "roll", "pitch", "yaw", "x", "y", "z", "comp1", "comp2", "comp3", "comp4", "comp5", "comp6")
paramType =  factor( rep(paramNames, each=nTimes), levels=paramNames)


paramGroup = factor(c(rep( "dvar", 2*nTimes), rep("global", 2*nTimes), rep("framewise", nTimes), rep( c("angle", "displacement"), each=3*nTimes ), rep("compcorr", 6*nTimes)), levels=c("dvar", "global", "framewise", "angle", "displacement", "compcorr"))
paramTimes = rep( seq(1:nTimes), length(paramNames) )
params = c(dvars, dvarsPost, corr$GlobalSignal, g2, frame, moco$MOCOparam0,moco$MOCOparam1,moco$MOCOparam2,moco$MOCOparam3,moco$MOCOparam4,moco$MOCOparam5,corr$CompCorrVec1,corr$CompCorrVec2,corr$CompCorrVec3,corr$CompCorrVec4,corr$CompCorrVec5,corr$CompCorrVec6)
moco.data = data.frame(Parameter=params, Type=paramType, Time=paramTimes, Group=paramGroup)
mocoPlot = ggplot( moco.data, aes(x=Time, y=Parameter, group=Type, colour=Type) ) + geom_line() + facet_grid(Group ~ ., scales="free" )
mocoPlot = mocoPlot + ggtitle( paste( "Motion correction parameters:", id) )


#print( "make the plot")
png(filename=output, width=1200, height=800)
print( mocoPlot )
dev.off()
