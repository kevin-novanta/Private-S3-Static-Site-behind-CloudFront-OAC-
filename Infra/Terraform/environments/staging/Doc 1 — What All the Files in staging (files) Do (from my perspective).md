When I go into Infra/Terraform/environments/staging/, this is my **environment root**. Everything in here is just the _wiring_ that tells Terraform how to build staging using my reusable module.

- **backend.tf**
    
    This tells Terraform where to store the _state file_. Instead of keeping it locally, I point it to an S3 bucket + DynamoDB lock table so staging has its own safe, remote state.
    
- **providers.tf**
    
    This declares which AWS region Terraform talks to. I also define a special alias provider (aws.us_east_1) because CloudFront certificates _must_ be issued in us-east-1.
    
- **variables.tf**
    
    This defines the inputs staging needs: project name, domain, subdomain, price class, and whether IPv6 is on. It’s like a checklist so Terraform knows what values to expect.
    
- **main.tf**
    
    This is the heart of staging. I call my reusable cloudfront_oac module here and pass in the staging-specific values. This file wires everything together: the providers, the variables, and the module.
    
- **outputs.tf**
    
    This file tells Terraform which values I want back after applying. For example, it shows me the CloudFront URL, the distribution ID, and the bucket names. It’s like my quick reference sheet.
    
- **terraform.tfvars**
    
    This is where I actually put the staging values:
    
    - project name = p1-private-site-staging
        
    - domain name = kevinscloudlab.click
        
    - subdomain = cdn.staging.kevinscloudlab.click
        
    - etc.
        
        Terraform reads this automatically so I don’t have to type -var flags every time.
        
    

  

👉 Together, these files make staging a complete, isolated environment that knows how to call my module with the right values.