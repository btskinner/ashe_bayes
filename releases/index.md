---
layout: default
title: Releases
---

If this workshop is updated, either to correct bugs or make general changes, I
tag each version with a release number. This allows users to see all changes
over time and go back to earlier versions if necessary.

Releases pull directly from
[GitHub](https://github.com/btskinner/ashe_bayes/releases). Release
numbers, `v<1>.<2>.<3>` follow the general format of:

- `<1>`: Workshop
- `<2>`: Module
- `<3>`: Bug fixes and small website updates


{% for release in site.github.releases %}
{% assign rdate = release.created_at | date: '%s' %}
{% assign rcuto = site.releasecutoff | date: '%s' %}
{% if rdate > rcuto %}
{% assign pdate = rdate | date: '%d %B %Y' %}
# [{{ pdate }} ({{ release.name }})]({{ release.html_url }})
{{ release.body }}
{% endif %}
{% endfor %}
