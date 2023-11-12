---
layout: default
title: Modules
---

Workshop modules are listed in order of the course. The R script
(<span><i class="fas fa-code"></i></span>) and data (<span><i
class="fas fa-database"></i></span>) used to create each module will be
linked at the top of the page. 

<ul class="modules">
{% assign modules = site.modules | where: 'category', 'module' %}
{% assign modules = modules | sort:"order"  %}
{% for m in modules %}
    <li>
        <a href="{{ m.url | prepend: site.baseurl }}.html">{{ m.title }}</a>
    </li>
{% endfor %}
</ul>
