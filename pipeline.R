# validation object
# -----------------
# `fun` validates an activation output
# `result` is a built-in list containing test results
validation <- setRefClass(
  "validation",
  fields = list(
    fun = "function"
  ),
  methods = list(
    initialize = function(fun=function(x){return(T)}) {
      fun <<- fun
    },
    # runs a test on activation output
    # saves results to `result`
    validate = function(output) {
      f <<- fun
      sw <- "no warnings"
      se <- "no errors"

      # Run test
      test_res <- tryCatch({
        fr <- f(output)
        length(fr)==1 && fr == T
      }, warning = function(w) {
        sw <<- w
      }, error = function(e) {
        se <<- e
        F
      })

      # Return results
      return(list(passed=test_res, warnings=sw, errors=se))
    }
  )
)

# activation object
# -----------------
# `fun` returns activated data output
# `autoremove` will clear & gc output after next node or the whole pipeline has finished activating
# `output` holds the result of `fun`
activation <- setRefClass(
  "activation",
  fields = list(
    fun = "function"
  ),
  methods = list(
    initialize = function(fun=function(x){return(x)}) {
      fun <<- fun
    },
    activate = function(input) {
      f <<- fun
      return(f(input))
    }
  )
)

# node
# ------------
# syncs up an activation and validation
# `name` is a unique identifier for a node
# `module` is a textual identifier for what overarching sequence
# `on.activate` houses a single activation object
# `on.validate` houses a single validation object
node <- setRefClass(
  "node",
  fields = list(
    name = "character",
    module = "character",
    on.activate = "activation",
    on.validate = "validation",
    verbose = "logical",
    state = "list"
  ),
  methods = list(
    initialize = function(name, module="main", on.activate, on.validate) {
      name <<- name
      module <<- module
      on.activate <<- on.activate
      on.validate <<- on.validate
      state <<- list()
    },
    activate = function(input, verbose=T) {
      name <<- name
      module <<- module

      # Run activation
      act <<- on.activate
      a <- act$activate(input)

      # Status
      if(verbose) {
        name <<- name
        module <<- module
        print(paste0(module, " @ ", Sys.time(), ": ", name, " - ", "activated"))
      }

      # Update state
      state$activation <<- a

    },
    validate = function(verbose=T) {
      name <<- name
      module <<- module

      # Run validation
      val <<- on.validate
      a <<- state$activation
      v <- val$validate(a)

      # Status
      if(verbose) {
        name <<- name
        module <<- module
        basestr <- paste0(module, " @ ", Sys.time(), ": ", name, " - ")

        if(v$passed) {
          print(paste0(basestr, "validation passed"))
        } else {
          print(paste0(basestr, "validation failed"))
          print(paste0(basestr, "validation warnings: ", v$warnings))
          print(paste0(basestr, "validation errors: ", v$errors))
        }
      }

      # Update state
      state$validation <<- v
    }
  )
)

# pipeline
# --------
# nodes = vector of node objects in linear order
# verbose = whether to print out status on activation/validation
pipeline <- setRefClass(
  "pipeline",
  fields = list(
    nodes = "list",
    verbose = "logical"
  ),
  methods = list(
    initialize = function(nodes, verbose=T) {
      nodes <<- nodes
      verbose <<- verbose
    },
    run = function(input1, devmode=T) {
      nodes <<- nodes
      verbose <<- verbose

      for(i in 1:length(nodes)) {
        # set node
        ni <- nodes[[i]]

        if(i==1) {
          # feed node initial input
          ni$activate(input1, verbose)
        } else {
          # feed node prior node activation
          ni_1 <- nodes[[i-1]]
          ni$activate(ni_1$state$activation, verbose)
        }

        # if devmode is on also run validation
        if(devmode) {
          ni$validate()
        }
      }
    },
    test = function() {
      nodes <<- nodes
      verbose <<- verbose

      for(i in 1:length(nodes)) {
        nodes[[i]]$validate(verbose)
      }
    }
  )
)
