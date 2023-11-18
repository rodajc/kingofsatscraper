# kingofsatscraper
linux/unix shell script to convert [kingofsat.net](https://en.kingofsat.net) SATTV data to Services_KingOfSat_ALL.txt to be imported in dreamboxEDIT

## Description

If you watch satellite TV with a Linux based receiver running enigma2 firmware and you used to create your channel lists from [kingofsat.net](https://en.kingofsat.net) using [this kind of tool](http://home.caiway.nl/~fnijhuis/kingofsat/index.html) but you discovered that there is more to it, then read on.

This script uses the standard Linux commands wget to retrieve the kingofsat.net data and especially sed to parse the data. To execute, download it, give it the right permissions (chmod 755 kingofsat.sh) and type kingofsat.sh. No parameters required. The output is created in a file called Services_KingOfSat_ALL.txt in the directory where you executed the script.

more info: https://up.nl.eu.org/projects/kingofsat.html
