  data:extend({
    {
        type = "sprite",
        name = "add",
        filename = "__core__/graphics/add-icon.png",
        priority = "extra-high-no-scale",
        width = 32,
        height = 32,
        scale = 1,
    },
  })


data.raw["gui-style"].default.stats_table_style = 
    {
      type = "table_style",
      cell_padding = 0,
      horizontal_spacing=2,
      vertical_spacing=5,
      -- same as frame
      column_graphical_set =
      {
        type = "composition",
        filename = "__core__/graphics/gui.png",
        priority = "extra-high-no-scale",
        corner_size = {3, 3},
        position = {0, 24},
        opacity = 0.8
      },
      odd_row_graphical_set =
      {
        type = "composition",
        filename = "__core__/graphics/gui.png",
        priority = "extra-high-no-scale",
        corner_size = {0, 0},
        position = {78, 18},
        opacity = 0.2
      }

    }

data.raw["gui-style"].default.stats_table_style_large = 
    {
      type = "table_style",
      cell_padding = 0,
      horizontal_spacing=2,
      vertical_spacing=6,
      -- same as frame
      column_graphical_set =
      {
        type = "composition",
        filename = "__core__/graphics/gui.png",
        priority = "extra-high-no-scale",
        corner_size = {3, 3},
        position = {0, 24},
        opacity = 0.8
      },
      odd_row_graphical_set =
      {
        type = "composition",
        filename = "__core__/graphics/gui.png",
        priority = "extra-high-no-scale",
        corner_size = {0, 0},
        position = {78, 18},
        opacity = 0.4
      }

    }

    data.raw["gui-style"].default["stats_label_style_large"] = {
      type = "label_style",
      parent = "label",
      font = "default-large-bold",
}