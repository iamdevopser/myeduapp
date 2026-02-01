; MyEduApp - Tek tikla kurulum (Inno Setup)
; Kullanici bu EXE'yi indirir, calistirir; gerisi otomatik.

#define MyAppName "MyEduApp"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "MyEduApp"
#define MyAppExeName "MyEduApp-Setup.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\MyEduApp
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=yes
DisableWelcomePage=no
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=MyEduApp-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\windows\runner\resources\app_icon.ico
OutputDir=..\dist
Uninstallable=no
; Gerekli dosyalar dist klasorunde; build script once onlari uretir
SourceDir=..\dist

[Files]
; Kurulum script'i ve bagimliliklari gecici klasore kopyala
Source: "MyEduApp.cer"; DestDir: "{tmp}\MyEduAppSetup"; Flags: ignoreversion
Source: "my_edu_app.msix"; DestDir: "{tmp}\MyEduAppSetup"; Flags: ignoreversion
Source: "KURULUM.ps1"; DestDir: "{tmp}\MyEduAppSetup"; Flags: ignoreversion

[Run]
; PowerShell ile kurulum script'ini calistir (yonetici miras alir)
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoProfile -WindowStyle Normal -File ""{tmp}\MyEduAppSetup\KURULUM.ps1"""; \
  StatusMsg: "MyEduApp kuruluyor..."; \
  Flags: waituntilterminated

[Code]
var
  LaunchButton: TButton;

procedure LaunchButtonClick(Sender: TObject);
var
  ErrorCode: Integer;
  LaunchScript: String;
begin
  // PowerShell ile MSIX uygulamasını aç
  LaunchScript := '$pkg = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" } | Select-Object -First 1; ' +
    'if ($pkg) { $manifest = [xml](Get-AppxPackageManifest $pkg); ' +
    '$appId = $manifest.Package.Applications.Application.Id; ' +
    'Start-Process "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId" }';
  
  ShellExec('open', 'powershell.exe', '-ExecutionPolicy Bypass -NoProfile -Command "' + LaunchScript + '"', 
    '', SW_HIDE, ewNoWait, ErrorCode);
end;

procedure InitializeWizard;
begin
  WizardForm.WelcomeLabel2.Caption :=
    'Bu sihirbaz MyEduApp uygulamasini bilgisayariniza kuracak.' + #13#10 + #13#10 +
    'Gereksinimler otomatik kontrol edilip yuklenecek, eski kurulumlar ve veritabani temizlenecek, ' +
    'sertifika yuklenecek ve uygulama kurulacak. Ek bir islem yapmaniz gerekmez.';
end;

procedure CurPageChanged(CurPageID: Integer);
var
  ButtonTop: Integer;
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedLabel.Caption :=
      'MyEduApp basariyla kuruldu!' + #13#10 + #13#10 +
      'Asagidaki butona tiklayarak uygulamayi acabilirsiniz.' + #13#10 +
      'Baslat menusunden "MyEduApp" yazarak her zaman erisebilirsiniz.';
    
    // Launch butonu oluştur
    ButtonTop := WizardForm.FinishedLabel.Top + WizardForm.FinishedLabel.Height + 30;
    
    LaunchButton := TButton.Create(WizardForm);
    LaunchButton.Parent := WizardForm.FinishedPage;
    LaunchButton.Left := ScaleX(100);
    LaunchButton.Top := ScaleY(ButtonTop);
    LaunchButton.Width := ScaleX(220);
    LaunchButton.Height := ScaleY(40);
    LaunchButton.Caption := 'MyEduApp''i Ac';
    LaunchButton.Font.Style := [fsBold];
    LaunchButton.Font.Size := 11;
    LaunchButton.OnClick := @LaunchButtonClick;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ErrorCode: Integer;
  LaunchScript: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Kurulum sonrası otomatik uygulamayı aç
    Sleep(3000); // Kısa bekleme (kurulum tamamlansın)
    LaunchScript := '$pkg = Get-AppxPackage | Where-Object { $_.Name -like "*myeduapp*" } | Select-Object -First 1; ' +
      'if ($pkg) { $manifest = [xml](Get-AppxPackageManifest $pkg); ' +
      '$appId = $manifest.Package.Applications.Application.Id; ' +
      'Start-Process "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId" }';
    
    ShellExec('open', 'powershell.exe', '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "' + LaunchScript + '"', 
      '', SW_HIDE, ewNoWait, ErrorCode);
  end;
end;
