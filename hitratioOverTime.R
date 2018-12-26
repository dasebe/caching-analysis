library(ggplot2)
library(data.table)
library(foreach)
ggplot <- function(...) { ggplot2::ggplot(...) + theme_bw() }


# webcachesim results

pname <- "~/webcachesimLemonOverTime/nsolution/"
files <- list.files(path=pname,pattern="^sol_")
fname <- files[1]

sims <- foreach(fname=files, .combine=rbind) %do% {
    tmp <- data.table(read.table(paste(pname,fname,sep="")))
    tmp[,list(type=V1,logsize=log2(V2),h=V4,r=V6)]
}

sims[,type2:=gsub("[0-9.]","",type)]
sims[,ohr:=h/r]
#sims2 <- sims[,list(h=max(h)),by=list(type=type2,logsize,r)]

llbreaks=c("ExpLRU","Filter","GDS","GDSF","LFUDA","LRU","LRUS","SLRU")
llabels=c("AdaptSize","BloomFilter","GDS","GDSF","LFUDA","LRU","LRU-S","SLRU")
sims[,type3:=factor(type2,levels=llbreaks,labels=llabels,ordered=TRUE)]

sims2 <- sims[logsize==36]
sims[,unique(logsize)]
sims2 <- sims[logsize==32]

pdf("/tmp/plots/hitratioOverTime.pdf",6,2.5)
pdf("/tmp/plots/hitratioOverTime32.pdf",6,2.5)

ggplot(sims2,aes(r/1e6,ohr,color=type3))+
   geom_line(size=0.7)+
    scale_colour_brewer("",palette="Set1")+
    scale_y_continuous("Object Hit Ratio",expand=c(0,0))+
    scale_x_continuous("Time [millions of requests]",expand=c(0.01,0))+
    theme(legend.key.width = unit(1.1, "cm"),
          legend.key.height = unit(0.43, "cm"))+
#    theme(legend.position = c(.73,0.25))+
    theme(legend.text = element_text(size = rel(0.9)))+
    theme(axis.title.x = element_text(size = rel(1.05),vjust=-.1),axis.title.y = element_text(size = rel(1.05),vjust=1.2))+
    coord_cartesian(ylim=c(0,1))
dev.off()
