[Setup]
AppName=School EVM
AppVersion=1.0.0
DefaultDirName={autopf}\SchoolEVM
DefaultGroupName=School EVM
OutputBaseFilename=SchoolEVM_Setup
Compression=lzma
SolidCompression=yes
OutputDir=setup_output

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\School EVM"; Filename: "{app}\school_evm.exe"
Name: "{commondesktop}\School EVM"; Filename: "{app}\school_evm.exe"
