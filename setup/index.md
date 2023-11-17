---
layout: default
title: Setup
---

In preparation for our workshop, you'll want to install a few free, open source
programs and libraries on the laptop you'll be using. Specifically, you'll need:

1. R (the programming language we'll be using)
1. RStudio (the application we'll use to work with R)

You can find links to download both R and RStudio at the Posit website:
[posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)

![]({{ site.baseurl }}/assets/img/posit.png){:.centerpic}

## Installing R

The link on the Posit page will take you to the CRAN (Comprehensive R Archive
Network) homepage.

![]({{ site.baseurl }}/assets/img/cran_home.png){:.centerpic}

You'll want to download the correct version of R depending on your computer's
operation system.

### Windows

For Windows/PC, first click on the _base_ link:

![]({{ site.baseurl }}/assets/img/cran_windows.png){:.centerpic}

On the next page, click the large top link:

![]({{ site.baseurl }}/assets/img/cran_windows_2.png){:.centerpic}

Follow all instructions to install R as you would a normal program.

#### Rtools

For Windows/PC machines, you'll also want to install Rtools. From the original
Windows page, click on the _Rtools_ link:

![]({{ site.baseurl }}/assets/img/cran_rtools.png){:.centerpic}

On the next page, click on the link in the middle of the page to download the
_rtools_ installer.

![]({{ site.baseurl }}/assets/img/cran_rtools_2.png){:.centerpic}

Follow all instructions to install Rtools as you would a normal program.

### MacOS

![]({{ site.baseurl }}/assets/img/cran_mac.png){:.centerpic}

For MacOS, choose the version that matches your chip type: Apple Silicon (newer)
or Intel (older). If you are unsure, click the Apple icon in the upper left part
of your toolbar and click on the _About this Mac_ link. The information about
your _processor_ should tell you. 

Follow all instructions to install R as you would a normal application.

### Linux

Let's be honest: if you run Linux on your machine, you probably don't need these
instructions!

# R libraries

You will need the following R libraries for this workshop:

- tidyverse
- brms

Once you've installed R and RStudio, you can paste the following in the RStudio console:

```r
install.packages(c("tidyverse",
                   "brms",
                   "bayesplot",
                   "tidybayes",
                   "patchwork",
                   "shinystan",
                   "parallel"),
                  dependencies = TRUE)
```

# Final notes

If you've installed R or RStudio in the past, we recommend downloading the
latest versions of each. If this is your first time downloading either, you will
automatically download the latest versions.

If you're having problems or errors, try restarting your computer first. If that
doesn't work or you need help with the installation process, please contact Ben
at btskinner \<at\> coe \<dot\> ufl \<dot\> edu to try to find some time at ASHE to
meet to troubleshoot.

