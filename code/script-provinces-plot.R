library(lubridate)
library(useful)
library(dplyr)
# smoothed p_cases and CI:
source("smooth_column-v2.R")

estimates_path <- "../data/estimates-provinces/"
plots_path <- "../data/estimates-provinces/plots/"

# estimates_path <- "./estimates-provinces/"
# plots_path <- "./estimates-provinces/plots/"


smooth_param <- 15
age_recent <- 5


## Load data ----
df <- read.csv(paste0(estimates_path, "ES/ESM-estimate.csv"))
df <- df %>% select(date, p_recentcases, p_cases, p_stillsick)
df$date <- as.Date(df$date)

# df <- tail(df, n=(nrow(df)-211))
df <- df[df$date >= ymd("2020-10-04"),]

df$date <- df$date - (age_recent-1)/2

#shift recent cases
df$recent_shifted <- df$p_recentcases
df <- smooth_column(df_in = df, 
                        col_s = "recent_shifted", 
                        basis_dim = smooth_param,
                        link_in = "log")


for (i in 1:(nrow(df)-3)){
  df$recent_shifted[i] <- df$recent_shifted[i+3]
  df$recent_shifted_smooth[i] <- df$recent_shifted_smooth[i+3]
  
}
df$recent_shifted[nrow(df)] <- df$recent_shifted[nrow(df)-1] <- 
  df$recent_shifted[nrow(df)-2] <- NA
df$recent_shifted_smooth[nrow(df)] <- df$recent_shifted_smooth[nrow(df)-1] <- 
  df$recent_shifted_smooth[nrow(df)-2] <- NA
# dfr <- df
# dfr %>% select(date, recent_shitfed = p_recentcases)
# dfr$date <- dfr$date -3
# dfn <- merge(df, dfr, by = "date")
# df <- shift.column(data=df, columns="p_recentcases", newNames="recent_shifted", len=3, up =T)


## Non-monotonic ----
df <- smooth_column(df_in = df, 
                        col_s = "p_recentcases", 
                        basis_dim = smooth_param,
                        link_in = "log")

df <- smooth_column(df_in = df, 
                        col_s = "p_stillsick", 
                        basis_dim = smooth_param,
                        link_in = "log")

# colors <- c("Nuevos casos" = "red", "recent_c" = "red", "sick_c" = "blue", "Sintomáticos" = "blue")
p1 <- ggplot(data = df, aes(x = date, color = ""))  +
  geom_vline(aes(xintercept = ymd("2020-10-02"), color = "Cierre"), 
             linetype="dotted", size=1)+
  geom_vline(aes(xintercept = ymd("2020-10-24"), color = "Cierre"), 
             linetype="dotted", size=1)+
  geom_vline(aes(xintercept = ymd("2020-10-09"), color = "Cierre"), 
             linetype="dotted", size=1)+
  geom_vline(aes(xintercept = ymd("2020-10-04"), color = "Domingo"), 
             linetype="dotted")+
  geom_vline(aes(xintercept = ymd("2020-10-11"), color = "Domingo"), 
             linetype="dotted")+
  geom_vline(aes(xintercept = ymd("2020-10-18"), color = "Domingo"), 
             linetype="dotted")+
  geom_point(aes(y = recent_shifted*100000, color = "Nuevos casos x 7"), alpha = 0.5, size = 2) +
  geom_line(aes(y = recent_shifted_smooth*100000, color = "Nuevos casos x 7 (suav.)"), linetype = "solid", size = 1, alpha = 0.6) +
  geom_point(aes(y = p_stillsick*100000, color = "Sintomáticos"), alpha = 0.5, size = 2) +
  geom_line(aes(y = p_stillsick_smooth*100000, color = "Sintomáticos (suav.)"), linetype = "solid", size = 1, alpha = 0.6) +
  labs(x = "Fecha", y =  "Casos por 100.000 habitantes") +
  # ylim(0, 3000)+
  theme_bw() + ggtitle("Incidencia en Madrid") +
  scale_colour_manual(values = c("green", "red", "red", "red", "blue", "blue"),
                      name="",
                      guide = guide_legend(override.aes = list(
                        linetype = c("dotted", "dotted", "blank", "solid", "blank", "solid"),
                        shape = c(NA, NA, 1, NA, 1, NA)))) +
  theme(legend.position = "bottom")
#p1

ggsave(plot = p1, 
       filename =  paste0(plots_path, "ESM-recent-plot.jpg"), 
       width = 9, height = 6)

# df_out <- smooth_column(df_in = df, 
#                         col_s = "p_cases", 
#                         basis_dim = 15, link_in = "log", monotone = T)
# 
# df_out$p_cases_smooth_log <- df_out$p_cases_smooth
# df_out <- df_out %>% select(date, p_cases_smooth_log, p_cases)
# 
# df_out <- smooth_column(df_in = df_out, 
#                         col_s = "p_cases", 
#                         basis_dim = 15, monotone = T)
# df_out$p_cases_smooth_id <- df_out$p_cases_smooth
# 
# colors <- c("cases" = "orange", "smooth_log" = "red", "smooth_id" = "blue")
# p2 <- ggplot(data = df_out, aes(x = date, color = Legend))  +
#   geom_point(aes(y = p_cases, color = "cases"), alpha = 0.4, size = 1) +
#   geom_line(aes(y = p_cases_smooth_log, color = "smooth_log"), size = 0.8, alpha = 0.6) +
#   geom_line(aes(y = p_cases_smooth_id, color = "smooth_id"), size = 0.8, alpha = 0.6) +
#   theme_bw() + ggtitle("Monotone smoothing (positive vs. unrestricted)") +
#   scale_color_manual(values = colors, name = "") + 
#   theme(legend.position = "bottom") 
# p2

