This folder is my **reusable module**. It’s the actual blueprint that builds S3, CloudFront, ACM, and Route 53. Any environment (staging, prod, etc.) can call this module and get the same secure setup.

- **main.tf**
    
    This is the big blueprint. It defines all the actual AWS resources:
    
    - S3 site bucket (private)
        
    - S3 logs bucket
        
    - ACM certificate (in us-east-1)
        
    - DNS validation records for the cert
        
    - CloudFront distribution with OAC
        
    - Route 53 alias that points my subdomain → CloudFront
        
        Basically, this is the engine.
        
    
- **variables.tf**
    
    This is the list of inputs the module needs. It matches what I pass in from staging: project name, domain, cdn domain, price class, IPv6 toggle, and tags. Without this, the module wouldn’t know what values to accept.
    
- **outputs.tf**
    
    This gives back the important info that other code (or me) might want: the CloudFront URL, the distribution ID, and the S3 bucket names.
    
- **versions.tf**
    
    This locks in the providers the module expects (hashicorp/aws) and declares that it accepts a special aliased provider (aws.us_east_1) for ACM. This keeps the module safe and predictable.
    
- **README.md** (if I add it)
    
    This would explain how to use the module and what inputs/outputs it expects.
    

  

👉 In short: cloudfront_oac is my reusable building block. Staging (and later prod) just plug into it by supplying the right values.