rmdir /s /q "%APPDATA%\factorio\mods\biter-pet
robocopy "%HOMEPATH%\Desktop\biter-pet" "%APPDATA%\factorio\mods\biter-pet" /MIR /XO /XC /XN
del "%APPDATA%\factorio\mods\biter-pet\deploy.bat"
cls
echo Synchronization complete!