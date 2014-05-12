# parse_frac_log.R
#
# filelist = list.files(path="/path/to/files/", pattern="*.log", full.names=T)
# keyfile = "keyfile.csv"
# outfile = "your_output.csv"


parse_frac_log <- function( filelist=NA, keyfile=NA, outfile=NA, trialColumn=2, stimClassColumn=3, correctResponseColumn=6 ) {
  
  ext = ".log"

  if ( is.na(filelist) || (length(filelist)==0) ) {
    stop( "No input files specified" )
  }

  if ( is.na(keyfile) ) {
    stop( "No key file specified")
  }

  key = read.csv(keyfile)

  nFiles = length(filelist)

  subject = rep("NA",nFiles)
  trueCount = matrix(0,nFiles,4)
  falseCount = matrix(0,nFiles,4)
  trueMRT = matrix(0,nFiles,4)
  falseMRT = matrix(0,nFiles,4)
  #otherCount = rep(0,nFiles)
  #otherMRT = rep(0,nFiles)
  
  nBackList = c("NBack0", "NBack1", "NBack2", "NBack3")
  colnames(trueCount) = nBackList
  colnames(trueMRT) = nBackList
  colnames(falseCount) = nBackList
  colnames(falseMRT) = nBackList

  idx = 1
  for ( file in filelist ) {
    filename = basename( file )
    id = sub(ext, "", filename)
    subject[idx] = id

    idat = read.csv(file, skip=3, sep="\t")

    responses = which(idat$Event.Type=="Response")
    #print( filename )
    #print( paste( id, "has", length(responses), "responses" ))

    truePos = rep(0,4)
    falsePos = rep(0,4)
    otherHit = 0

    trueTime = rep(0.0,4)
    falseTime = rep(0.0,4)
    otherTime = 0.0

    for ( response in responses ) {
      trial = idat$Trial[response]
      time = idat$TTime[response]
      
      #keyRow = which(key$trial... == trial )
      keyRow = which(unlist(key[trialColumn]) == trial)
      
      #correct = key$correct.response[ keyRow ]
      correct = unlist(key[correctResponseColumn])[keyRow]
      
      #trialType = key$Stim.Class[ keyRow ]
      trialType = unlist(key[stimClassColumn])[keyRow]
      
      if ( length(keyRow) > 0 ) {
      if ( trialType == "0-back") {
        nBack = 0
      } 
      else if ( trialType == "1-back") {
        nBack = 1
      }
      else if (trialType == "2-back") {
        nBack = 2
      }
      else if (trialType == "3-back") {
        nBack = 3
      }  
      } else {
        print(paste( "WARNING: no trial type found for", trial))      
      }
      
      if ( length(correct) == 0 ) {
        print(paste("WARNING: ", filename, "HAS TRIAL", trial, "WHICH IS NOT FOUND IN KEY"))
        otherHit = otherHit + 1
        otherTime = otherTime + 1
      } else if ( !is.na(correct) ) {

        if ( correct == 1 ) {
          truePos[nBack+1] = truePos[nBack+1] + 1
          trueTime[nBack+1] = trueTime[nBack+1] + time
        } else if ( correct == 0 ) {
          falsePos[nBack+1] = falsePos[nBack+1] + 1
          falseTime[nBack+1] = falseTime[nBack+1] + time
        }

      } else {
        otherHit = otherHit + 1
        otherTime = otherTime + 1
      }
      
      #print(paste(truePos, trueTime, trueTime/truePos))

    }

    trueTime = trueTime / truePos
    falseTime = falseTime / falsePos
    trueTime[truePos==0] = 0
    falseTime[falsePos==0] = 0

    trueCount[idx,] = truePos
    trueMRT[idx,] = trueTime/10.0     # convert to ms
    falseCount[idx,] = falsePos
    falseMRT[idx,] = falseTime/10.0   # convert to ms
    #otherCount[idx] = otherHit
    #otherMRT[idx] = otherTime

    idx = idx + 1
    #print( paste( id, truePos, trueTime, falsePos, falseTime ))
  }

  odat = data.frame(Subject=subject, TruePositives=trueCount, TrueMRT=trueMRT, FalsePositives=falseCount, FalseMRT=falseMRT)
  if ( !is.na(outfile) ) {
    write.csv(odat, outfile)
  }

  return( odat )

} 

