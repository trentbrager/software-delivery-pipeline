# Software Delivery Pipeline HW

Added a manual approval stage to the pipeline from class. After the build, the pipeline waits and sends an email (SNS) to approve before it deploys.

Stages: Source -> Build -> ManualReview -> Deploy

## Files

- `templates/app-codepipeline-approval-template.json` - pipeline with the approval stage
- `templates/app-codepipeline-template-original-fixed.json` - class template with fixes so it would deploy (launch template instead of launch config, CodeDeploy role permissions, newer CodeBuild image)
- `verification/verify.sh` - CLI commands used to check it

App repo: https://github.com/trentbrager/python-project

## Deploy

Deploy in CloudFormation (us-east-1) by uploading `app-codepipeline-approval-template.json`, filling in the parameters, and confirming the SNS email.
