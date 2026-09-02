library(lmerTest) 
library(afex)
library(emmeans)
library(multcomp)
library(dplyr)
library(optimx)
library(ggeffects)
library(ggplot2)


args <- commandArgs(trailingOnly = TRUE)

kv <- list(); i <- 1L
while (i <= length(args)) {
  key <- args[[i]]
  if (!startsWith(key, "--")) { i <- i + 1L; next }
  if (i == length(args)) { kv[[substr(key, 3L, nchar(key))]] <- TRUE; break }
  val <- args[[i+1L]]
  if (startsWith(val, "--")) { kv[[substr(key, 3L, nchar(key))]] <- TRUE; i <- i + 1L; next }
  kv[[substr(key, 3L, nchar(key))]] <- val
  i <- i + 2L
}
getk <- function(k, default=NULL) if (!is.null(kv[[k]])) kv[[k]] else default
load_path <- getk("load_path")
save_path <- getk("save_path")
wd_path <- getk("wd_path")
setwd(wd_path)


# LOAD -----------------------------------------------------------------
dt_TRACKS <- read.csv(load_path, header=T, sep=",")

dt_TRACKS$rat= factor(dt_TRACKS$rat)
dt_TRACKS$track = factor(dt_TRACKS$track)
dt_TRACKS$reward = factor(dt_TRACKS$reward, levels=c('HIGH','LOW'))
dt_TRACKS$session = factor(dt_TRACKS$session)
dt_TRACKS$cellid = factor(dt_TRACKS$cellid)
dt_TRACKS$cellcat = factor(dt_TRACKS$cellcat)

dt_TRACKS <- dt_TRACKS %>% filter(track != 1) # remote replays cannot happen on T1 so removing that, and only novel cells by definition
dt_TRACKS$track = factor(dt_TRACKS$track)

# set contrasts
contrasts(dt_TRACKS$reward) <- contr.treatment(2, contrasts= TRUE)
contrasts(dt_TRACKS$track) <- contr.treatment(2, contrasts= TRUE)
contrasts(dt_TRACKS$cellcat) <- contr.treatment(2, contrasts= TRUE)

center_local  <- 1
center_remote <- 1
center_lap    <- median(log(dt_TRACKS$lap_number), na.rm = TRUE)

dt_TRACKS <- dt_TRACKS %>%
  mutate(
    numLocalActive_centered  = numLocalActive - center_local,
    numRemoteActive_centered = numRemoteActive - center_remote,
    lap_number_centered      = log(lap_number) - center_lap
  )


dt_TRACKS$fieldCorr[dt_TRACKS$fieldCorr == 1]= 0.999
dt_TRACKS$fieldCorr_z <- atanh(dt_TRACKS$fieldCorr)

# model

m1_full<- mixed(fieldCorr_z ~ track + cellcat*lap_number_centered + cellcat*numLocalActive_centered + numRemoteActive_centered +
                  (track + lap_number_centered + cellcat||cellid),
                data = dt_TRACKS,
                expand_re = TRUE,
                check_contrasts= FALSE,
                all_fit = TRUE)
summary(m1_full)
anova(m1_full)
emmeans(m1_full$full_model, ~ numRemoteActive_centered, type = "response")
emmeans(m1_full$full_model, ~ cellcat*numLocalActive_centered, type = "response")

levels(dt_TRACKS$track)
levels(dt_TRACKS$cellcat)

### SAVE
dir.create(save_path, showWarnings = FALSE)
fixed <- summary(m1_full)$coefficients
write.csv(fixed,file.path(save_path,"fixed_effects_replayChangeMap.csv"), row.names = TRUE)
write.csv(as.data.frame(anova(m1_full)),file.path(save_path,"anova_replayChangeMap.csv"), row.names = TRUE)


## PLOTS

mod <- m1_full$full_model 

track_ref <- levels(dt_TRACKS$track)[1]

make_slope_labels <- function(df) {
  df %>%
    mutate(
      sig_star = case_when(
        p.value < 0.001 ~ "***",
        p.value < 0.01  ~ "**",
        p.value < 0.05  ~ "*",
        TRUE            ~ "n.s."
      ),
      legend_label = paste0(
        cellcat,
        " (slope p=", signif(p.value, 2),
        ", ", sig_star, ")"
      )
    )
}

# Local Active plot

local_vals <- seq(
  min(dt_TRACKS$numLocalActive_centered, na.rm = TRUE),
  max(dt_TRACKS$numLocalActive_centered, na.rm = TRUE),
  length.out = 25
)

p_local <- ggpredict(
  mod,
  terms = c("numLocalActive_centered", "cellcat"),
  at = list(
    numLocalActive_centered      = local_vals,
    numRemoteActive_centered     = 0,                 # centered at 1
    lap_number_centered = 0,                 # centered at median(log(lap_number)) = 5 because [1 10]
    track               = track_ref
  )
)

local_trends_df <- summary(
  emtrends(
    mod,
    ~ cellcat,
    var = "numLocalActive_centered",
    at = list(
      numRemoteActive_centered     = 0,
      lap_number_centered = 0,
      track               = track_ref
    )
  ),
  infer = TRUE
) %>%
  make_slope_labels()

legend_labels_local <- setNames(local_trends_df$legend_label, local_trends_df$cellcat)

gg_local <- ggplot(p_local, aes(x = x, y = predicted, colour = group, fill = group)) +
  geom_line(linewidth = 1) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, colour = NA) +
  scale_colour_discrete(labels = legend_labels_local) +
  scale_fill_discrete(labels = legend_labels_local) +
  labs(
    x = paste0("number of local events"),
    y = paste0("Predicted ratemap\n","correlation"),
    colour = "cellcat",
    fill   = "cellcat",
    title  = paste0(
      "Effect of local events\n", 
      "for number local= ",center_remote,",",
      "\nlap= ",
      signif(exp(center_lap), 3),
      ", track = ", track_ref
    )
  ) +
  theme_classic() +
  coord_cartesian(xlim = c(0, 10))

gg_local
ggsave(file.path(save_path,"LocalEvents_CorrReg.png"), plot = gg_local, width = 6, height = 4, dpi = 600)

#  Remote Active plot
remote_vals <- seq(
  min(dt_TRACKS$numRemoteActive, na.rm = TRUE),
  max(dt_TRACKS$numRemoteActive, na.rm = TRUE),
  length.out = 25
)

p_remote <- ggpredict(
  mod,
  terms = c("numRemoteActive_centered", "cellcat"),
  at = list(
    numRemoteActive_centered     = remote_vals,
    numLocalActive_centered      = 0,                 # centered at 1
    lap_number_centered = 0,                 # centered at median(log(lap_number)) = 5
    track               = track_ref
  )
)

remote_trends_df <- summary(
  emtrends(
    mod,
    ~ cellcat,
    var = "numRemoteActive_centered",
    at = list(
      numLocalActive_centered      = 0,
      lap_number_centered = 0,
      track               = track_ref
    )
  ),
  infer = TRUE
) %>%
  make_slope_labels()

legend_labels_remote <- setNames(remote_trends_df$legend_label, remote_trends_df$cellcat)

gg_remote <- ggplot(p_remote, aes(x = x, y = predicted, colour = group, fill = group)) +
  geom_line(linewidth = 1) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, colour = NA) +
  scale_colour_discrete(labels = legend_labels_remote) +
  scale_fill_discrete(labels = legend_labels_remote) +
  labs(
    x = paste0("number of remote events"),
    y = paste0("Predicted ratemap\n","correlation"),
    colour = "cellcat",
    fill   = "cellcat",
    title  = paste0(
      "Effect of remote events\n", 
      "for number local= ",center_local,",",
      "\nlap= ",
      signif(exp(center_lap), 3),
      ", track = ", track_ref
    )
  ) +
  theme_classic() +
  coord_cartesian(xlim = c(0, 5))

gg_remote
ggsave(file.path(save_path,"RemoteEvents_CorrReg.png"), plot = gg_remote, width = 6, height = 4, dpi = 600)

# plot map stability with number of local replays, per category
dt_TRACKS <- dt_TRACKS %>%
  mutate(
    localReplayCat = case_when(
      numLocalActive == 0 ~ "0",
      numLocalActive == 1 ~ "1",
      numLocalActive == 2 ~ "2",
      numLocalActive >= 3 ~ "3+"
    ),
    remoteReplayCat = case_when(
      numRemoteActive == 0 ~ "0",
      numRemoteActive == 1 ~ "1",
      numRemoteActive == 2 ~ "2",
      numRemoteActive >= 3 ~ "3+"
    )
  ) %>%
  mutate(
    localReplayCat = factor(localReplayCat, levels = c("0", "1", "2", "3+")),
    remoteReplayCat = factor(remoteReplayCat, levels = c("0", "1", "2", "3+"))
  )

g1 <- ggplot(dt_TRACKS, aes(localReplayCat, fieldCorr, fill = localReplayCat, group = interaction(localReplayCat, cellcat))) +
  geom_boxplot(width = 0.5, whisker.colour = NA, outliers = FALSE, position = position_dodge(width = 0.8)) +
  stat_summary(aes(group = interaction(localReplayCat, cellcat)),
               position = position_dodge(width = 0.8),
               fun = median,geom = "point",colour = "black", size= 4)+
  theme_classic() +
  labs(x = "Number of local replay events including neuron",
    y = "ratemap correlation (r))",
    title = "map stability evolution with \n participation in local replay events") + 
  scale_fill_brewer(palette = "Purples") 
ggsave(file.path(save_path,"LocalEvents_CorrData.png"), plot = g1, width = 6, height = 4, dpi = 600)



## PANELS FOR FIG S7

laps_to_plot <- seq(1, 10, by = 2) 
dt_TRACKS <- dt_TRACKS %>%
  mutate(
    localReplayCat = case_when(
      numLocalActive == 0 ~ "0",
      numLocalActive == 1 ~ "1",
      numLocalActive == 2 ~ "2",
      numLocalActive >= 3 ~ "3+"
    ),
    remoteReplayCat = case_when(
      numRemoteActive == 0 ~ "0",
      numRemoteActive == 1 ~ "1",
      numRemoteActive == 2 ~ "2",
      numRemoteActive >= 3 ~ "3+"
    )
  ) %>%
  mutate(
    localReplayCat = factor(localReplayCat, levels = c("0", "1", "2", "3+")),
    remoteReplayCat = factor(remoteReplayCat, levels = c("0", "1", "2", "3+"))
  )

dt_TRACKS %>%
  filter(
    lap_number %in% laps_to_plot) %>%
  count(cellcat, lap_number, localReplayCat)

gLoc <- ggplot(
  dt_TRACKS %>% filter(lap_number %in% laps_to_plot),
  aes(localReplayCat, fieldCorr, fill = localReplayCat, group = interaction(localReplayCat, cellcat))
) +
  stat_summary(aes(group = interaction(localReplayCat, cellcat)),
               position = position_dodge(width = 0.8),fun = median,geom = "point",colour = "black", size= 2)+
  geom_boxplot(width = 0.2, whisker.colour = NA, outliers = FALSE) +
  facet_grid(cellcat ~ lap_number) +  
  theme_classic() +
  labs(
    x = "Number of local replay events including neuron",
    y = "Map stability",
    title = "Local replay x map stability across laps and cell categories"
  ) + scale_fill_brewer(palette = "Purples")

ggsave(file.path(save_path,"LocalEvents_BoxPLotsS7.png"), plot = gLoc, width = 6, height = 4, dpi = 600)


# same for remote
gRem <- ggplot(
  dt_TRACKS %>% filter(lap_number %in% laps_to_plot, cellcat == "both"),
  aes(remoteReplayCat, fieldCorr, fill = remoteReplayCat, group = interaction(remoteReplayCat, cellcat))
) +
  stat_summary(aes(group = interaction(remoteReplayCat, cellcat)),
               position = position_dodge(width = 0.8),fun = median,geom = "point",colour = "black", size= 2)+
  geom_boxplot(width = 0.2, whisker.colour = NA, outliers = FALSE) +
  facet_grid( ~ lap_number) +  
  theme_classic() +
  labs(
    x = "Number of remote replay events including neuron",
    y = "Map stability",
    title = "Remote replay x map stability across laps"
  )+ scale_fill_brewer(palette = "Purples")

ggsave(file.path(save_path,"RemoteEvents_BoxPLotsS7.png"), plot = gRem, width = 6, height = 4, dpi = 600)
