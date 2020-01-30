# SCOM MP Authoring Tool

This is a Powershell project to assist in SCOM Management Pack Authoring.

It works like a scaffolding engine to combine multiple .mpx fragments (A common pattern for SCOM MP authoring), and merges them into a single XML Management Pack.

## SCOM VSAE Fragment Library

Kevin Holman maintains an up-to-date library of .mpx fragments, they are normally used in VSAE (Visual Studio Authoring Extension).

These fragments are common patterns for a variety of scenarios, and can be copied and modified to suite ones needs.

Here is a download link:

<https://gallery.technet.microsoft.com/SCOM-Management-Pack-VSAE-2c506737>

## Using this project

Below are the steps to use this project:

1. Download this repository locally. Command:

    ```git clone git@github.com:bwright86/SCOMMPAuthoring.git```

2. Download the **SCOM VSAE Fragment Library** from the below link:

    <https://gallery.technet.microsoft.com/SCOM-Management-Pack-VSAE-2c506737>

3. Create a new folder for your MP project in the ```\Management Packs``` folder, name it something concise and descriptive.

    **Note:** A good rule of thumb is to use *\<CompanyName\>*.*\<Application\>*.*\<UniqueIdentifier\>*

    **Example**:

    - IBM.MQ.Discovery
    - Fabrikam.Exchange.Core
    - Fabrikam.Exchange.Cluster
    - Etc...

4. Create a ```\Fragments``` folder in the root of your new MP project folder.

5. Copy the ```\Templates\Manifest.mpx``` file into the root of your new MP project folder.

6. Copy any number of .mpx fragments into the ```\<MPProject>\Fragments``` folder in your MP project, and modify them to suite your need.

7. Assemble your new Management Pack, by running either of the below:

    Execute the ```BuildMP.ps1``` script

    **OR**

    In VS Code, take advantage of the Task Runner, and use the configured "```Run Build Task```" (Ctrl + Shift + B)

    **Note:** This requires the ```Psake``` module to be installed.

8. After the script complets, check the ```\Output``` folder for the newly assembled SCOM Management Pack

Congratualations!!! You should have a fully assembled MP that is ready for import or signing/sealing.
