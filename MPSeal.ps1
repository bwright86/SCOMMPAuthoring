# #############################################################################
# Wright Stuff Tech - SCRIPT - POWERSHELL
# FILENAME: MPSeal.ps1

# AUTHOR:  Brent Wright
# DATE:  02/03/2020

## COMMENT:  Description of script.

## VERSION HISTORY
#   mm/dd/yyyy - user name - fixed bug or added new feature...

## TO ADD
# -Add a Function to ...
# -Fix the...
# #############################################################################


param ([string]$XMLFile)

#region User Configuration


# Folder for input/output
$inputFolder = "$PSScriptRoot\Output\"
$outputFolder = "$PSScriptRoot\Output\"

# A public key created with "sn.exe" (Strong Naming tool)
$keyFile = "$PSScriptRoot\PublicKey.snk"

# A folder with the required .mp files to cover references.
$MPReferenceFolder = "$PSScriptRoot\SupportTools\ManagementPacks"

# Name of the company to seal in MP
$CompanyName = "Fabrikam"


#endregion  User Configuration


if (-not $(Get-Command MPSeal.exe)) {
    throw "Cannot locate MPSeal.exe application, please your PATH..."
}


if ($PSBoundParameters.ContainsKey("XMLFile")) {

    $chosenFile = $XMLFile

} else {

    $mpXMLFiles = Get-ChildItem -Path $inputFolder -Filter "*.xml"
    $choices = @()
    $count = 1
    foreach ( $file in $mpXMLFiles ) {
        $choices += [System.Management.Automation.Host.ChoiceDescription]"&$count-$($file.name)"
    }

    $userChoice = $host.UI.PromptForChoice("Seal an MP", "Please choose the MPXML to seal:",$choices,0)
    $chosenFile = $mpXMLFiles[$userChoice]

}

MPSeal.exe $chosenFile /Keyfile $keyFile /Company $CompanyName /Outdir $outputFolder