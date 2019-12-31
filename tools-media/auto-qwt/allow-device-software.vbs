' This is a hack for allowing device software to install automatically in recent versions of Windows 7 which is necessary because of Microsoft purposely removing that functionality in an effort to push Windows 10 (In recent builds of Windows 10, this prompt doesn't show up anymore):
' https://support.microsoft.com/en-gb/help/2921916/the-untrusted-publisher-dialog-box-appears-when-you-install-a-driver-i (Clicking on "Update Available" says the hotfix has been discontinued and to upgrade to Windows 10)
' This makes it so adding certificates to the trusted publisher list causes the "Would you like to install this device software?" prompt to show up either way
'
' Other attempts before resorting to this:
'   * Found and tried to install the Microsft signed hotfix (MSU) that use to fix this issue from a third party and received a message saying "The update is not applicable to your computer."
'   * Enabled bcdedit nointegritychecks, ignored in Windows 7: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#parameter
'   * Installing all updates
'   * gpedit.msc enable code signing for drivers
'
' Possibly better solutions:
'   * Find and remove KB that planted this restriction (Removal is probably blocked)
'   * Put oem* files in C:\Windows\inf directory before QWT installation (Extract INF files from QWT installer and use pnputil command to install them... Actually, this would not work as pnputil will also create the prompt. However, maybe just copy the INF files into the INF directory then compile them to PNF files seperately if necessary)
'   * Install drivers in offlineServicing unattend pass (setup.exe has a /installCert option for Win7+ that looks promising)
'   * Temporarily hijack/overwrite pnpui.dll that rundll32.exe uses to make prompt and make function always return true (yes to the button being pressed). However, this seems even more hacky.
'   * Some other unknown quirk or undocumented feature
'   * Looks like if we can extract the INF files from QWT (or otherwise) then we can simply install the drivers silently as seen below
'       * rundll32 AdvPack.dll,LaunchINFSection my.inf,,3
'       * https://stackoverflow.com/questions/24510472/install-driver-silent
'       * Advpack.dll is for processing INF files
'       * More links:
'       * https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/gg441316(v%3Dvs.85)
'       * http://www.mdgx.com/INF_web/launch.htm
'   * Drivers stored in: C:\Program Files\Invisible Things Lab\Qubes Tools\drivers
'       * Maybe we can install them from there once the drivers are extracted by QWT before it processes the INF files itself

Set wshShell = WScript.CreateObject("WScript.Shell")

Do
    ' Sets focus to window with given window title
    ret = wshShell.AppActivate("Windows Security")

    ' Press "i" (ALT key) to install device software if focus is successful
    If ret = True Then
        wshShell.SendKeys "i"
    End If

    WScript.Sleep 1000
Loop
