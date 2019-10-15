library(ggplot2)
library(data.table)

dt <- data.table(read.table("test"))

ids.all <- dt[,unique(V3)]
ids.sample <- sample(ids.all,100)

dt.sample <- dt[V3 %in% ids.sample]

ggplot(dt.sample,aes(V2,V1,color=factor(V3)))+
    geom_point()


# sampled

ppath <- "sampled"
files <- dir(ppath)

for(i in files) {
    print(i)
    fn <- paste("sampled/",i,sep="")
    dt <- data.table(read.table(fn))
fnplot <- paste("sampleplots/",i,"_plots.pdf",sep="")
pdf(fnplot,7,5)
p <- ggplot(dt,aes(V2,V1))+
    geom_point()+
    scale_x_continuous("Time [unix ts]")+
    scale_y_continuous("Server",breaks=0:9,labels=0:9)
    print(p)
    dev.off()
}
