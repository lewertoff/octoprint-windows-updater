$venvPath = "C:\Octoprint\venv\" 
$components = "pip", "octoprint"

function selfElevate {
# Creates a new admin process if the current one is not admin level.
    # Get the ID and security principal of the current user account
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
    # Get the security principal for the Administrator role
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole))
 
       {
       # We are running "as Administrator" - so change the title and background color to indicate this
       $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
       $Host.UI.RawUI.BackgroundColor = "DarkBlue"
       clear-host
 
       }
    else
       {
       # We are not running "as Administrator" - so relaunch as administrator
 
       # Create a new process object that starts PowerShell
       $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
 
       # Specify the current script path and name as a parameter
       $newProcess.Arguments = $myInvocation.MyCommand.Definition;
 
       # Indicate that the process should be elevated
       $newProcess.Verb = "runas";
 
       # Start the new process
       [System.Diagnostics.Process]::Start($newProcess);
 
       # Exit from the current, unelevated, process
       exit
   }
}

function pipUpdate {
# Uses pip to update components in the venv.
    param (
        [string] $item
    )

    $pythonExe = "$venvPath\Scripts\python.exe"
    
    try {
        # Update file
        & $pythonExe -m pip install --upgrade $item
    }
    catch {
    write-host $_.Exception.Message -backgroundColor DarkRed
    }	
}

function warnPrompt {
# Helper function to assist with user greeting.
    if ((read-host "Ready to update? Will close OctoPrint & require admin level. (y/n)").ToLower() -ne "y") {
        write-host "Update canceled." -backgroundColor DarkRed
        exit
        }
}

function restartPrompt {
# Helper function to assist with restarting.
    if ((read-host "Update complete. Restart now? (y/n)").ToLower() -eq "y") {
        restart-computer
        }
    else {
        write-host "Restart canceled."
        }
}

function main {
    
    # Warn user
    warnPrompt

    # begin by checking if admin
    selfElevate

    # Make sure Octoprint is not running
    get-process -name *octoprint* -ErrorAction Continue | stop-process

    # Update each component
    foreach ($component in $components) {
        pipUpdate -item $component
    }
    
    # Restart NUC
    restartPrompt
}

main
        