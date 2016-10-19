library("dplyr")
library("ggplot2")
ll <- read.csv("~/Downloads/laureate.csv", stringsAsFactors=FALSE)
ll$born <- as.Date(ll$born , "%Y-%m-%d")
ll$died <- as.Date(ll$died , "%Y-%m-%d")
ll <- mutate(ll, age = year - as.numeric(format(born,'%Y')))
lldraw <- select(ll, year, age, category, gender)
lldraw <- na.omit(lldraw)
lldraw$category <- as.factor(lldraw$category)
# levels(lldraw$category)
# [1] "chemistry"  "economics"  "literature" "medicine"   "peace"      "physics" 
levels(lldraw$category) <- c("化學", "經濟學", "文學", "醫學", "和平", "物理")
lldraw$gender <- as.factor(lldraw$gender)
# levels(lldraw$gender)
# [1] "female" "male"  
levels(lldraw$gender) <- c("女", "男")
lldraw <- mutate(lldraw, 性別=gender)
g <- ggplot(data=lldraw, aes(x=year, y=age)) + 
  geom_point(size=0.7, aes(colour=性別)) +
  facet_grid(. ~ category) +
  scale_x_continuous("年度", breaks=c(1900, 1950, 2000)) +
  scale_y_continuous("年齡", limit=c(17,95)) +
  ggtitle("歷年諾貝爾獎得主年齡與性別") + 
  theme(text=element_text(family="Noto Sans CJK TC", size=10), 
        title=element_text(size=20),
        axis.title=element_text(size=14),
        legend.title=element_text(size=14),
        strip.text=element_text(size=14))

# WORLD MAP!!!
library("rworldmap")
library("countrycode")
library("rgdal")

world <- map_data("world")
world <- world[world$region != "Antarctica",]
world <- mutate(world, iso2c=countrycode(world$region, "country.name", "iso2c"))
bornCount <- summarise(group_by(ll, bornCountryCode), bornNumber=n_distinct(id))
orgCount <- summarise(group_by(ll, country), orgNumber=n_distinct(id))
orgCount <- mutate(orgCount, iso2c=countrycode(orgCount$country, "country.name", "iso2c"))
countryCount <- merge(bornCount, orgCount, by.x="bornCountryCode", by.y="iso2c", all=TRUE)
world2 <- merge(world, countryCount, by.x="iso2c", by.y="bornCountryCode", all.x=TRUE)
worldMap <- readOGR(dsn="world_borders", layer="TM_WORLD_BORDERS_SIMPL-0.3")
worldMap.fort <- fortify(world2, region = "ISO2")
idList <- worldMap@data$ISO2
centroids.df <- as.data.frame(coordinates(worldMap))
names(centroids.df) <- c("Longitude", "Latitude") 
centroid <- cbind(idList, centroids.df)
orgNumGeo <- merge(centroid, countryCount, by.x="idList", by.y="bornCountryCode")

gg <- ggplot(data=world2) + 
  geom_map(data=world2, map=world,
           aes(x=long, y=lat, map_id=region, fill=orgNumber), 
           color="white", size=0.05, alpha=0.8) + 
  geom_text(data=orgNumGeo, 
            aes(x=Longitude, y=Latitude, label=orgNumber, map_id=country), 
            na.rm=TRUE, colour="white", size=5, check_overlap = TRUE) +
  scale_x_continuous(NULL, breaks=NULL) +
  scale_y_continuous(NULL, breaks=NULL) +
  ggtitle("歷年諾貝爾獎得主得獎時工作國家") + 
  scale_fill_continuous("人數", low = "#8FAADC", high = "#222E43", trans = "log", breaks=c(0, 5, 10, 50, 300), na.value = "grey65") + 
  theme(text=element_text(family="Noto Sans CJK TC"), 
        title=element_text(size=20),
        legend.title=element_text(size=14),
        legend.position = "bottom")

ggsave("nobel_map.png")
