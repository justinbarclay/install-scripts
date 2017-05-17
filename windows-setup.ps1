# Get ready to install Choco
Set-ExecutionPolicy AllSigned
# Don't forget to ensure ExecutionPolicy above
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Turn on developer mode
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

#Lets get git
choco install git -params '"/GitAndUnixToolsOnPath"'

# install programming stuff
choco install emacs

# Set upRuby environment
choco install ruby
choco install railsinstaller
gem install yard
gem install pry
gem install pik
gem install pry-doc

choco install python


#install bash/WLS
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
