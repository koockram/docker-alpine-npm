# docker-alpine-npm
Dockerfile and scripts to create a lightweight image to download node packages

# Update 4/4/22 - Updated scripts. STarted using them in Alpine image in WSL since Docker Desktop became licensed charge on Windows.
 
-- Versions
   WSL = 2
   Alpine  = 3.15.0
     nodejs = 17.8.0
     npm = 8.1.3
     aws-cli = 1.19.105
     git = 2.34.1
     jq = 1.6
     openssh-keygen = 8.8
     openssh-client-common = 8.8

-- Enable WSL1 or 2 depending on compatibility of Windows Build
   Link https://docs.microsoft.com/en-us/windows/wsl/about

-- Get Alpine (or your favourite Linux distro) from Windows Store

-- When you run Alpine in WSL the first time it will prompt you to create a user/password
   There is no "sudo", so you run the "su -" command to switch to root using your own password

!  WSL2 will overwrite /etc/resolv.conf which is a symlink to /run/resolveconf/resolve.conf 
-- In Alpine, switch user to root and do the following

   $ rm /etc/resolv.conf
   $ echo "nameserver 8.8.8.8" > /etc/resolv.conf
   $ echo "[network]" > /etc/wsl.conf
   $ echo "generateResolvConf = false" >> /etc/wsl.conf

-- Exit from Alpine and start Powershell

   > wsl -l -v
   > wsl --shutdown
   > wsl -l -v
   > wsl -d Alpine

-- Back in Alpine as user root, update, upgrade, and install following

   $ apk update
   $ apk upgrade
   $ apk add nodejs npm jq openssh-keygen openssh-client-common aws-cli git

-- Concern about managing duplicates in Artifactory
!! Try experiment with two new repos with two versions of a pkg and see if they both resolve via virtual




-- Using 3 different types of analysis to obtain absolute list of packages
1. Look at "dependencies" section in package-lock.json
-- There can be nested dependencies
-- Close correlation with methods 2 & 3 for a sample of 2000+ packages, but with mismatch of 1 package

2. Look at "packages" section in package-lock.json
-- Simple data to analyse
-- Matched results of method 3
-- Used this one to do the pack operation *

3. Look at "resolved" files in package-lock.json
-- Complex data to analyse and parse
-- Matched results of method 2

