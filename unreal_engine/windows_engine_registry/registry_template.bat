@echo off

:: 不同引擎的根目录，和 UnrealVersionSelector.exe 的文件名有所不同，切换之前调整该参数即可
set UVS_PATH=D:\UE4.27\Engine\Binaries\Win64\UnrealVersionSelector.exe

:: 设置注册表项 DefaultIcon
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\DefaultIcon /ve /t REG_SZ /d """%UVS_PATH%""" /f

:: 设置注册表项 shell/open
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\open\command /ve /t REG_SZ /d """"%UVS_PATH%""" /editor """%%1"""" /f

:: 设置注册表项 shell/run
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\run /v Icon /t REG_SZ /d """%UVS_PATH%""" /f
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\run\command /ve /t REG_SZ /d """"%UVS_PATH%""" /game """%%1"""" /f

:: 设置注册表项 shell/rungenproj
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\rungenproj /v Icon /t REG_SZ /d """%UVS_PATH%""" /f
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\rungenproj\command /ve /t REG_SZ /d """"%UVS_PATH%""" /projectfiles """%%1"""" /f

:: 设置注册表项 shell/switchversion
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\switchversion /v Icon /t REG_SZ /d """%UVS_PATH%""" /f
reg add HKEY_CLASSES_ROOT\Unreal.ProjectFile\shell\switchversion\command /ve /t REG_SZ /d """"%UVS_PATH%""" /switchversion """%%1"""" /f

pause
