#install.packages("hexSticker")
library(hexSticker)
library(ggplot2)

p <- ggplot() +
   theme_void() +
   xlim(0, 10) + ylim(0, 6) +
   annotate("rect", xmin = 0.5, xmax = 3, ymin = 1.5, ymax = 4.5,
      fill = NA, color = "#4A90D9", linewidth = 0.8, linetype = "dashed") +
   annotate("rect", xmin = 3.5, xmax = 6, ymin = 1.5, ymax = 4.5,
      fill = "#4A90D9", color = "#4A90D9", alpha = 0.8) +
   annotate("segment", x = 6.3, xend = 7.2, y = 3, yend = 3,
      arrow = arrow(length = unit(0.15, "cm"), type = "closed"),
      color = "white", linewidth = 0.6) +
   annotate("rect", xmin = 7.5, xmax = 10, ymin = 0.5, ymax = 5.5,
      fill = "#4A90D9", color = "#4A90D9", alpha = 0.5) +
   annotate("rect", xmin = 7.5, xmax = 10, ymin = 0.5, ymax = 3.5,
      fill = "#4A90D9", color = "#4A90D9", alpha = 0.8)

sticker(
   subplot = p,
   package = "rdborrow",
   p_size = 20,
   p_color = "#FFFFFF",
   p_y = 1.4,
   h_fill = "#1E3A5F",
   h_color = "#4A90D9",
   s_x = 1, s_y = 0.8,
   s_width = 1.4, s_height = 0.9,
   filename = "man/figures/logo.png"
)