make.adj <- function(shapefile,datafile,id,filename) {

    require(spdep)
    
    if(!all(duplicated(shapefile[[id]]) == FALSE))
        stop("dups")
        
    if(class(shapefile[[id]]) != class(datafile[[id]]))
        stop("class error")

    if( (class(shapefile[[id]]) == "factor") || (class(datafile[[id]]) == "factor") )
        stop("no factors")

    ## make sure id label is in both shapefile and datafile
    if(!(id %in% names(shapefile))) stop("error 1")
    if(!(id %in% names(datafile)))  stop("error 2")

    ## make shapefile and datafile have intersection of id's
    id.inter <- as.character(intersect(shapefile[[id]],datafile[[id]]))
    shapefile <- shapefile[shapefile[[id]] %in% id.inter,]
    datafile <- datafile[datafile[[id]] %in% id.inter,]

    ## sort both shapefile and datafile by id
    shapefile <- shapefile[order(shapefile[[id]]),]
    datafile <- datafile[order(datafile[[id]]),]

    if(!all(unique(shapefile[[id]]) == unique(datafile[[id]]))) stop("error 4")

    ## set up numeric id and give it a .num name
    datafile$temp <- match(datafile[[id]],sort(unique(shapefile[[id]])))

    new.id.name <- paste(id,".num",sep="")
    ## could have multiple existing new.id.names's
    if(new.id.name %in% names(datafile))
       datafile <- subset(datafile,select = -which(names(datafile) == new.id.name))
    names(datafile)[names(datafile) == "temp"] <- new.id.name

    ## make adjacency file
    shapefile.nb <- poly2nb(shapefile,queen=TRUE)
    nb2INLA(filename,shapefile.nb)

    ans <- list(shapefile = shapefile, datafile = datafile)

    ans
}
