library(lmerTest) 
library(afex)
library(emmeans)
library(multcomp)
library(dplyr)
library(optimx)
library(ggplot2)
library(dplyr)
library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)

# Tiny "--key value" parser
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
dep_name <- getk("dep_name")
wd_path <- getk("wd_path")
setwd(wd_path)


# LOAD -----------------------------------------------------------------
dt_TRACKS <- read.csv(load_path, header=T, sep=",")

dt_TRACKS$rat= factor(dt_TRACKS$rat)
dt_TRACKS$track = factor(dt_TRACKS$track)
dt_TRACKS$reward = factor(dt_TRACKS$reward, levels=c('HIGH','LOW'))
dt_TRACKS$previous_reward = factor(dt_TRACKS$reward, levels=c('HIGH','LOW'))
dt_TRACKS$session = factor(dt_TRACKS$session)
# set contrasts
contrasts(dt_TRACKS$reward) <- contr.sum(2, contrasts= TRUE)
contrasts(dt_TRACKS$previous_reward) <- contr.sum(2, contrasts= TRUE)
contrasts(dt_TRACKS$track) <- contr.sum(3, contrasts= TRUE)
contrasts(dt_TRACKS$session) <- contr.sum(6, contrasts= TRUE)

# SET FORMULAS ------------------------------------------------------------

f_speed_lap <- as.formula('event_rate ~ speed + lap_number + (1 | rat/session)')
f_full <- as.formula('event_rate ~ reward *track + speed + lap_number + (1 | rat/session)')


# RUN MODELS --------------------------------------------------------------

mean_speed= dt_TRACKS$mean_speed[1]
mean_lap= dt_TRACKS$mean_lap_number[1]
mean_dur= dt_TRACKS$mean_duration[1]
mean_HIGH= mean(dt_TRACKS$speed[dt_TRACKS$reward == "HIGH"])
mean_LOW= mean(dt_TRACKS$speed[dt_TRACKS$reward == "LOW"])
dt_TRACKS$speed_onoff <- rep(0,nrow(dt_TRACKS))
dt_TRACKS$speed_onoff[dt_TRACKS$speed <=0] <- -1
dt_TRACKS$speed_onoff[dt_TRACKS$speed >0]<- 1

m1_simple <- mixed('event_rate ~ reward*track + lap_number + (1 | rat/session)',
                  data = dt_TRACKS,
                  expand_re = TRUE,
                  check_contrasts= TRUE,
                  all_fit = TRUE)
summary(m1_simple)
anova(m1_simple)
emm_simple <- emmeans(m1_simple$full_model, ~ reward | track, type = "response")
contrast(emm_simple, "pairwise")
contrast(emmeans(m1_simple$full_model, ~ track | reward, type = "response"), "pairwise")

# Speed Lap only model
m1_speed_lap <- mixed(f_speed_lap,
  data = dt_TRACKS,
  expand_re = TRUE,
  check_contrasts= TRUE,
  all_fit = TRUE)
summary(m1_speed_lap)

m4_rate <- mixed(f_full,
  data = dt_TRACKS,
  expand_re = TRUE,
  check_contrasts= TRUE,
  all_fit = TRUE)
summary(m4_rate)
anova(m4_rate)

# SUMMARIES ---------------------------------------------------------------

emm_speed <- emmeans(m1_speed_lap$full_model, ~ speed, type = "response",at = list(speed = c(mean_HIGH,mean_LOW)))
c_speed <- contrast(emm_speed, "pairwise")
emm_lap <- emmeans(m1_speed_lap$full_model, ~ lap_number, type = "response",at = list(lap_number = c(10-mean_lap,1-mean_lap)))
c_lap <- contrast(emm_lap, "pairwise")

out_c_lap_speed <- rbind(c_lap,c_speed)
out_emm_lap_speed <- rbind(emm_lap,emm_speed)
out_c_lap_speed <- update(out_c_lap_speed, adjust= 'none') # figure out pvalue for sidak 1 - (1- alpha)^(1/num contrasts). alpha=0.05*3 because 3 families, num contrasts= 10
# need to adjust pval and set alpha level for confint
out2_SL <- update(out_c_lap_speed, adjust= 'sidak')
out2_SL <- as.data.frame(out2_SL)

CI_SL <- confint(out_c_lap_speed, level= 1 - 0.05*2)
out_emm_lap_speed <- as.data.frame(out_emm_lap_speed)
out_c_lap_speed <- as.data.frame(out_c_lap_speed)
out_c_lap_speed$alpha <-  1 - (1- 0.05*2)^(1/ 2)
out_c_lap_speed$p_sidak <- out2_SL$p.value
out_c_lap_speed$estimate <- CI_SL$estimate
out_c_lap_speed$SE  <- CI_SL$SE
out_c_lap_speed$CI_low <- CI_SL$lower.CL
out_c_lap_speed$CI_high <- CI_SL$upper.CL
out_c_lap_speed$RateRatio  <- exp(out_c_lap_speed$estimate)
out_c_lap_speed$CI_low_RR  <- exp(out_c_lap_speed$CI_low)
out_c_lap_speed$CI_high_RR <- exp(out_c_lap_speed$CI_high)

emm_reward <- emmeans(m4_rate$full_model, ~ reward, type = "response")
c_reward <- contrast(emm_reward, "pairwise")
emm_rec <- emmeans(m4_rate$full_model, ~ track, type = "response")
c_rec <- contrast(emm_rec, "pairwise")
emm_simple <- emmeans(m4_rate$full_model, ~ reward | track, type = "response")
plot(emm_simple)
c_simple <- contrast(emm_simple, "pairwise")
emm_interact <- emmeans(m4_rate$full_model, ~ track * reward  , type = "response")
c_interact <- contrast(emmeans(m4_rate$full_model, ~ track * reward  , type = "response"), interaction =c("pairwise","pairwise"))
out_c <- rbind(c_reward,c_rec,c_simple,c_interact)
out_emm <- rbind(emm_reward,emm_rec,emm_simple)
# report these values
out_c <- update(out_c, adjust= 'none') # figure out pvalue for sidak 1 - (1- alpha)^(1/num contrasts). alpha=0.05*3 because 3 families, num contrasts= 10
alpha <- 1 - (1- 0.05*3)^(1/ 10)
# need to adjust pval and set alpha level for confint
out2 <- update(out_c, adjust= 'sidak')
CI <- confint(out2, level= 1 - 0.05*3)

df_speed <-  as.data.frame(c_speed)
df_lap <-  as.data.frame(c_lap)
df_simple <- as.data.frame(c_simple)
df_rec <- as.data.frame(c_rec)
df_eff_interact <- as.data.frame(c_interact)

out_c <- as.data.frame(out_c)
out_emm <- as.data.frame(out_emm)
out2 <- as.data.frame(out2)

# # Also export rate ratios if you’ll plot on RR scale
out_c$alpha <- alpha
out_c$p_sidak <- out2$p.value
out_c$estimate <- CI$estimate
out_c$SE <- CI$SE
out_c$CI_low <- CI$lower.CL
out_c$CI_high <- CI$upper.CL
out_c$RateRatio  <- exp(out_c$estimate)
out_c$CI_low_RR  <- exp(out_c$CI_low)
out_c$CI_high_RR <- exp(out_c$CI_high)

out_emm_ALL <- rbind(out_emm_lap_speed,out_emm)
out_c_ALL <- rbind(out_c_lap_speed,out_c)
out_c_ALL$label <- c("lap10-Lap1",
               "speedHIGH-speedLOW",
               "(HIGH-LOW)",
               df_rec$contrast,
               paste0("T", df_simple$track, " (HIGH-LOW)"),
               paste0("T: ",df_eff_interact$track_pairwise,": (HIGH-LOW)"))

out_emm_ALL$label <- c("lap10","Lap1","speedHIGH","speedLOW",
                       "HIGH","LOW","T1","T2","T3",
                       "T1 HIGH","T1 LOW","T2 HIGH","T2 LOW","T3 HIGH","T3 LOW")

# save --------------------------------------------------------------------

### SAVE
if (save_path == ''){
  for (subdir in c("contrasts", "emmeans", "anova")) {
    dir.create(file.path(subdir),recursive = TRUE,showWarnings = FALSE)
  }
  write.csv(out_c_ALL, file.path("contrasts",paste0(dep_name,"_contrasts.csv")), row.names = FALSE)
  write.csv(out_emm_ALL, file.path("emmeans",paste0(dep_name,"_emmeans.csv")), row.names = FALSE)
  write.csv(as.data.frame(anova(m4_rate)),file.path("anova",paste0(dep_name,"_anova.csv")), row.names = TRUE)
  fixed <- summary(m1_speed_lap)$coefficients
  write.csv(fixed,paste0(dep_name,"_fixed_effects_speedLap.csv"), row.names = TRUE)
  fixed2 <- summary(m4_rate)$coefficients
  write.csv(fixed2,paste0(dep_name,"_fixed_effects_all.csv"), row.names = TRUE)
} else {
  dir.create(file.path(save_path), showWarnings = FALSE)
  for (subdir in c("contrasts", "emmeans", "anova")) {
    dir.create(file.path(save_path,subdir),recursive = TRUE,showWarnings = FALSE)
  }
  write.csv(out_c_ALL, file.path(save_path,"contrasts",paste0(dep_name,"_contrasts.csv")), row.names = FALSE)
  write.csv(out_emm_ALL, file.path(save_path,"emmeans",paste0(dep_name,"_emmeans.csv")), row.names = FALSE)
  write.csv(as.data.frame(anova(m4_rate)),file.path(save_path,"anova",paste0(dep_name,"_anova.csv")), row.names = TRUE)
  fixed <- summary(m1_speed_lap)$coefficients
  write.csv(fixed,file.path(save_path,paste0(dep_name,"_fixed_effects_speedLap.csv")), row.names = TRUE)
  fixed2 <- summary(m4_rate)$coefficients
  write.csv(fixed2,file.path(save_path,paste0(dep_name,"_fixed_effects_all.csv")), row.names = TRUE)
}

