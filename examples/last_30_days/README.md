# RStudio Connect Usage Report

This R Markdown report can be published as-is to your RStudio Connect server or 
used as a starting point for your own analysis. You can schedule the report and 
distribute it via email (the email will include inline graphics!)

Sample Report: http://colorado.rstudio.com/rsc/usage

<center><img src="email-preview.png" width = "400px" height = "400x"></center>

The report is generated using the [RStudio Connect Server API](https://docs.rstudio.com/connect/api). The `helpers.R` file contains example code for querying the various API endpoints. The API and data collection are both available as of RStudio Connect 1.7.0. The API contains data to help answer questions like:

- What content is most visited?
- Who is visiting my content?
- What reports are most common?
- Has viewership increased over time?
- Did my CEO actually visit this app?

**A data science team's time is precious, this data will help you focus and justify your efforts.**

The report uses the environment variables `CONNECT_SERVER` and `CONNECT_API_KEY` to collect the data. To limit the results to a single publisher, use a publisher API key.

### Common Questions

- Could this be a shiny app instead of a report? Of course! Let us know what you come up with.
- Can I use the API from another language besides R? Absolutely, the API includes a spec to get you started.
- Will you provide an R client for accessing the API? Please start a topic on [RStudio Community](https://community.rstudio.com/c/r-admin/rstudio-connect) (in the R Admins section) if this sounds interesting.
- What is the `manifest.json` file? This file aids in programmatic deployments, a new RStudio Connect feature.
