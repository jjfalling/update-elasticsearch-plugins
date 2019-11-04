Note: This is for an ancient version of elasticsearch. It will not work on any version released after 2015 or 2016.


update-elasticsearch-plugins
============================

A rought but simple way to update your Elasticsearch plugins. This will only work with plugins hosted on github.
It works by scraping the Elasticsearch plugin page and getting the github account/repo for each plugin, then it will ask you which plugins to update. You can manually add github hosted plugins that are not on the Elasticsearch page to the customPlugins hash, such as ["kopf"]="lmenezes/elasticsearch-kopf" .

You may need to change elasticsearchPluginDir to point to the location of your es plugins and elasticsearchPlugin to point to the es plugin script
