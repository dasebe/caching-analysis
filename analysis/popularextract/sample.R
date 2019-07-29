library(ggplot2)
library(data.table)

dt <- data.table(read.table("test"))

ids.all <- dt[,unique(V3)]
ids.sample <- sample(ids.all,100)

dt.sample <- dt[V3 %in% ids.sample]

ggplot(dt.sample,aes(V2,V1,color=factor(V3)))+
    geom_point()
