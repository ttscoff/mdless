---
title: Highlighter test
---
## Highlighter ==highlight== header

This is a ==highlight inside== a paragraph.

- This is a ==highlight== in the middle of a list item

* Make sure you have Chrome installed (a recent version, like 59)
* Make sure you have `matrix-js-sdk` and `matrix-react-sdk` installed and built, as above
* `yarn test`

We do not recommend running Riot from the same domain name as your Matrix homeserver. The reason is the risk of XSS
(cross-site-scripting) vulnerabilities that could occur if someone caused Riot to load and render malicious [==user-generated content==](https://brettterpstra.com) from a Matrix API which then had trusted access to Riot (or other apps) due to sharing the same
domain.

