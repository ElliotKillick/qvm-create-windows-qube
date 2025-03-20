' Copyright (C) 2023 Elliot Killick <contact@elliotkillick.com>
' Licensed under the MIT License. See LICENSE file for details.

' This is a backup method of saying "Yes" to the "Would you like to install this device software?" prompt in recent versions of Windows 7/Windows Server 2008 R2 where a bug exists causing Windows to still show that prompt whether or not the drivers are backed by a trusted certificate
' This is the result of Microsoft making the following hotfix "no longer available":
' https://support.microsoft.com/en-us/help/2921916/the-untrusted-publisher-dialog-box-appears-when-you-install-a-driver-i
' Clicking on the "Update Available" link will just redirect to a page where it tells you to upgrade to Windows 10
'
' Failed solution attempts:
'    - Tried a couple MSUs that turned out not to be the correct ones to fix this issue
'    - Enabled bcdedit nointegritychecks, ignored in Windows 7: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#parameter
'    - Installing all updates
'    - gpedit.msc enable code signing for drivers
'    - Looks like if we might be able to extract the INF files from QWT (or otherwise) then we can simply install the drivers silently as seen below
'        - rundll32 AdvPack.dll,LaunchINFSection my.inf,,3
'        - https://stackoverflow.com/questions/24510472/install-driver-silent
'        - Advpack.dll is for processing INF files
'        - https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/gg441316(v%3Dvs.85)
'        - http://www.mdgx.com/INF_web/launch.htm
'        - Drivers stored in: C:\Program Files\Invisible Things Lab\Qubes Tools\drivers
'        - INF DefaultInstall/Install in right-click context menu is legacy: https://social.msdn.microsoft.com/Forums/en-US/60f4b917-93c9-400a-b91a-15375a8793bf/installing-driver-using-inf-file-from-command-line-on-windows-7-64-bit-failing?forum=wdk
'        - Useful info about INF files: https://web.archive.org/web/20170923174452/http://www.sokoolz.com/addons/r64/ADVANCED_INF.pdf
'        - I got a couple things to work using this command: rundll32 AdvPack.dll,LaunchINFSection qvideo.inf,qvideo
'            - qvideo references the [qvideo] INF section which copies the files (You will see a file copy window show up quickly)
'            - Wouldn't create service when referencing [qvideo_Service_Inst]
'            - The xen*.inf drivers are a lot more complex so this is just going to be written off as not viable
'    - Get already installed QWT oem*.inf files from a previous installation in C:\Windows\inf directory before next QWT installation so it can use them and not have to install the driver again
'        - Driver installation is more complex than having INF/PNF files in that folder
'    - PnpUnattend.exe also gives the prompt despite its name
'
' Unattemped solutions:
'     - Install drivers in offlineServicing unattend pass (setup.exe has a /installCert option for Windows 7+ which looks promising)
'     - Temporarily hijack/overwrite the pnpui.dll that rundll32.exe uses to make prompt so that the called function always "returns true" to the button being pressed
'         - rundll32 calls InstallSecurityPromptRunDllW which internally calls another exported function InstallSecurityPrompt to create the prompt
'         - OpenEvent/SetEvent WinAPI functions communicate back to the parent process drvinst.exe on whether or not the user said yes to the prompt
'         - Very hacky
'     - The hotfix "Symptoms" notes that this only happens to SHA-256, SHA-384 and SHA-512 certificates
'         - Sign the drivers with a SHA-1 certificate
'             - Insecure
'             - We would have to convince Xen to sign their drivers with SHA-1
'             - Unless we self-sign the drivers ourselves on-the-fly
'                 - Seems like it would require WDK so this is off the table
'     - Something else that hasn't been thought of yet
'
' Solution:
'     - Found the correct KB (KB2921916) available for download at: http://thehotfixshare.net/board/index.php?autocom=downloads&showfile=18882
'         - The KB number was in the original help URL and the "Update Available" link the entire time
'     - Requires restart
'     - Could be installed in WindowsPE pass during "Installing updates..."
'     - Trying to find if the MSU can be found not indexed on an offical Microsoft download server
'     - Not available on: https://catalog.update.microsoft.com
'     - Hotfix used to be available but Microsoft no longer does hotfixes for any OS: http://hotfixv4.microsoft.com/Windows%207/Windows%20Server2008%20R2%20SP1/sp2/Fix485407/7600/free/471834_intl_x64_zip.exe
'         - They seem to have moved the hotfixes on to here, but still can't find the one we're looking for: https://www.catalog.update.microsoft.com/Search.aspx?q=hotfix+for+Windows+7
'     - https://charismathics.zendesk.com/hc/en-us/articles/231993568-How-to-enable-SHA2-Support-on-Windows-7
'         - KB3033929 is already installed
'         - Correct KB is not part of standard updates, must be installed manually
'     - No support for verifying MSUs with Authenticode on Linux means we will have to do it before it's installed on Windows (Get-AuthenticodeSignature PowerShell cmdlet avilable in Windows 7)
'         - Even if it was supported we wouldn't do it for security reasons: https://blog.reversinglabs.com/blog/breaking-the-linux-authenticode-security-model
'     - thehotfixshare.net does not support HTTPS
'     - I have archived the site and the MSU download
'         - https://web.archive.org/http://thehotfixshare.net/board/index.php?autocom=downloads&showfile=18882
'         - https://web.archive.org/http://thehotfixshare.net/board/index.php?autocom=downloads&req=download&code=confirm_download&id=18882
'         - This file is authenticode signed by Microsoft
'         - I confirmed this MSU fixes the issue

Set wshShell = WScript.CreateObject("WScript.Shell")

Do
    ' Set focus to window with given window title
    isFocused = wshShell.AppActivate("Windows Security", 0)

    ' If focus is successful
    If isFocused = True Then
        ' Press "i" (ALT key) to install device software
        wshShell.SendKeys "i"
    End If

    WScript.Sleep 1000
Loop
