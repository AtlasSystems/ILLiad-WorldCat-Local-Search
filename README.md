# ILLiad WorldCat Local Search Addon

## Summary

The WorldCat Local Search Addon allows you to search Articles and Loans using a variety of criteria (title, ISSN, OCLC, etc.) and automatically shows search results. When on an item page, bibliographic data can be imported.

## Prerequisites
ILLiad 9.2 and above is required for this addon to function. In ILLiad 9.2.4 or Ares 5.0.9 and above it will use the WebView2 embedded browser rather than Chromium.
This addon requires the Atlas Helpers Addon Library to be present in the Addons folder. If you do not have it, it can be downloaded at https://atlas-sys.atlassian.net/wiki/spaces/ILLiadAddons/pages/633405444/Atlas+Helpers+Addon+Library

## Settings

**AutoSearch (Boolean)**

Defines whether the search should be automatically performed when the form opens. Default: true

**WorldCatURL (string)**
The URL for WorldCat Local. Do not include a trailing slash. Default: https://worldcat.org

**SearchPriority (string)**

Defines what order priority should be used when attempting to find a field to search by when using the auto search feature. Allowed fields are title, isxn, and oclc. Default: Title,ISXN,OCLC

## DataMapping

Icons, source fields, and import fields can be customized for each product in the DataMapping.lua file.