library(ggplot2)
library(data.table)
library(foreach)
library(scales)
library(RColorBrewer)

ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }

options(width=Sys.getenv("COLUMNS"))


#dvars

# offline lower bound

# table with trace names and legend positions
x <-"
trace lr ur lx ly type tname mlx mly
1 msr_proj_0.tr 24 32 .7 .23 Storage Proj0 .75 .83
3 msr_proj_2.tr 28 38 .7 .67 Storage Proj2 .75 .23
4 msr_src1_0.tr 30 36 .3 .65 Storage Src1 .25 .45
5 w100m.tr 28 36 .7 .23 CDN smallSF .75 .83
6 traceUS100m.tr 28 38 .7 .23 CDN largeUS .75 .83
7 traceHK100m.tr 28 38 .7 .23 CDN largeHK .75 .83
"            
traceprops <- data.table(read.table(textConnection(x)))

traces <- traceprops$trace
logsizes <- 20:42

lbound1 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslbound_",trace,"_",acc,"_",logsize,".log",sep="")
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}

#LM
lbound2 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","800000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"_",acc,"_",logsize,".log",sep="")
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}

#LM cpy
lboundcpy <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"_",acc,"_",logsize,".log_cpy",sep="")
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}

#LM cpy MSR
lboundcpy2 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000","450000","800000","1000000","2000000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"_",acc,"_",logsize,".logf_cpy",sep="")
        print(fname)
        tmp <- data.table(read.table(fname))
        tmp2 <- last(tmp)
        data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
}


# gcd

errorhandler <- "remove"

basepath <- "~/gcd/nsolutiong/"
servercount <- 24

lboundgcd <- foreach(server=0:servercount, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(trace=traces, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(acc=c("500000","1000000","2000000"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(method=c("lnslbound","lnslboundLM","linearlns","linearlns3"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(format=c(".log",".log_cpy"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling=errorhandler) %do% {
        fname <- paste(basepath,server,"/sol_",method,"_",trace,"_",acc,"_",logsize,format,sep="")
        if(file.exists(fname)){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp2 <- last(tmp)
            data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
        }
}

setkey(lboundgcd,trace,logsize)
lboundgcd[grepl("src1",trace)]


#lbound <- rbind(lbound1,lbound2,fast)
lboundall <- rbind(lbound1,lbound2,lboundcpy,lboundcpy2,lboundgcd)

lboundall <- lboundall[!is.na(h)]

lboundall[grep("100m",trace),r:=1e8]
lboundall[grep("500m",trace),r:=5e8]

lboundall2 <- lboundall[,list(h=max(h),r=max(r)),by=list(type,trace,logsize)]

# if ever goes downwards, skip this datapoint
setkey(lboundall2,trace,logsize)

lboundall2[,dd:=c(1,diff(h)),by=trace]
lboundall2 <- lboundall2[dd>0]
lboundall2[,dd:=NULL]


lboundall2[grepl("src1",trace)]
lboundall2[grepl("proj_2",trace)]
lboundall2[grepl("proj_0",trace)]



# fluid model
fluid <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
    fname <- paste("~/LemonMCFlns/nsolution/sol_fluidupper2_",trace,".log",sep="")
    print(fname)
    tmp <- data.table(read.table(fname))
    tmp[,list(type=V1,trace,logsize=log2(V2),h=V3,r=V4)]
}

#fluid2 <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
#    fname <- paste("~/LemonMCFlns/nsolution/sol_fluid_",trace,".log",sep="")
#    print(fname)
#    tmp <- data.table(read.table(fname))
#    tmp[,list(type=V1,trace,logsize=log2(V2),h=V3,r=V4)]
#}


#allfluid <- fluid #rbind(fluid,fluid2)


# backward/forward
trace <- traces[1]
logsize <- logsizes[9]

belady <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2_",trace,"_100_",logsize,".log",sep="")))
        dt1 <- tmp[,list(type=V1,trace=trace,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2size_",trace,"_100_",logsize,".log",sep="")))
        dt2 <- tmp[,list(type=V1,trace=trace,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2sizefrequency_",trace,"_100_",logsize,".log",sep="")))
        dt3 <- tmp[,list(type=V1,trace=trace,logsize,h=V5,r=V7)]
        rbind(dt1,dt2,dt3)
    }

belady2 <- belady[!grepl("Backward",type)]



# utility

util <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %do% {
    fname <- paste("~/LemonMCFofma/nsolution/sol_utilityknapsack_",trace,".log",sep="")
    print(fname)
    tmp <- data.table(read.table(fname))
    rbind(
        tmp[V1!=-1,list(type="util",trace,logsize=log2(V1),h=V2,r=V3)],
        tmp[V1==-1,list(type="inf",trace,logsize=1:50,h=V2,r=V3)]
        )
}


# webcachesim results

pname <- "~/webcachesim/nsolution/"

t <- list.files(path=pname,pattern=paste("^sol_.*",trace,sep=""))
fname=t[grepl("GD",t)][1]

sims <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(fname=
                list.files(path=pname,pattern=paste("^sol_.*",trace,sep=""))
          , .combine=rbind) %do% {
              tmp <- data.table(read.table(paste(pname,fname,sep="")))
              if(length(colnames(tmp))==5) {
                  tmp[,list(type=V1,trace,logsize=log2(V2),h=V4,r=V3)]
              } else {
                  tmp[,list(type=V1,trace,logsize=log2(V2),h=V5,r=V4)]
              }
}

#sims[grepl("LRUS([5-9]|1[0-9])$",type) & trace=="traceUS100m.tr" & logsize==30]
#sims <- sims[!grepl("LRUS([0-9]|1[0-9])$",type)]
#sims <- sims[!grepl("LRUS$",type)]
sims[,unique(type)]

sims[,type2:=gsub("[0-9.]","",type)]
sims2 <- sims[,list(h=max(h)),by=list(type=type2,trace,logsize,r)]



#plots

getPalette = colorRampPalette(brewer.pal(8, "Set1"))

bbreaks <- c(22,24,26,28,30,32,34,36,38,40,42)
blabels <- c("       4MB","16MB","64MB","       256MB","1GB","4GB","16GB","64GB","256GB","1TB","4TB   ")

bbreaks <- c(24,27,30,33,36,39)
blabels <- c("16MB","128MB","1GB","8GB","128GB","512GB")



# opt vs belady

dt <- rbind(lboundall2,allfluid)
dt <- rbind(lboundall2,fluid,belady2,util)
dt <- dt[!is.na(r)]
dt[,r:=max(r),by=trace]

dt[,unique(trace)]
dt[,unique(type)]

llbreaks=c("inf","fluid2","lbound","FW-Volume","Belady2SizeFrequencyForward","Belady2SizeForward","Belady2SizeFrequencyBackward","Belady2SizeBackward","GDSF","GDS","Filter","ExpLRU","Belady2Forward","SLRU","Belady2Backward","LRUS","LRUK","LFUDA","LRU")
llabels=c("Infinite Capacity","OPT fluid bound","OPT lower bound","Fw-Volume","Fw-FreqSize","Fw-RecSize","Bw-FreqSize","Bw-RecSize","GDSF","GDS","Bloom","AdaptSize","Fw-Recency","SLRU","Bw-Recency","LRU-S","LRU-K","LFU-DA","LRU")

llbreaks=rev(c("inf","fluid2","lbound","FW-Volume","Belady2SizeForward","util","Belady2Forward"))
llabels=rev(c("Inf Capacity (L)","P-FOO (L)","P-FOO (U)","Fw-Volume (U)","Belady-Size (U)","Freq-Size (U)","Belady (U)"))


dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]


## miss ratio

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    print(tr)
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    lx <- rw$mlx
    ly <- rw$mly
    maxh <- dt3[,max(1-h/r)]*1.03
    pl <- ggplot(dt3,aes(logsize,1-h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.8)+
    scale_color_manual("",values = rev(c("#edb459","#27338a","#27338a","#db6a6a","#db6a6a","#db6a6a")))+  # gree 33b042   #lila 835b
    scale_shape_manual("",values=rev(c(5,1,2,0,20,4)))+
    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Miss Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,maxh))
#
    oname <- paste("/tmp/plots/opt_belady_missratio_",tr,".pdf",sep="")
    pdf(oname,3.0,2.4)
    print(pl)
    dev.off()
}



# opt vs sims

dt <- rbind(lboundall2,fluid,belady2,sims2)
dt[,r:=max(r),by=trace]

opts <- c("inf","fluid2","lbound")
sims <- c("GDSF","GDS","ExpLRU","SLRU","LRUK","LRU")
heuristics <- c("FW-Volume","Belady2SizeForward","util")
llbreaks=rev(c(opts,heuristics,sims))
lopt <- c("Inf Capacity (L)","P-FOO (L)","P-FOO (U)")
lsims <- c("GDSF","GDS","AdaptSize","SLRU","LRU-K","LRU")
lheuristics <- c("Fw-Volume (U)","Belady-Size (U)","Freq-Size (U)")
llabels=rev(c(lopt,lheuristics,lsims))

dt2 <- dt[type %in% llbreaks]

dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

dt2[,unique(type2)]

## miss ratio

# best sim

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    print(tr)
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    dt3[,ohr:=h/r]
    dt3[type!="inf",loss:=ohr/max(ohr),by=logsize]
    # selected max ohr policy/heuristic
    dt4 <- dt3[type %in% sims,mean(loss),by=type]
    dt5 <- dt3[type %in% heuristics,mean(loss),by=type]
    selected <- c(opts,dt4[V1==max(V1),as.character(type)],dt5[V1==max(V1),as.character(type)])
    dt6 <- dt3[type %in% selected]
    lx <- rw$mlx
    ly <- rw$mly
    maxh <- dt3[,max(1-h/r)]*1.03
    pl <- ggplot(dt6,aes(logsize,1-h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.8)+
    scale_color_manual("",values = rev(c("#27338a","#27338a","#db6a6a","#33b042")))+  # gree 33b042   #lila 835bde
    scale_shape_manual("",values=rev(c(1,2,0,20)))+
    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Miss Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,maxh))
#
    oname <- paste("/tmp/plots/opt_sims_missratio_",tr,".pdf",sep="")
    pdf(oname,3.4,2.5)
    print(pl)
    dev.off()
}


# best sim at any time

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    print(tr)
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    # selected max ohr policy/heuristic
    dt4 <- dt3[type %in% sims]
    dt4
    dt5 <- dt3[type %in% heuristics]
    dt5
    dt6 <- dt3[type %in% opts]
    dt6
    dt4d <- dt4[,list(h=max(h),r=max(r),type="sim",type2="Policies"),by=list(trace,logsize)]
    dt5d <- dt5[,list(h=max(h),r=max(r),type="heuristic",type2="Heuristics"),by=list(trace,logsize)]
    dt7 <- rbind(dt4d,dt5d,dt6)
    llbreaks=rev(c(opts,heuristics,"heuristic",sims,"sim"))
    llabels=rev(c(lopt,lheuristics,"Prior Offline",lsims,"Prior Online"))
    dt7[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]
    lx <- rw$mlx
    ly <- rw$mly
    maxh <- dt3[,max(1-h/r)]*1.03
    pl <- ggplot(dt7,aes(logsize,1-h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.8)+
    scale_color_manual("",values = rev(c("#27338a","#27338a","#db6a6a","#33b042")))+  # gree 33b042   #lila 835bde
    scale_shape_manual("",values=rev(c(1,2,0,20)))+
    scale_size_manual("",values=c(0.5,0.5,0.5,0.9,0.9,0.5))+
    scale_y_continuous("Miss Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,maxh))
#
    oname <- paste("/tmp/plots/opt_hsims_missratio_",tr,".pdf",sep="")
    pdf(oname,3.4,2.5)
    print(pl)
    dev.off()
}



## hit ratio

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = c("#00b8ce","#888888","#444444","#C50003","#7570b3","#66a61e","#e7298a","#e6ab02","#a6761d","#d95f02"))+
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_sims_",tr,".pdf",sep="")
    pdf(oname,3,2.6)
    print(pl)
    dev.off()
}


######### outdated
# opt vs online vs stuff

dt <- rbind(lboundall2,fluid,sims2,belady2)
dt[,r:=max(r),by=trace]

dt[,unique(type)]

llbreaks=c("fluid","lbound","Belady2SizeFrequencyForward","Belady2SizeFrequencyBackward","GDSF","ExpLRU","Belady2Forward","LRU")
llabels=c("OPT fluid bound","OPT lower bound","Fw-FreqSize","Bw-FreqSize","GDSF","AdaptSize","Fw-Recency","LRU")

dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- rw$trace
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = getPalette(length(ttypes)))+
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_belsims_",tr,".pdf",sep="")
    pdf(oname,8,5)
    print(pl)
    dev.off()
}






# backward/forward
trace <- traces[1]
logsize <- logsizes[9]

belady <- foreach(trace=traces, .combine=rbind, .errorhandling='remove') %:%
    foreach(sample=c(100,500,1000,2000,2001,4001,8001,16001), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
#        print(paste("~/LemonMCFofma/nsolution/sol_belady2size_",trace,"_",sample,"_",logsize,".log",sep=""))
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2size_",trace,"_",sample,"_",logsize,".log",sep="")))
        dt2 <- tmp[,list(type=V1,trace=trace,sample,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2_",trace,"_",sample,"_",logsize,".log",sep="")))
        dt1 <- tmp[,list(type=V1,trace=trace,sample,logsize,h=V5,r=V7)]
        tmp <- data.table(read.table(paste("~/LemonMCFofma/nsolution/sol_belady2sizefrequency_",trace,"_",sample,"_",logsize,".log",sep="")))
        dt3 <- tmp[,list(type=V1,trace=trace,sample,logsize,h=V5,r=V7)]
        rbind(dt1,dt2,dt3)
    }

belady[trace=="traceUS100m.tr" & logsize==30 & type=="Belady2SizeForward"]
belady[trace=="traceUS100m.tr" & logsize==31 & type=="Belady2SizeForward"]
belady[trace=="traceHK100m.tr" & logsize==31 & type=="Belady2SizeForward"]
belady[trace=="memcachier100m.tr"]

belady2 <- belady[!grepl("Backward",type)]


tracesfast <- c("w100m", "traceUS100m","traceHK100m")
trace="w100m"
logsize=30

fast <- foreach(trace=tracesfast, .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=c(30,31), .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lboundfast_",trace,"_",logsize,".log",sep="")
        print(fname)
        tmp <- data.table(read.table(fname,skip=0))
        tmp2 <- last(tmp)
        tmp2[,list(type="FW-Volume",trace=paste(trace,"tr",sep="."),sample=0,logsize,h=V3,r=V4)]
}

fast[trace=="w100m.tr"]
fast[trace=="traceHK100m.tr"]

tmp1 <- lboundall2
tmp1[,sample:=0]
tmp2 <- sims2
tmp2[,sample:=0]
fluid[,sample:=0]
dt <- rbind(belady,fast,lboundall2,sims2,fluid)

tr="w100m.tr"
tr="traceUS100m.tr"
tr="traceHK100m.tr"
tr="w100m.tr"

for(tr in traces) {

    dt2 <- dt[trace==tr]
    dt2[,tt:=paste(type,sample)]
    dt2[,unique(tt)]

#    llbreaks=c("fluid 0","lbound 0","FW-Volume 0",paste("Belady2SizeFrequencyForward",rev(c(100,500,1000,2001,4001,8001)),sep=" "),paste("Belady2SizeForward",rev(c(100,500,1000,2001,4001,8001)),sep=" "),"GDSF 0","LRU 0")
#    llabels=c("OPT\nupper","OPT\nlower","Greedy\nVolume",paste("Belady\nSizeFreq\n",rev(c(100,500,1000,2001,4001,8001)),"sampl",sep=" "),paste("Belady\nSize\n",rev(c(100,500,1000,2001,4001,8001)),"sampl",sep=" "),"GDSF","LRU")

    llbreaks=c("fluid 0","lbound 0","FW-Volume 0","Belady2SizeForward 500","GDSF 0","LRU 0")
    llabels=c("OPT\nupper","OPT\nlower","Greedy\nVolume","Belady\nSize\n500","GDSF","LRU")

    
    dt3 <- dt2[tt %in% llbreaks]
    dt3[,type2:=factor(tt,levels=rev(llbreaks),labels=rev(llabels),ordered=TRUE)]

    dt4 <- dt3[logsize==31]
    dt4 <- dt3[logsize==30]

#
    pl <- ggplot(dt4,aes(type2,h/r))+
        geom_bar(stat="identity")+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_discrete("")+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
#    coord_cartesian(xlim=c(20,42))
                                        #    coord_cartesian(ylim=c(0.22,0.8))
    coord_cartesian(ylim=c(0,1))
#

    oname <- paste("/tmp/plots/opt_samplesize_",tr,".pdf",sep="")
    pdf(oname,8,5)
    print(pl)
    dev.off()

}





### abs error

dt <- rbind(lboundall2,fluid,belady2,util)
dt <- dt[!is.na(r)]
dt[,r:=max(r),by=trace]

errorhandler="stop"

i <- 1

dterr <- foreach(i=1:nrow(traceprops), .combine=rbind, .errorhandling=errorhandler) %do% {
    rw <- traceprops[i]
    tr <- rw$trace
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    dt3[type=="fluid2",hfl:=h]
    dt3[,hfl:=max(hfl,na.rm=TRUE),by=logsize]
    dt3[,list(err=hfl/r-h/r,logsize,trace,type)]
}    

dterr

setkey(dterr,trace,err)
dterr[,w:=1/length(err),by=trace]
dterr[,ecdf:=cumsum(w),by=trace]

dterr[,unique(trace)]

llbreaks=traceprops$trace
llabels=traceprops$tname

dterr[,trace2:=factor(trace,levels=llbreaks,labels=llabels,ordered=TRUE)]

llbreaks=c("lbound","FW-Volume","Belady2SizeForward","util","Belady2Forward")
llabels=c("P-FOO (L)","Fw-Volume (L)","Belady-Size (L)","Freq-Size (L)","Belady (L)")

dterr2 <- dterr[type %in% llbreaks]
dterr2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

cdntr <- traceprops[type=="CDN"]$trace

dterr3 <- dterr2[trace %in% cdntr]
oname <- "/tmp/plots/opt_pfoo_err_cdn.pdf"

dterr3 <- dterr2[!trace %in% cdntr]
oname <- "/tmp/plots/opt_pfoo_err_storage.pdf"



pl <- ggplot(dterr3, aes(trace2, err, fill=type2)) + 
  geom_boxplot(outlier.shape=NA)+
    scale_x_discrete("")+
    scale_y_continuous("Error in Hit Ratio",expand=c(0,0))+
    scale_fill_manual("",values = c("#444444","#C50003","#7570b3","#66a61e","#e7298a","#e6ab02","#a6761d","#d95f02"))+
theme(legend.direction='horizontal',
      legend.box='horizontal',
#      legend.position = c(-0.13,-0.11),
      legend.position = c(-0.18,1.2),
      legend.justification = c(0, 1),
      legend.margin=margin(t = 0, unit='cm'),
      plot.margin = unit(c(2, 0.6, 0.4, 0.5), "lines"))+
    theme(legend.key.width = unit(0.25, "cm"),
          legend.key.height = unit(0.5, "cm"))+
    theme(legend.text = element_text(size = rel(0.65)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
    coord_cartesian(ylim=c(0,0.4))

pdf(oname,3,2.6)
    print(pl)
    dev.off()


    






## exact

traces <- traceprops$trace
traces2 <- gsub("100m","",traces)

exact <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("~/LemonMCF/nsolution/sol_exact_",trace,"5m_",logsize,".log",sep="")
        print(fname)
        tmp <- data.table(read.table(fname))
        tmp[,list(type="foo",trace,logsize,hu=V9,hl=V10,r=V6)]
}

errorhandler <- "remove"
#errorhandler <- "stop"

basepath <- "~/gcd/nsolutiong/"
servercount <- 25

exactgcd <- foreach(server=0:servercount, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(trace=traces, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(method=c("exact"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(format=c(".log",".log_cpy"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling=errorhandler) %do% {
        fname <- paste(basepath,server,"/sol_",method,"_",trace,"5m__",logsize,format,sep="")
        if(file.exists(fname)){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp[,list(type="foo",trace,logsize,hu=V9,hl=V10,r=V6)]
        }
}

exactall <- rbind(exact,exactgcd)

exactall2 <- rbind(
    exactall[,list(type="ufoo",trace,logsize,h=hu,r)],
    exactall[,list(type="lfoo",trace,logsize,h=hl,r)]
    )


### OFMA


traces <- traceprops$trace
traces2 <- gsub("100m","",traces)

ofma <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %:%
    foreach(format=c(".log",".log_cpy"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% {
        fname <- paste("~/LemonMCFofma/nsolution/sol_ofma_",trace,"5m_",logsize,format,sep="")
        if(file.exists(fname) & file.info(fname)$size > 0){
            print(fname)
            tmp <- data.table()
            tmp <- data.table(read.table(fname))
            print(paste("good",fname))
            tmp[,list(type=V1,trace,logsize,h=V4,r=V6)]
        }
}



# P-FOO LNS

#LM
lns <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %:%
    foreach(acc=c("500000"), .combine=rbind, .errorhandling='remove') %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling='remove') %do% { 
        fname <- paste("~/LemonMCFlns/nsolution/sol_lnslboundLM_",trace,"5m_",acc,"_",logsize,".logf",sep="")
        if(file.exists(fname) & file.info(fname)$size > 0){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp2 <- last(tmp)
            data.table(type="lbound",trace,logsize,h=tmp2$V14,r=tmp2$V16)
        }
}



# localratio

traces <- traceprops$trace
traces2 <- gsub("100m","",traces)

localratio <- foreach(trace=traces2, .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(method=c("localratio"), .combine=rbind, .errorhandling=errorhandler) %:%
    foreach(logsize=logsizes, .combine=rbind, .errorhandling=errorhandler) %do% {
#        ttrace <- gsub("100m","",rw$trace) ## check this for other traces
        fname <- paste("~/LemonMCFlocalratio/nsolution/sol_",method,"_",trace,"5m_",logsize,".log",sep="")
        if(file.exists(fname)){
            print(fname)
            tmp <- data.table(read.table(fname))
            tmp2 <- last(tmp)
            tmp2[,list(type=method,trace=trace,logsize,h=V2,r=V4)]
        }
}


# fluid, infinite

# fluid model
smallfluid <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %do% {
    fname <- paste("~/LemonMCFlns/nsolution/sol_fluid_",trace,"5m.log",sep="")
    print(fname)
    tmp <- data.table(read.table(fname))
    tmp[,list(type=V1,trace,logsize=log2(V2),h=V3,r=V4)]
}

# utility
smallutil <- foreach(trace=traces2, .combine=rbind, .errorhandling='remove') %do% {
    fname <- paste("~/LemonMCFofma/nsolution/sol_utilityknapsack_",trace,"5m.log",sep="")
    print(fname)
    tmp <- data.table(read.table(fname))
    rbind(
        tmp[V1==-1,list(type="inf",trace,logsize=1:50,h=V2,r=V3)]
        )
}



dt <- rbind(exactall2,ofma,lns,smallfluid,smallutil)

dt <- dt[type!="OF",list(h=max(h,na.rm=TRUE),r=max(r,na.rm=TRUE)),by=list(type,trace,logsize)]
dt[type=="ufoo",maxh:=h]
dt[,maxh:=max(maxh,na.rm=TRUE),by=list(logsize,trace)]
dt[type!="inf" & type!="fluid2" & ifelse(maxh<1,FALSE,h>maxh),h:=maxh]
dt[,maxh:=NULL]

dt[,r:=max(r),by=trace]

dt[,unique(type)]

llbreaks=rev(c("inf","fluid2","ufoo","lfoo","lbound","OFMA"))
llabels=rev(c("Inf Capacity (L)","P-FOO (L)","FOO (L)","FOO (U)","P-FOO (U)","OFMA (U)"))
lcolors <- rev(
    c("edb459","27338a", "68b5f6","68b5f6", "27338a", "db6a6a"))
lshapes <- rev(c(5,1,20,20,2,0))

### SINGLE STEP
lcolors <- paste(rep("#",length(lcolors)),lcolors,sep="")

dt2 <- dt[type %in% llbreaks]
dt2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]

ttypes <- dt2[,unique(type2)]

bbreaks <- c(24,27,30,33,36,39,42)
blabels <- c("16MB","128MB","1GB","8GB","128GB","512GB","4TB  ")



# missratio

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- gsub("100m","",rw$trace) ## check this for other traces
    print(tr)
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    lx <- rw$mlx
    ly <- rw$mly
    maxh <- dt3[,max(1-h/r)]*1.02
    pl <- ggplot(dt3,aes(logsize,1-h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.8)+
    scale_color_manual("",values = lcolors)+
    scale_shape_manual("",values=lshapes)+
    scale_y_continuous("Miss Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,maxh))
#
    oname <- paste("/tmp/plots/opt_foo_missratio_",tr,".pdf",sep="")
    pdf(oname,3.4,2.5)
    print(pl)
    dev.off()
}


# missratio

i <- 2

    rw <- traceprops[i]
    tr <- gsub("100m","",rw$trace) ## check this for other traces
    print(tr)
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    lx <- rw$mlx
    ly <- rw$mly
    maxh <- dt3[,max(1-h/r)]*1.02
    pl <- ggplot(dt3,aes(logsize,1-h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.8)+
    scale_color_manual("",values = lcolors)+
    scale_shape_manual("",values=lshapes)+
    scale_y_continuous("Miss Ratio (different scale)",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0.99,1))
#
    oname <- paste("/tmp/plots/opt_foo_missratio09_",tr,".pdf",sep="")
    pdf(oname,3.4,2.5)
    print(pl)
    dev.off()

    dev.off()







### hit ratio

for(i in 1:nrow(traceprops)) {
    rw <- traceprops[i]
    tr <- gsub("100m","",rw$trace) ## check this for other traces
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    lx <- rw$lx
    ly <- rw$ly
    pl <- ggplot(dt3,aes(logsize,h/r,color=type2,shape=type2))+
        geom_line(size=0.5)+
        geom_point(size=1.2)+
    scale_color_manual("",values = c("#888888","#444444","#e7298a","#619d65","#d95f02","#C50003","#7570b3"))+ #"#C50003","#7570b3","#66a61e",,"#e6ab02"
    scale_shape_manual("",values=1:20)+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Cache Size",expand=c(0,0),breaks=bbreaks,labels=blabels)+
    theme(legend.key.width = unit(0.5, "cm"),
          legend.key.height = unit(0.28, "cm"))+
    theme(legend.position = c(lx,ly))+
    theme(legend.text = element_text(size = rel(0.8)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
        theme(legend.background = element_rect(fill="transparent"))+
    coord_cartesian(xlim=c(lrange,rrange),ylim=c(0,1.0))
#
    oname <- paste("/tmp/plots/opt_foo_",tr,".pdf",sep="")
    pdf(oname,3,2.6)
    print(pl)
    dev.off()
}




# abs error

errorhandler="stop"

dterr <- foreach(i=1:nrow(traceprops), .combine=rbind, .errorhandling=errorhandler) %do% {
    rw <- traceprops[i]
    tr <- traces2 <- gsub("100m","",rw$trace) ## check this for other traces
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    dt3[type=="ufoo",hfl:=h]
    dt3[,hfl:=max(hfl,na.rm=TRUE),by=logsize]
    dt3[,list(err=hfl/r-h/r,logsize,trace,type)]
}    

dterr <- foreach(i=1:nrow(traceprops), .combine=rbind, .errorhandling=errorhandler) %do% {
    rw <- traceprops[i]
    tr <- traces2 <- gsub("100m","",rw$trace) ## check this for other traces
    lrange <- rw$lr
    rrange <- rw$ur
    dt3 <- dt2[trace==tr & logsize>=lrange & logsize<=rrange]
    if(nrow(dt3)==0) {
        next
    }
    dt3[grepl("foo",type),list(err=max(h/r)-min(h/r)),by=list(logsize,trace)]
}    

setkey(dterr,trace,err)

dterr[,unique(trace)]

llbreaks=gsub("100m","",traceprops$trace)
llabels=traceprops$tname

dterr[,trace2:=factor(trace,levels=llbreaks,labels=llabels,ordered=TRUE)]

llbreaks=c("lfoo","OFMA","localratio")
llabels=c("FOO (L)","OFMA (L)","LocalRatio (L)")

dterr2 <- dterr[type %in% llbreaks]
dterr2[,type2:=factor(type,levels=llbreaks,labels=llabels,ordered=TRUE)]


cdntr <- gsub("100m","",traceprops[type=="CDN"]$trace)

dterr3 <- dterr2[trace %in% cdntr]
oname <- "/tmp/plots/opt_foo_err_cdn.pdf"

dterr3 <- dterr2[!trace %in% cdntr]
oname <- "/tmp/plots/opt_foo_err_storage.pdf"

pl <- ggplot(dterr3, aes(trace2, err, fill=type2)) + 
  geom_boxplot(outlier.shape=NA)+
    scale_x_discrete("")+
    scale_y_continuous("Error in Hit Ratio",expand=c(0,0))+
    scale_fill_manual("",values = c("#444444","#e7298a","#619d65","#d95f02"))+ #"#C50003","#7570b3","#66a61e",,"#e6ab02"
theme(legend.direction='horizontal',
      legend.box='horizontal',
#      legend.position = c(-0.13,-0.11),
      legend.position = c(-0.18,1.2),
      legend.justification = c(0, 1),
      legend.margin=margin(t = 0, unit='cm'),
      plot.margin = unit(c(2, 0.6, 0.4, 0.5), "lines"))+
    theme(legend.key.width = unit(0.25, "cm"),
          legend.key.height = unit(0.5, "cm"))+
    theme(legend.text = element_text(size = rel(0.65)))+
    theme(axis.title.x = element_text(size = rel(1.1),vjust=-.1),axis.title.y = element_text(size = rel(1.1),vjust=1.2))+
    coord_cartesian(ylim=c(0,1))

pdf(oname,3,2.6)
    print(pl)
    dev.off()
