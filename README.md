# Do NBA Teams Avoid Trading within Their Own Division?

Data, code and paper (**currently under review**).

- Jimi Adams (@jimiadams)
- Michał Bojanowski  (@mbojan)

Abstract:

> Within US professional sports, trades within one's own division are often perceived to be disadvantageous. We ask how common this practice is. To examine this question, we construct a date-stamped network of all trades in the NBA between June 1976 and May 2019. We then use yearly weighted exponential random graph models to estimate the likelihood of teams avoiding within-division trade partners, and whether that pattern changes through time. In addition to the empirical question, this analysis serves to demonstrate the necessity and difficulty of constructing the proper baseline for statistical comparison. We find limited-to-no support for the popular perception.



## Building

The repository uses GNU make for reproducibility. Wherever random number generation is performed the seed is set so the results should reproduce.

All the artifacts (data, estimated models, and figures) are committed to the repository. This facilitates editing the manuscript without rerunning any part of the analysis. Simply Knit the document in RStudio or use `make just-render`.

1. To see defined phony targets run:

```sh
make help
```

2. To render the manuscript without touching any other parts: knit it in RStudio or execute

```sh
make just-render
```

3. To render the manuscript (re)running some other parts if necessary:

```sh
make paper
```

4. To "publish" the manuscript to `/docs/` execute:

```sh
make publish
```



