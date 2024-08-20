# RE-FRB
Implementation example for Rare Events FRB repeaters classification 

## Installation

This package is not part of the general repository of Julia, so it is necessary to load it locally, and some preparation is necessary in advance.


## Running example

Once the package has been instatiated correctly, it is straightforward to use the example file:

From Julia's REPL

```
using Pkg;
Pkg.Activate("./repeaters");
include("Example.jl")
```
From terminal:

```
Julia --project=./repeaters Example.jl
```

This will run the example file "Example.jl" producing several plots with validation metrics and a test example histogram, as well as saving a CSV with the coefficients for the ensemble of classifiers.
