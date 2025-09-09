## Error 1:

This is my first error log after the "Updated Jenkins acceskey and secret accesskey ID in both my jenkinsfile and the jenkins UI so that both terraform outputs stage and the deploy stage run inside a withcredentials block that injects those two secrets as AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY" commit.

Jenkins ran into an error because jenks-staging-deploy wasn't authroized to perform s3:ListBucket on resource: "arn:aws:s3:::p1-private-site-staging-site-207567803283" because no identity-based policy allows the s3:ListBucket action. I simply made a policy for that user that allows the s3:ListBucket action.
