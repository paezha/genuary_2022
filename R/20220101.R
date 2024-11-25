# Load libraries ---------------------------------------------------------------

library(dplyr)
library(purrr)
library(tidyr)
library(showtext)
library(ggplot2)

# Define custom functions ------------------------------------------------------

# Source: https://github.com/sharlagelfand/gradients

generate_gradient_colours <- function(colour_1, colour_2, size, probability) {
  sample(
    c(colour_1, colour_2),
    size = size,
    replace = TRUE,
    prob = c(probability, 1 - probability)
  )
}

generate_points_from_grid <- function(xmin, xmax, ymin, ymax, colour_1, colour_2, granularity = 100, horizontal = NULL) {
  x_size <- xmax - xmin
  y_size <- ymax - ymin
  
  grid <- expand.grid(
    x = seq(xmin, xmax, length.out = granularity * x_size),
    y = seq(ymin, ymax, length.out = granularity * y_size)
  ) %>%
    as_tibble() %>%
    filter(!x %in% c(xmin, xmax)) %>%
    filter(!y %in% c(ymin, ymax))
  
  if (colour_1 == colour_2) {
    grid <- grid %>%
      mutate(color = colour_1)
    
    return(grid)
  }
  
  if (is.null(horizontal)) {
    horizontal_gradient <- x_size > y_size
  } else {
    horizontal_gradient <- horizontal
  }
  
  if (horizontal_gradient) {
    grid <- grid %>%
      mutate(prop = (x - xmin) / x_size)
    
    sample_size <- grid %>%
      distinct(y) %>%
      nrow()
  } else {
    grid <- grid %>%
      mutate(prop = (y - ymin) / y_size)
    
    sample_size <- grid %>%
      distinct(x) %>%
      nrow()
  }
  
  grid %>%
    group_nest(prop) %>%
    mutate(color = map(
      prop,
      ~ generate_gradient_colours(
        colour_1 = colour_1,
        colour_2 = colour_2,
        size = sample_size,
        probability = .x
      )
    )) %>%
    unnest(cols = c(data, color))
}

# Create the data --------------------------------------------------------------

col1 = "#c84c0c" # mario brick main colour
col2 = "#fcbcb0" # mario brick light
# rose_madder = "#DB2B39"
# space_cadet = "#2D3047"

set.seed(10000)

layout <- tribble(
  ~xmin, ~xmax, ~ymin, ~ymax, ~colour_2, ~colour_1,
  
  0, 1, 0, 1, col1, col2)

gradient_grid <- layout %>%
  mutate(points = pmap(list(xmin, xmax, ymin, ymax, colour_1, colour_2), generate_points_from_grid, granularity = 105)) %>%
  select(points) %>%
  unnest(cols = c(points))

# Build plot 1 -----------------------------------------------------------------

# Import Google Fonts
font_add_google("Press Start 2P", "pressstart")

showtext_auto()

# Build plot
p <- gradient_grid %>%
  ggplot(aes(x = x, y = y, color = color)) +
  geom_point(size = 4, shape = 15) +
  scale_color_identity() +
  labs(
    title = "Mario the Generative Artist",
    subtitle = "#genuary2022 - Day 1",
    caption = "@jacquietran") +
  theme_void() +
  coord_fixed() +
  theme(
    text = element_text(colour = "#5c94fc", family = "pressstart", size = 24),
    plot.title = element_text(colour = "#FFFFFF"),
    plot.background = element_rect(fill = "#161c28", colour = "#161c28"),
    plot.margin = margin(5,0,5,0, unit = "pt"))

# Export to PNG
ggsave(
  here::here("img/20220101.png"),
  last_plot(), width = 10, height = 10, units = "cm", dpi = 320)

showtext_auto(FALSE)