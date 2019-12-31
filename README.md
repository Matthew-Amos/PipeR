# PipeR
Lightweight toolkit for building data pipelines structured as a set of linear, testable nodes.

# Installation

Currently you must download this repository:

```bash
git clone https://github.com/equinaut/PipeR.git
```

To use it in your code, you need to simply `source` *pipeline.R*:

```R
source("LOCAL_PATH_TO_PipeR/pipeline.R")
```

# Example

First we prepare the environment and load in data as usual:
```R
# Load in files and libraries
library(dplyr)
source("PATH_TO_FILE/pipeline.R")

# Load / prep data
airquality <- datasets::airquality
quarters <- tibble(Month=seq(1, 12), Quarter=c(rep(1,3), rep(2,3), rep(3,3), rep(4,3)))
```

Next we design our data transformation algorithm. This will be organized into a series of progressive steps, which we refer to as nodes, where the output of the prior node is typically the input of the next.

Each node has two core components:
1. An `activation` function that transforms the input.
2. A `validation` function that tests the `activation` output for errors.

```R
# Prepare pipeline
# Each step in your data transformation will be its own node

# Step 1 - join quarters
# ----------------------
act_quarters <- activation(function(df) { left_join(df, quarters) })
val_quarters <- validation(function(df) { nrow(anti_join(df, airquality)) == 0})

node_quarters <- node$new(
  name="join quarters",
  on.activate=act_quarters,
  on.validate=val_quarters)

# Step 2 - Summarize
# ----------------------
act_summary <- activation(
  function(df) {
    df %>%
      group_by(Quarter) %>%
      summarise(MedianTemp = median(Temp))
  }
)

val_summary <- validation(function(df) { nrow(df) > 0 })

node_summary <- node$new(
  name="summarize",
  on.activate=act_summary,
  on.validate=val_summary)
```

Finally, we instantiate a pipeline like so:
```R
# The pipeline object takes a vector of nodes organized linearly
pipe <- pipeline(nodes=c(node_quarters, node_summary))

# Pass airquality to the first node
# By default devmode is set to TRUE, running the validation immediately after activation
pipe$run(airquality, devmode=F)
```

Executing `pipe$run(airquality, devmode=F)` should produce a comparable output:

```
> Joining, by = "Month"
> [1] "main @ 2018-05-12 20:11:25: join quarters - activated"
> [1] "main @ 2018-05-12 20:11:25: summarize - activated"
```

We can then separately test the pipeline:

```R
# Validate separately
pipe$test()
```

Testing the pipeline should produce output similar to below:

```
> Joining, by = c("Ozone", "Solar.R", "Wind", "Temp", "Month", "Day")
> [1] "main @ 2018-05-12 20:13:13: join quarters - validation passed"
> [1] "main @ 2018-05-12 20:13:13: summarize - validation passed"
```

```R
# Activations and validations are stored in the nodes
output <- pipe$nodes[[2]]$state$activation
test <- pipe$nodes[[2]]$state$validation
```

# TODO

- [ ] Documentation
- [ ] Easier way to access node states from pipeline
- [ ] Ability to clear activations at the node level for memory management
- [ ] Getting a "code for methids in class ... not checked for suspicious field assignments" warning
