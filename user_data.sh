    #!/bin/bash
aws ssm put-parameter \\
    --name "dev/goapi/db/password" \\
    --value "<PASSWORD-HERE>" \\
    --type String \\
    --tags [{"Key":"Region","Value":"us-east-1"},{"Key":"Environment", "Value":"Dev"},{"Key":"Service", "Value":"go-api-mysql"}]'

# write is as tf code 


# null resource FTW (SSM)

    sudo su root
    yum update -y && yum upgrade -y
    yum install golang -y
    yum install mysql-client-core-8.0 -y
    yum install awscli -y

    mkdir -p /home/ec2-user/go/{src,bin,pkg}
    chown -R ec2-user:ec2-user /home/ec2-user/go
    # deprecated since go 1.11
    # export GOROOT=/usr/lib/golang
    # export GOPATH=/home/ec2-user/go
    export PATH=$PATH:/usr/local/go/bin

    export PATH=$PATH:$GOPATH/bin
    export PATH=$PATH:$PATH:/usr/local/bin
    export PATH=$PATH:$PATH:/usr/bin
    export PATH=$PATH:$PATH:/bin
    export PATH=$PATH:$PATH:/usr/sbin
    export PATH=$PATH:$PATH:/sbin

    [ ! -d /opt/go-mysql-api ] && mkdir -p /opt/go-mysql-api/${var.environment};
    
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;

    DB_PASSWORD=$(aws ssm get-parameter --name ${DB_PASSWORD_PARAM} --region ${var.region} --with-decryption --output text --query Parameter.Value)
    # mysql -h ${DB_HOST} -u ${DB_USER} ${DB_NAME} -p$DB_PASSWORD
    cd /app/go-mysql-api && sudo go build -buildvcs=false -o go-api
    MYSQL_USER=${DB_USER} MYSQL_PASSWORD=$DB_PASSWORD MYSQL_HOST=${DB_HOST} MYSQL_PORT=${DB_PORT} MYSQL_DATABASE=${DB_NAME} ./go-api