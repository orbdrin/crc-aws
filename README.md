<!-- About the Project -->
# Cloud Resume Challenge (CRC)
The Cloud Resume Challenge is a hands-on project first set by Forrest Brazeal as a means of exploring many of the skills used by real cloud and DevOps engineers in a practical fashion. It provides a list of challenge requirements and not much else, placing the onus on the person undertaking the project to learn fast and google well if they hope to complete it. Further details on the AWS flavor of the challenge can be found [here](https://cloudresumechallenge.dev/docs/the-challenge/aws/). Since its inception, several optional extensions to the challenge have been proposed by the community as well. As we'll cover in a bit, I opted to go for the Terraform your Cloud Resume Challenge as well, details of which can be found [here](https://cloudresumechallenge.dev/docs/extensions/terraform-getting-started/).

You can visit the live demo site at [jinningtioh.com](https://jinningtioh.com).

<!-- Blog -->
# Blog
## Certification
Before even attempting the challenge proper, the suggested first step is earning the fundamental [AWS Cloud Practitioner certification](https://aws.amazon.com/certification/certified-cloud-practitioner/). However, I wanted more details on AWS services and decided to go a little further, earning the [AWS Solution Architect - Associate](https://aws.amazon.com/certification/certified-solutions-architect-associate/) instead.

## Site Content (HTML, CSS, JavaScript)
Being very rusty in HTML (think the Frontpage days) and having minimal experience with CSS and JavaScript, I opted to keep things simple and found a one page resume template that suit my needs. The site was done in HTML and styled with CSS to mold it into a hopefully presentable resume/CV. A placeholder JavaScript file for our visitor counter was created and referenced in the HTML file as well. We'll return to the JS script in a bit.

## Terraform (Infrastructure as Code)
With the growing ubiquity of Terraform as an IaC tool, I knew that I'd want to incorporate Terraform instead of the AWS native CloudFormation to build my infrastructure from the ground up. The official documentation proved invaluable in figuring things out, and I made copious use of the examples. I ended up dividing up the project into two separate modules for the frontend and backend services, with an additional runtime module which calls on both and allows for overriding the default variables at runtime to keep things neat.

## Frontend (S3, CloudFront, Route 53 (DNS), ACM)
A public-read S3 bucket was configured as a static website to host the website proper. A CloudFront distribution was setup and an SSL certificate was obtained from AWS Certificate Manager (ACM) to meet the challenge requirement of only serving the site via HTTPS. Furthermore a custom domain name was purchased via Route 53 and pointed to the CloudFront distribution. I encountered some trouble here but eventually managed to set the appropriate DNS records after some troubleshooting.

## Backend (DynamoDB, Lambda, API, CloudWatch)
This was undoubtedly the most time-consuming part of the challenge. I decided to begin with provisioning the single item DynamoDB database which would host our visitor counter. Simple enough. Building the Lambda function came next, which I opted to code in Python for the practice. I made use of the AWS console's built in test function to ensure that both the database and function were working as expected. Next was setting up the API and integrating the lambda function. Though not strictly a challenge requirement, setting up separate CloudWatch logs for both the lambda function and API Gateway proved invaluable for leaving a trail of breadcrumbs to troubleshoot errors. This brings us back to the earlier JS script, which was setup to invoke the lambda function via the API URL to display the visitor counter.

## Source Control, CI/CD
The final step was to setup source control as well as a continuous integration and deployment (CI/CD) pipeline here on GitHub. Since our frontend and backend was already neatly separated in modules, only a single repository was necessary rather than the two suggested by the original challenge. GitHub Actions were setup to ensure that any changes to the source/infrastructure would be properly translated to the production environment.
