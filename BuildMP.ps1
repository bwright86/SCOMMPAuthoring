# #############################################################################
# Wright Stuff Tech - SCRIPT - POWERSHELL
# FILENAME: BuildMP.ps1

# AUTHOR:  Brent Wright
# DATE:  12/29/2019

## COMMENT:  Compiles an MP project with fragments, into a full SCOM MP.

## VERSION HISTORY
#   01/30/2020 - Updated XML merging to use a list of nodes to merge. This reduces issues with merging at incorrect node level.
#   02/02/2020 - Now sorting childnodes at the end of merge. (Validation was flagging some ModuleTypes that were out of order.)
#   03/08/2020 - Improved merging of parent nodes, fixed issue where child nodes were duplicated after a parent node was merged for a sibling node.
#              - Manifest's Build version is incremented now for every run, Major, Minor, and revision are carried over from previous version.

## TO ADD
# -Add a Function to ...
# -Fix the...
# #############################################################################

param ([string]$MPDir)

$here = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"


#region User Configuration

$MPBuildDir = "$here\Management Packs"
$outputDir = "$here\Output"

# A list of paths where child nodes will be merged into a single MP.
$xmlChildPaths = @(
    "Manifest"
    "TypeDefinitions/EntityTypes/ClassTypes"
    "TypeDefinitions/EntityTypes/RelationshipTypes"
    "TypeDefinitions/ModuleTypes"
    "TypeDefinitions/MonitorTypes"
    "TypeDefinitions/SecureReferences"
    "Monitoring/Discoveries"
    "Monitoring/Monitors"
    "Monitoring/Recoveries"
    "Monitoring/Rules"
    "Monitoring/Tasks"
    "Categories"
    "Presentation/ConsoleTasks"
    "Presentation/FolderItems"
    "Presentation/Folders"
    "Presentation/StringResources"
    "Presentation/Views"
    "Resources"
    "LanguagePacks/LanguagePack/DisplayStrings"
    "LanguagePacks/LanguagePack/KnowledgeArticles"
)

# A list of paths where child nodes should be sorted.
$xmlChildPathSorts = @(
    "TypeDefinitions/ModuleTypes"
)

# XML Nodes to ignore.
$ignoreXMLNodes = @(
    "/#comment"
)


#endregion  User Configuration

# helper function to recursively return the deepest node paths
function Get-XMLChildNodePath {
    param ($XMLNode, $CurrentPath = "")

    if ($xmlnode.hasChildNodes) {
        foreach ($node in $xmlnode.childnodes) {
            Get-XMLChildNodePath -xmlNode $node -currentPath $("$currentPath/{0}" -f $node.localname)
        }
    } else {
        $CurrentPath
    }
}


# If MP folder was provided, compile a single MP.
if ( $PSBoundParameters.ContainsKey("MPDir") ) {

    $managementPacks = Get-Item $MPDir

# Otherwise, retrieve all MP folders and compile each one.
} else {
    $managementPacks = Get-ChildItem $MPBuildDir
}


if ( -not $(Test-Path $outputDir) ) {
    $null = New-Item $outputDir -ItemType Directory -Force
}

"The following nodes are being ignored for merging:`n- {0}`n`n" -f $($ignoreXMLNodes -join "`n- ") | Write-Host -ForegroundColor Cyan

"Management Packs to build: {0}" -f $managementPacks.count | Write-Host

# Process each MP project in the MPBuildDir
foreach ($mp in $managementPacks) {

    # Read in a copy of the MP Template.
    [xml]$mpXML = Get-Content "$here\Templates\ManagementPack.xml"

    # Get a list of .mpx files in the MP project, along with the manifest.mpx.
    $fragments = @(Get-ChildItem -Path $mp.fullname -Filter "*.mpx" -Recurse)

    #region Manifest - Increment Build
    
    
    # Read in the manifest xml.
    $manifestXMLPath = Join-Path $mp.FullName "Manifest.mpx"
    [xml]$manifestXML = Get-Content -Path $manifestXMLPath

    $curVer = [version]$manifestXMLPath.ManagementPackFragment.manifest.Identity.version

    $newVer = [version]::new($curVer.Major,$curVer.Minor,$curVer.Build+1,$curVer.Revision)

    # Update the manifest version with the new version.
    $manifestXML.ManagementPackFragment.Manifest.Identity.version = $newVer.ToString()

    $manifestXML.Save($manifestXMLPath)

    "  Manifest version build incremented: $curVer -> $newVer"
    
    
    #endregion  Manifest - Increment Build



    "{0}: Fragments to add: {1}" -f $mp.Name, $fragments.count | Write-Host

    # Process each .mpx file, including the manifest.mpx
    foreach ($fragment in $fragments) {

        "  Fragment file: {0}" -f $fragment.name | Write-Host -ForegroundColor Green

        [xml]$fragXML = Get-Content $fragment.fullname

        # Build a list of all leaf nodes.
        # Items will be removed as they are merged.
        # At the end, any items left will be reported as a warning.
        $fragXMLLeafNodes = Get-XMLChildNodePath -XMLNode $fragXML.ManagementPackFragment

        # Build a list of XPaths that have children in XML fragment.
        $eligibleXPaths = foreach ($xmlChildPath in $xmlChildPaths) {
            if ( $fragXML.SelectNodes("ManagementPackFragment/$xmlChildPath").count -gt 0 ) {
                $xmlChildPath
            }
        }

        # List of nodes to skip merging after parent node is merged.
        $skipDueToParentMerge = @()

        # Perform the merge into the MP XML document.
        foreach ($XPath in $eligibleXPaths) {

            "    Adding nodes from XPath: $XPath" | Write-Host

            # Check if node was merged in previous parent merge.
            if ( $($skipDueToParentMerge | Where-Object {$XPath -like "*$_*"}).Count -gt 0 ) {

                "      Skipping node... Merged from previous parent node merge." | Write-Host -ForegroundColor Yellow

            # Check if the XPath exists in MP XML.
            } elseif ($mpXML.SelectNodes("ManagementPack/$XPath").count -gt 0) {

                foreach ($childNode in $fragXML.SelectNodes("ManagementPackFragment/$xpath").ChildNodes) {
                    $mpXML.SelectNodes("/ManagementPack/$XPath").AppendChild($mpXML.ImportNode($childNode.clone(),$true)) | Out-Null
                }

                # Remove any items that were merged.
                $fragXMLLeafNodes = $fragXMLLeafNodes | Where-Object {$_ -notlike "/$XPath*"}

            # Otherwise, find the deepest node that does exist, and merge from there.
            } else {

                # Move backwards in XPath until node exists in MP XML, then add node 1 level deeper.
                $nodeNotExist = $true
                while ($nodeNotExist) {

                    # Keep the XPath that is 1 level deeper, to use when parent node does exist.
                    $childXPath = $XPath

                    $XPath = $(Split-Path -Path $XPath -Parent) -replace "\\","/"

                    "      XPath doesn't exist, trimming to: $XPath" | Write-Verbose

                    if ($mpXML.SelectNodes("ManagementPack/$XPath").count -gt 0) {
                        $nodeNotExist = $false
                    }
                }

                $childNode = $fragXML.SelectNodes("ManagementPackFragment/$childXPath")
                $mpXML.SelectNodes("/ManagementPack/$XPath").AppendChild($mpXML.ImportNode($childNode.clone(),$true)) | Out-Null
                $skipDueToParentMerge += $childXPath

                "      ChildNode `"{0}`" added to parent: {1}" -f $(split-path $childXPath -Leaf), $XPath | Write-Host -ForegroundColor Yellow

                # Remove any items that were merged.
                $fragXMLLeafNodes = $fragXMLLeafNodes | Where-Object {$_ -notlike "/$childXPath*"}
            }
        } # Foreach: XPath

        $ignoreXMLNodesRegex = "^$($ignoreXMLNodes -join "|^")"
            $fragXMLLeafNodes = $fragXMLLeafNodes | Where-Object {$_ -notmatch $ignoreXMLNodesRegex}

        if ($fragXMLLeafNodes.count -gt 0) {
            $fragXMLLeafNodes | ForEach-Object {"Fragment node not merged: $_"} | Write-Warning
        }
    } # Foreach: Fragment

    # Sort child nodes alphabetically.
    foreach ($childXPath in $($xmlChildPaths | Where-Object {$_ -in $xmlChildPathSorts}) ) {

        $([System.Xml.XmlNode]$orig = $mpXML.ManagementPack.SelectSingleNode($childXPath))

        # Check that node exists.
        if ($null -ne $orig -and $orig.ChildNodes.count -gt 0) {
            $orig.ChildNodes | Sort-Object LocalName -Descending | ForEach-Object { $mpXML.ManagementPack.SelectSingleNode($childXPath).PrependChild($_) } | Out-Null
            "Sorting childnodes for: $childXPath" | Write-Host -ForegroundColor White
        }
    }

    $mpXML.Save("$outputDir\$($mp.Name).xml")

    "Writing final MP for: $($mp.Name)`n`n`n" | Write-Host -ForegroundColor Green
}