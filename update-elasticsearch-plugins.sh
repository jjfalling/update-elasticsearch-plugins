#!/usr/bin/env bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

#****************************************************************************
#*   update-elasticsearch-plugins                                           *
#*   Update elasticsearch plugins that are hosted in github                 *
#*                                                                          *
#*   Copyright (C) 2014 by Jeremy Falling except where noted.               *
#*                                                                          *
#*   This program is free software: you can redistribute it and/or modify   *
#*   it under the terms of the GNU General Public License as published by   *
#*   the Free Software Foundation, either version 3 of the License, or      *
#*   (at your option) any later version.                                    *
#*                                                                          *
#*   This program is distributed in the hope that it will be useful,        *
#*   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
#*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
#*   GNU General Public License for more details.                           *
#*                                                                          *
#*   You should have received a copy of the GNU General Public License      *
#*   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
#****************************************************************************

#Edit the following to match your needs
elasticsearchPluginDir='/usr/share/elasticsearch/plugins'
elasticsearchPlugin='/usr/share/elasticsearch/bin/plugin'
elasticsearchPluginPage='http://www.elastic.co/guide/en/elasticsearch/reference/current/modules-plugins.html'

#define a hash with the plugin name as the key and github user/plugin name as the value
declare -A customPlugins
customPlugins=( ["kopf"]="lmenezes/elasticsearch-kopf" )


#End of options
#############################################################################

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
    printf "This script needs to run as root to run the updates!\n" 1>&2
    exit 1
fi

if [[ "$1"  == "-h" ]]
then
    printf "Usage: update-elasticsearch-plugins [-y]\n\n"
    printf "This will update your elasticsearch plugins in one of two modes, interactive or automatic\n"
    printf "Interactive mode will ask before upgrading each plugin, skipping the plugin if you do not want to upgrade it.\n"
    printf "Automatic mode upgrade everything without asking if you give the -y flag\n\n"

    printf "Normally your plugin needs to be listed on the elasticsearch plugin page. However you can also manually add plugins hosted on github by editing the customPlugins hash in this script\n\n"
    exit

fi


printf "\n\nupdate-elasticsearch-plugins\n"

auto=0
if [[ "$1"  == "-y" ]]
then
    auto=1
    printf "\n\nRunning in auto mode, I will upgrade all plugins without asking!\n\n"
    sleep 1
fi

#check if curl is installed
command -v curl >/dev/null 2>&1 || { printf "\nERROR: curl is not installed\n\n"; exit 1; }

#ensure the elasticsearch plugin command exists
command -v $elasticsearchPlugin >/dev/null 2>&1 || { printf "\nERROR: elasticsearch plugin command $elasticsearchPlugin does not exist\n\n"; exit 1; }

printf "Obtaining current list of plugins from the elasticsearch website, please wait...\n"

#curl the es plugin page. Then grep for each url line (contains ulink), remove a bogus line, strip it down to just the url, then shove it in an array
esPlugins=(`curl -s $elasticsearchPluginPage | grep ulink | grep -v "be found under the" |sed 's/<a class="ulink" href="//' | sed 's/" target=".*//'`)
if [ "$esPlugins" == "" ]; then
    printf "\nERROR: curling $elasticsearchPluginPage failed\n"
    exit 1
fi

#ensure the es plugin dir exists
if [ -d "$elasticsearchPluginDir" ]; then
    #get a list of current plugins and shove it into an array
    installedPlugins=(`ls $elasticsearchPluginDir |grep -v preupgrade*`)
else
    printf "\nERROR: elasticsearchPluginDir $elasticsearchPluginDir does not exist\n"
    exit 1
fi

#look at each installed plugin and try to find its repo, then offer to update
printf "Looking at plugins\n"
for currentInstalledPlugin in "${installedPlugins[@]}"
do

    if [[ ${customPlugins["$currentInstalledPlugin"]} ]]
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
            printf "using custom plugin url instead of offical es plugin url for $currentInstalledPlugin\n"
            $elasticsearchPlugin -r $currentInstalledPlugin
            $elasticsearchPlugin -i ${customPlugins["$currentInstalledPlugin"]}
        fi

    else

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
                    $elasticsearchPlugin -r $currentInstalledPlugin
                    $elasticsearchPlugin -i $githubProject
                fi

                break
            fi

        done
    fi
done

printf "\nDone.\n"
