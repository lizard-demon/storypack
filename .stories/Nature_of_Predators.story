return {
  title = "The Nature of Predators",
  platform = "nop",
  file = "library/natureofpredators.epub",
  filter = function(row, headers)
    -- Filter for main timeline Nature of Predators entries
    local title_idx, timeline_idx = 3, 2 -- Title and Timeline columns
    return row[timeline_idx] == "Main" and 
           row[title_idx] and 
           row[title_idx]:match("Nature of Predators")
  end
}
