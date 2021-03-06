#' Coumputes Sky View Factor (SVF) of a tile. The SVF of the whole tile is returned.
#' 
#' \code{SVF} computes the Sky View Factor (SVF) given a path of a tile, maximal horizon view.
#' The data is saved into a text file (NLSVF200m.txt) and in a grid file (with name as the coordinates).
#' 
#' @param pointX x-coordinates in meters (RDcoordinates)
#' @param pointY y-coordinates in meters (RDcoordinates)
#' @param maxView maximal horizon view
#' 
#' 
#' 
#' @export


SVFWholeNL<-function(filepath, maxView){
  
  
  #tileNumberXCoord<-str_pad(as.integer(floor(pointX/1000)*1000), 6, pad = "0")
  #tileNumberYCoord<-str_pad(as.integer(floor(pointY/1000)*1000), 6, pad = "0")
  
  
  
  
  file<-basename(filepath)
  splits<-unlist(strsplit(file, c("\\.")))
  splits<-unlist(strsplit(splits[[1]], "_"))
  
  tileNumberXCoord<-as.integer(splits[[2]])
  tileNumberYCoord<-as.integer(splits[[3]])
  
  
  
  
  mainTile<-loadTileWholeNL(filepath)
  mainTile<-makeSpatialDF(mainTile,projection = pro)
  extensionMainTile<-extent(mainTile)
  
  if(xmax(extensionMainTile)!=xmin(extensionMainTile) & ymax(extensionMainTile)!=ymin(extensionMainTile))
     {
  
  neighbors<-mergeNeighborTiles(lazFolder, tileNumberXCoord, tileNumberYCoord, extensionMainTile, maxView, pro)
  
  #neighbors<-lapply(neighbors,checkCoordinates)
 
  rasterizedNeighbors<-lapply(neighbors, makeRaster, Xres, Yres, pro)
  if(length(rasterizedNeighbors)==1){
    mergedNeighbors<-rasterizedNeighbors[[1]]
  }
  else if (length(rasterizedNeighbors)==0){
    return(-1)  
  }
  else{
    mergedNeighbors<-do.call(merge, c(rasterizedNeighbors, tolerance =10))  
  }
  rm(neighbors)
  rm(rasterizedNeighbors)
  rasterizedMainTile<-makeRaster(mainTile,Xres,Yres,pro)
  rm(mainTile)
  #rasterOptions(tolerance = 0.1)
  fullRaster<-merge(rasterizedMainTile, mergedNeighbors, tolerance = 10)
  rm(mergedNeighbors)
  gc()
  
  r.svf<-svf(fullRaster, nAngles=16, maxDist= maxView, ll=F)
  out<-crop(r.svf,extent(rasterizedMainTile))
  
  #to fix the small inconsistencies in the extention (sometimes small approx are introduced in the extent)
  out<-fix_extent(rasterizedMainTile,out)

  r.b<-brick(rasterizedMainTile,out[[1]])
  names(r.b)<-c("Z","SVF")
  r.df<-as.data.frame(r.b,xy=TRUE)
  
  ##############################################
  ###############SAVE FUNCTION##################
  ##############################################
             
  #Writing the raster file with tile names
  writeRaster(r.b,filename=paste0(output_dir,
                                  str_pad(as.integer(floor(tileNumberXCoord/1000)*1000), 6, pad = "0"), "_",
                                  str_pad(as.integer(floor(tileNumberYCoord/1000)*1000), 6, pad = "0"),".grd"),
              format="raster",
              overwrite=TRUE)
  
  #Writing a table which will be appended if exists
  write.table(r.df,file="NLSVF200m.txt",sep=",",row.names = FALSE, append = TRUE, col.names = !file.exists("NLSVF200m.txt"))
  
  }
  else {
    print(paste0("tile ", filepath, " with odd extention: ", as.character(extensionMainTile)))
  }
  ##############################################
  ##############################################
  ##############################################
  rm(r.svf,r.b,r.df,splits,file)
  gc()
}

