# Instructions

This is a simple example that shows off how you can use the Venafi provider to create a certificate, import it to ACM and attach it to AWS services. For more information about the Venafi provider, check out the docs here: https://github.com/terraform-providers/terraform-provider-venafi 

A couple things you need to do to get this to work:
- Edit the Venafi provider credentials with a TPP server or Venafi Cloud instance you have access to. For more information on how to do this check out the provider documentation.
- Edit the AWS provider so that you have access to your AWS account. It's already halfway configured to use access and secret keys but if you wish to use env variables or a credentials file feel free to edit the configurations.

Once those two things are done, you can run the plans like any other terraform plan. 
Make sure both Terraform templates are in the same folder. vpc-aws-creation.tf creates the VPC needed for aws-main.tf to run properly.

Do the following:
- terraform init        ## This will initialize the providers 
- terraform plan        ## Allows you to check what exactly you are building
- terraform apply       ## Run the plan and create all the services and artifacts.

This entire process will be done in under 10 minutes and at the end the dns name of the LB will be shown as an output. Copy the link in to your web browser and accept any self-signed cert error message. If everything worked out properly, you should see a big "Hello World!" in your browser.

**Note:** This example doesn't use only free-tier AWS services, thus there would be a cost tied to running this example.


