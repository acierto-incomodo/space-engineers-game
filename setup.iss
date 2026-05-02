[Setup]
AppName=Space Engineers by StormGamesStudios
AppVersion=1.0.6
DefaultDirName={userappdata}\StormGamesStudios\NewGameDir\SpaceEngineers
DefaultGroupName=StormGamesStudios
OutputDir=C:\Users\melio\Documents\GitHub\space-engineers-game\output
OutputBaseFilename=SpaceEngineers_Launcher_Installer
Compression=lzma
SolidCompression=yes
AppCopyright=Copyright © 2025 StormGamesStudios. All rights reserved.
VersionInfoCompany=StormGamesStudios
AppPublisher=StormGamesStudios
SetupIconFile=space-engineers.ico
VersionInfoVersion=1.0.6.0
DisableProgramGroupPage=yes
; Habilitar selección de carpeta
DisableDirPage=yes

[Files]
Source: "C:\Users\melio\Documents\GitHub\space-engineers-game\dist\installer_updater.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\melio\Documents\GitHub\space-engineers-game\space-engineers.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\melio\Documents\GitHub\space-engineers-game\space-engineers.png"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{commonprograms}\StormGamesStudios\Space Engineers"; Filename: "{app}\installer_updater.exe"; IconFilename: "{app}\space-engineers.ico"; Comment: "Lanzador de Space Engineers"; WorkingDir: "{app}"
Name: "{commonprograms}\StormGamesStudios\Desinstalar Space Engineers"; Filename: "{uninstallexe}"; IconFilename: "{app}\space-engineers.ico"; Comment: "Desinstalar Space Engineers"

[Registry]
Root: HKCU; Subkey: "Software\Space Engineers"; ValueType: string; ValueName: "Install_Dir"; ValueData: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Run]
Filename: "{app}\installer_updater.exe"; Description: "Ejecutar Space Engineers"; Flags: nowait postinstall skipifsilent

[Code]
function IsDirectoryEmpty(DirPath: String): Boolean;
var
  FindRec: TFindRec;
begin
  Result := True;
  if DirExists(DirPath) then
  begin
    if FindFirst(DirPath + '\*', FindRec) then
    begin
      try
        repeat
          if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
          begin
            Result := False;
            Break;
          end;
        until not FindNext(FindRec);
      finally
        FindClose(FindRec);
      end;
    end;
  end;
end;

procedure RunUninstaller(DirPath: String);
var
  FindRec: TFindRec;
  ResultCode: Integer;
  Attempts: Integer;
begin
  if DirExists(DirPath) then
  begin
    // Busca cualquier archivo que coincida con unins*.exe (unins000.exe, unins001.exe, etc.)
    if FindFirst(DirPath + '\unins*.exe', FindRec) then
    begin
      try
        repeat
          // Ejecutar el desinstalador de forma muy silenciosa y esperar a que termine
          Exec(DirPath + '\' + FindRec.Name, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        until not FindNext(FindRec);
      finally
        FindClose(FindRec);
      end;
    end;

    // Esperar hasta que la carpeta esté vacía (máximo 5 segundos de espera activa)
    Attempts := 0;
    while (not IsDirectoryEmpty(DirPath)) and (Attempts < 10) do
    begin
      Sleep(500); // Esperar 500ms antes de volver a comprobar
      Attempts := Attempts + 1;
      
      // Intentar borrar lo que quede (por si son archivos de log o restos que el desinstalador no quitó)
      if Attempts > 5 then
      begin
        DelTree(DirPath, True, True, True);
      end;
    end;
  end;
end;

procedure UninstallOldVersion();
begin
  // 1. Revisar la ruta de la versión anterior específica
  RunUninstaller(ExpandConstant('{userappdata}\StormGamesStudios\NewGameDir\SpaceEngineers'));
  
  // 2. Revisar la ruta donde se va a instalar actualmente (por si es una reinstalación/actualización)
  RunUninstaller(ExpandConstant('{app}'));
end;

procedure CloseApp();
var
  ResultCode: Integer;
begin
  // Cierra el actualizador y el launcher si están abiertos
  Exec('taskkill', '/F /IM installer_updater.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill', '/F /IM win_launcher.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill', '/F /IM "SpaceEngineers.exe"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('taskkill', '/F /IM ""', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Durante la instalación, cierra cualquier instancia abierta
  if CurStep = ssInstall then
  begin
    CloseApp();
    UninstallOldVersion();
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  // Durante la desinstalación, cierra cualquier instancia abierta
  if CurUninstallStep = usUninstall then
  begin
    CloseApp();
  end;
end;