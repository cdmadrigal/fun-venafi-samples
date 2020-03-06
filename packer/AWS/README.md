# TPP Base Packer Install AWS

## Introduction
As workloads move to the cloud and in many cases multi-cloud, the need to be able to create standardized, repeatable and automated images are needed. Organizations wants their images or base snapshots across their environments to be identical as this provides a repeatable or reliable framework. This repository focuses on solutions that use Packer. Packer is a solution by Hashicorp that builds automated machine images. For more information check out their website at: https://packer.io/ 

## Getting Started 
**Note:** The files and instructions provided are for Azure based deployments. Check out the AWS folder if you want the AWS instructions/files. Further cloud products will be added over time.

Before using these files you will need Packer installed on your machine. https://packer.io/downloads.html 


## Instructions

- Open up your terminal and navigate to your cloned git repository with the Packer folder.
- Make the following changes to the 'secret-variables.json' file: 
  - Change the `venafi_password` variable value to the password you use to access the download.venafi.com site.
  - If you wish to set your own password for the EC2 instance you will need to change the `winrm_password` value. If you do change this, you will also need to make a change in the winrm-setup.ps1 file.
- Make the following change to the 'variables.json' file:
  - Edit the `venafi_user` variable to the email address used to access the download.venafi.com site.
- If you made a change to the `winrm_password` above you will need to edit the winrm-setup.ps1 file and change the netuser Administrator password to match the change you made.

**Note:** Please don't store files that have sensitive passwords in source control repos that can be accessed by multiple people. Best practice would suggest you leave the `winrm_password` and `venafi_password` values blank on files that are pushed out of your local machine.

- Once those changes have been made you are ready to run the Packer script. Run the following command:
    ```bash
    packer build -var-file=secret-variables.json -var-file=variables.json -timestamp-ui tpp-golden-image-ami.json 
    ```
- There's nothing else you need to do but wait, this process should take about 30 to 40 minutes to run from end to end. Essentially, Packer will spin up a new EC2 instance, download all the dependecies needed, TPP, unzip TPP and run the TPP .msi file. After this is done, it will remove the ability to winrm back in to the system (for security purposes) and create an AMI.

**Note:** The password you set as the `winrm_password` will NOT be the password of the EC2 instances based from the AMI. Part of the script resets the password set and randomly generates a new one during each deployment.

If you wish to see how a general output log of the process looks like, check out the sample-output.txt file provided.
