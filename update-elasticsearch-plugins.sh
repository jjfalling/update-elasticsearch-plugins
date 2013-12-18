#!/usr/bin/env bash
#
################################
# update-elasticsearch-plugins #
################################
#
# We get list of plugins from elasticsearch: http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/modules-plugins.html
# then compare it to a list of currently installed plugins.


elasticsearchPluginPage='http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/modules-plugins.html'
elasticsearchPluginDir='/usr/share/elasticsearch/plugins'

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
        echo "This script needs to run as root to run the updates!" 1>&2
        exit 1
fi

if [[ "$1"  == "-h" ]]
then
        echo "update-elasticsearch-plugins"
        echo "This will update your elasticsearch plugins in interactive mode"
        echo "or automaticly if you give the -y flag"
        exit

fi


printf "\n\nupdate-elasticsearch-plugins\n"
printf "This will offer to update github hosted plugins. It will remove the old version before installing the new one.\n"

auto=0
if [[ "$1"  == "-y" ]]
then
                auto=1
                printf "\n\nRunning in auto mode, I will upgrade all plugins without asking!\n\n"
                sleep 1
fi

echo "Obtaining current list of plugins, please wait..."

#curl the es plugin page. Then grep for each url line (contains ulink), remove a bogus line, strip it down to just the url, then shove it in an array
esPlugins=(`curl -s $elasticsearchPluginPage | grep ulink | grep -v "be found under the" |sed 's/<a class="ulink" href="//' | sed 's/" target=".*//'`)

#get a list of current plugins and shove it into an array
installedPlugins=(`ls $elasticsearchPluginDir |grep -v preupgrade*`)

#look at each installed plugin and try to find its repo, then offer to update
echo "Looking at plugins"
for currentInstalledPlugin in "${installedPlugins[@]}"
do

        for currentEsPlugin in "${esPlugins[@]}"
        do
                currentTrue=`echo $currentEsPlugin | grep --silent $currentInstalledPlugin; echo $?`
                if [ $currentTrue -eq 0 ]
                then
                        if [ $auto -eq 1 ]
                        then
                                response="y"
                        else
                                printf "\nUpgrade $currentInstalledPlugin? [y/n] "
                                read response
                        fi


                        if [ $response == "y" ]
                        then
                                #get the project name
                                githubProject=`echo $currentEsPlugin | sed 's/https:\/\/github.com\///'`
                                /usr/share/elasticsearch/bin/plugin -r $currentInstalledPlugin
                                /usr/share/elasticsearch/bin/plugin -i $githubProject
                        fi

                        break
                fi

        done

done
