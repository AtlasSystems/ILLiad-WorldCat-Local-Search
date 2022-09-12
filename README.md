# ILLiad WorldCat Local Search Addon

## Summary

The WorldCat Local Search Addon allows you to search Articles and Loans using a variety of criteria (title, ISSN, OCLC, etc.) and automatically shows search results.

## Settings

**AutoSearch (Boolean)**

Defines whether the search should be automatically performed when the form opens. Default: true

**WorldCatURL (string)**
The URL for WorldCat Local. Do not include a trailing slash. Default: https://worldcat.org

**SearchPriority (string)**

Defines what order priority should be used when attempting to find a field to search by when using the auto search feature. Allowed fields are title, isxn, and oclc. Default: Title,ISXN,OCLC