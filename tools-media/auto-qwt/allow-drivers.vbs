' This is a backup method of saying "Yes" to the "Would you like to install this device software?" prompt in recent versions of Windows 7/Windows Server 2008 R2 where a bug exists so trusting certificates still shows that prompt
' This is the result of Microsoft making the following hotfix from "no longer available":
' https://support.microsoft.com/en-us/help/2921916/the-untrusted-publisher-dialog-box-appears-when-you-install-a-driver-i
' Clicking on the "Update Available" link will just redirect you to a page where is tells you to upgrade to Windows 10
'
' Failed solution attempts:
'    - Found and tried to install the Microsft signed hotfix (MSU) that use to fix this issue from a third party and received a message saying "The update is not applicable to your computer."
'    - Installing Windows 7 SHA-256 support MSUs: Already installed
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
'        - I got a couple things to work using this such as: rundll32 AdvPack.dll,LaunchINFSection qvideo.inf,qvideo
'            - qvideo references the [qvideo] INF section which copies the files (You will see a file copy window show up quickly)
'            - Wouldn't create service when referencing [qvideo_Service_Inst]
'            - The xen*.inf drivers are a lot more complex so this is just going to be written off as too complex
'    - Get already installed QWT oem*.inf files from a previous installation in C:\Windows\inf directory before next QWT installation so it can use them and not have to install the driver again
'        - Driver installation is more complex than having INF/PNF files in that folder
'    - PnpUnattend.exe also gives the prompt despite its name
'
' Unattemped solutions:
'     - Install drivers in offlineServicing unattend pass (setup.exe has a /installCert option for Win7+ that looks promising)
'     - Temporarily hijack/overwrite pnpui.dll that rundll32.exe uses to make prompt and make function always return true (yes to the button being pressed). However, this seems even more hacky.
'         - rundll32 calls InstallSecurityPromptRunDllW which internally calls another exported function InstallSecurityPrompt to create the prompt
'         - It then appears to be using OpenEvent/SetEvent WinAPI functions to communicate back to the parent process drvinst.exe whether or not the user said yes to the prompt
'     - The hotfix "Symptoms" note that this only happens to SHA-256, SHA-384 and SHA-512 certificates
'         - Sign the drivers with a SHA-1 certificate (insecure, but we could make make a self-signed one on the fly)
'     - Something else that hasn't been thought of yet
'
' Solution:
'     - Found the correct KB (KB2921916) available for download at: http://thehotfixshare.net/board/index.php?autocom=downloads&showfile=18882
'     - Requires restart
'     - Could be installed in WindowsPE pass "Installing updates..."
'     - Trying to find if the MSU can be found not indexed on an offical Microsoft download server
'     - Not available on: https://catalog.update.microsoft.com
'     - Hotfix use to be available but Microsoft no longer does hotfixes for any OS: http://hotfixv4.microsoft.com/Windows%207/Windows%20Server2008%20R2%20SP1/sp2/Fix485407/7600/free/471834_intl_x64_zip.exe
'     - https://charismathics.zendesk.com/hc/en-us/articles/231993568-How-to-enable-SHA2-Support-on-Windows-7
'         - KB3033929 is already installed
'         - Correct KB is not part of standard updates, must be installed manually
'     - No support for verifying MSUs with Authenticode on Linux means we will have to do it before having it installed on Windows (Get-AuthenticodeSignature in PowerShell avilable on Windows 7)
'         - Even if it was supported we wouldn't do it for security reasons: https://blog.reversinglabs.com/blog/breaking-the-linux-authenticode-security-model

Set wshShell = WScript.CreateObject("WScript.Shell")

Do
    ' Set focus to window with given window title
    ret = wshShell.AppActivate("Windows Security")

    ' Press "i" (ALT key) to install device software if focus is successful
    If ret = True Then
        wshShell.SendKeys "i"
    End If

    WScript.Sleep 1000
Loop
