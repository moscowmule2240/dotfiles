@echo off

for %%A in (files/.*.*) do (
  echo mklink %USERPROFILE%\%%A %cd%\files\%%A
)

for /d %%A in (files/.*.*) do (
  echo mklink /D %USERPROFILE%\%%A %cd%\files\%%A
)

for %%A in (files/windows/.*.*) do (
  echo mklink %USERPROFILE%\%%A %cd%\files\windows\%%A
)
