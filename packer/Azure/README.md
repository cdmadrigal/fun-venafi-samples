# TPP Base Packer Install Azure

## Introduction
As workloads move to the cloud and in many cases multi-cloud, the need to be able to create standardized, repeatable and automated images are needed. Organizations wants their images or base snapshots across their environments to be identical as this provides a repeatable or reliable framework. This repository focuses on solutions that use Packer. Packer is a solution by Hashicorp that builds automated machine images. For more information check out their website at: https://packer.io/ 

## Getting Started
**Note:** The files and instructions provided are for Azure based deployments. Check out the AWS folder if you want the AWS instructions/files. Further cloud products will be added over time.

Before using these files you will need Packer installed on your machine. https://packer.io/downloads.html

## Instructions

- Make the following change to the 'secret-variables.json' file:
  - Change the `venafi_password` variable value to the password you use to access the download.venafi.com site.
- Make the following change to the 'variables.json' file:
  - Edit the `venafi_user` variable to the email address used to access the download.venafi.com site.
  
**Note:** Please don't store files that have sensitive passwords in source control repos that can be accessed by multiple people. So if you add your password to the 'secret-variable.json' file, DON'T push it up to a source control system.

- Once those changes have been made you are ready to run the Packer script. Run the following command: 
    ```bash
    packer build -var-file=secret-variables.json -var-file=variables.json -timestamp-ui tpp-golden-image-ami.json 
    ```
- There's nothing else you need to do but wait, this process should take about 60 minutes to run from end to end. Essentially, Packer will create an instance on Azure with all the dependencies and TPP installed on it, deprovision it and create a snapshot of the instance and store that as an image.
- All of the files will be downloaded and stored in the C:\Users\Public\Downloads folder.

If you wish to see how a general output log of the process looks like, check out the sample-output.txt file provided.