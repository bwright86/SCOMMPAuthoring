# #############################################################################
# Wright Stuff Tech - SCRIPT - POWERSHELL
# FILENAME: BuildMP.ps1

# AUTHOR:  Brent Wright
# DATE:  12/29/2019
# EMAIL: brent.g.wright@gmail.com

## COMMENT:  Compiles an MP project with fragments, into a full SCOM MP.

## VERSION HISTORY
#   mm/dd/yyyy - user name - fixed bug or added new feature...

## TO ADD
# -Add a Function to ...
# -Fix the...
# #############################################################################

$here = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"


#region User Configuration

$MPBuildDir = "$here\Management Packs"
$outputDir = "$here\Output"


#endregion  User Configuration



$managementPacks = Get-ChildItem $MPBuildDir

    
if ( -not $(Test-Path $outputDir) ) {
    $null = New-Item $outputDir -ItemType Directory -Force
}

"Management Packs to build: {0}" -f $managementPacks.count

# Process each MP project in the MPBuildDir
foreach ($mp in $managementPacks) {

    # Read in a copy of the MP Template.
    [xml]$mpXML = Get-Content "$here\Templates\ManagementPack.xml"
    
    # Get a list of .mpx files in the MP project.
    $fragments = @(Get-ChildItem -Path $mp.fullname -Filter "*.mpx" -Recurse)

    "{0}: Fragments to add: {1}" -f $mp.Name, $fragments.count

    # Process each .mpx file
    foreach ($fragment in $fragments) {

        [xml]$fragXML = Get-Content $fragment.fullname

        # Ignore comments and empty childnodes
        $eligibleSections = $fragXML.ManagementPackFragment.ChildNodes | 
            Where-Object {$_.localname -ne "#comment" -and $_.haschildnodes}

        # Process each section of the manifest fragment separately.
        foreach ($section in $eligibleSections.localname) {

            "{0}: Merging section: {1}" -f $fragment.name, $section.localname

            foreach ($childNode in $fragXML.SelectNodes("ManagementPackFragment/$section").ChildNodes) {
            $mpXML.SelectNodes("/ManagementPack/$section").AppendChild($mpXML.ImportNode($childNode.clone(),$true))
            }
        }
    }

    $mpXML.Save("$outputDir\$($mp.Name).xml")
}