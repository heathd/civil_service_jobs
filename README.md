## Civil Service Jobs Scraper

Designed to incrementally scrape the Civil Service Jobs website.

It will parse index pages and individual job pages.

It has a multi-threaded crawler with configurable parallisation. If you use
this please be considerate as it's very easy to over-load a dynamic website
with a high level of parallel threads. Recommended number of threads is 4
which will allow you to scrape all of the job listings (~3000) in under 20
minutes.

The scraper uses a local sqlite database and will not re-scrape a job that has
been seen before.

It uses the reference number shown on the search results page as a unique
key. 

## Content under Open Government License

Fixtures in the `spec/fixtures` folder contain copies of the HTML source from
the Civil Service Jobs website. This is public sector information licensed
under the Open Government Licence v3.0.

## Data under Open Government License

The data downloaded by this scraper is collected under [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/)

You can access a copy of the data as a tar+gzipped sqlite database at the following URL:

```
https://civil-service-jobs-data.s3.eu-west-1.amazonaws.com/csj.tar.gz
```

## License

This source code is licensed under the GNU Affero Public License v3.0
