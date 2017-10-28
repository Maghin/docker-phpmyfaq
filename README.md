# PhpMyFaq on Docker

[![Size](https://shields.beevelop.com/docker/image/image-size/merhylstudio/phpmyfaq/2.9.7.svg)](https://hub.docker.com/r/merhylstudio/phpmyfaq/)
[![Layers](https://shields.beevelop.com/docker/image/layers/merhylstudio/phpmyfaq/2.9.7.svg)](https://hub.docker.com/r/merhylstudio/phpmyfaq/)

## What is phpMyFAQ?

phpMyFAQ is a multilingual, completely database-driven FAQ-system. It supports
various databases to store all data, PHP 5.4.4+ or HHVM 3.4.2+ is needed in order to
access this data. phpMyFAQ also offers a multi-language Content Management
System with a WYSIWYG editor and an Image Manager, flexible multi-user support
with user and group based permissions on categories and records, a wiki-like
revision feature, a news system, user-tracking, 40+ supported languages, enhanced
automatic content negotiation, HTML5/CSS3 based templates, PDF-support, a
backup-system, a dynamic sitemap, related FAQs, tagging, RSS feeds, built-in spam
protection systems, OpenLDAP and Microsoft Active Directory support, and an easy
to use installation script.

## To run localy

Clone this [repository](https://github.com/Maghin/docker-phpmyfaq/) and `cd` to it.

    git clone git@github.com:Maghin/docker-phpmyfaq.git
    cd docker-phpmyfaq

Run docker-compose to start the full app on your system.

    docker-compose up

> **Note:**
> - This command will create a folder volumes in your reporitory. You can manage it as you want (fill, delete, etc...)

## On [Rancher](http://rancher.com/)

Use the [rancher](https://github.com/Maghin/docker-phpmyfaq/tree/rancher) branch to get a docker-compose.yml
file fully adapted to rancher with named volumes. You just have to paste it in the
[Rancher API](http://rancher.com/docs/rancher/v1.6/en/cattle/adding-services/#adding-services-with-rancher-compose).
