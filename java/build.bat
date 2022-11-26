@echo off
echo.
echo Compiles your Java code into classes.dex
echo Verified to work for Delphi XE6
echo.
echo Place this batch in a java folder below your project (project\java)
echo Place the source in project\java\src\com\yocharge\YoCharge
echo If your source file location or name is different, please modify it below.
echo This assumes a Win64 system with the 64-bit Java installed by the Delphi XE6 
echo installer in C:\Program Files\Java\jdk1.7.0_40
echo.

setlocal
                 
set ANDROID_JAR="C:\Users\Public\Documents\Embarcadero\Studio\14.0\PlatformSDKs\adt-bundle-windows-x86-20131030\sdk\platforms\android-19\android.jar"
set DX_LIB="C:\Users\Public\Documents\Embarcadero\Studio\14.0\PlatformSDKs\adt-bundle-windows-x86-20131030\sdk\build-tools\android-4.4\lib"
set EMBO_DEX="C:\Program Files\Embarcadero\Studio\14.0\lib\android\debug\classes.dex"
set PROJ_DIR=%CD%
set VERBOSE=0
set JAVASDK="C:\Program Files\Java\jdk1.7.0_40\bin"
set DX_BAT="C:\Users\Public\Documents\Embarcadero\Studio\14.0\PlatformSDKs\adt-bundle-windows-x86-20131030\sdk\build-tools\android-4.4\dx.bat"

echo.
echo Compiling the Java source files
echo.
pause
mkdir output 2> nul
mkdir output\classes 2> nul
if x%VERBOSE% == x1 SET VERBOSE_FLAG=-verbose
%JAVASDK%\javac %VERBOSE_FLAG% -Xlint:all -classpath %ANDROID_JAR% -d output\classes src\com\yocharge\YoCharge\BootReceiver.java

echo.
echo Creating jar containing the new classes
echo.
pause
mkdir output\jar 2> nul
if x%VERBOSE% == x1 SET VERBOSE_FLAG=v
%JAVASDK%\jar c%VERBOSE_FLAG%f output\jar\test_classes.jar -C output\classes com


echo.
echo Converting from jar to dex...
echo.
pause
mkdir output\dex 2> nul
if x%VERBOSE% == x1 SET VERBOSE_FLAG=--verbose
call %DX_BAT% --dex %VERBOSE_FLAG% --output=%PROJ_DIR%\output\dex\test_classes.dex --positions=lines %PROJ_DIR%\output\jar\test_classes.jar

echo.
echo Merging dex files
echo.
pause
%JAVASDK%\java -cp %DX_LIB%\dx.jar com.android.dx.merge.DexMerger %PROJ_DIR%\output\dex\classes.dex %PROJ_DIR%\output\dex\test_classes.dex %EMBO_DEX%

echo.
echo Now use output\dex\classes.dex instead of default classes.dex
echo And add broadcastreceiver to AndroidManifest.template.xml
echo.

:Exit

endlocal
