source env.sh

for host in $gdsvzbinsnew1 $gdsvzbinsnew2 $gdsvzbrub6
do
echo -n "Copying Key on $host..."
$SSH $host 2>/dev/null <<EOF 
mkdir -p /var/home/root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAo7XXOl5g8/RYkaFa3iJqTUj8tb+YOjDTTA/z32lbG8t1act6M1jafrCmZGfon20AnoTTtWR1R9kEe5KvmWwHXThjNQMv2wLHGIG8eHNxQKeEWzLloyrNA6r4D3eZ0aAAgrF/8KG+leY3zUV4xwlwUbP4gLY7m81/ep+C2R/dUeHQQjE49XXDFucXFbN11vxqpO5AG8sXGqqHf7D9ExIeb4wkiYdj2F2HLSKUwEbTQqtwab0S/VjgVMN70l1CRh/H5qbnYx8Yb5NNT3pMyns0bMh76GSoSPstH3QKH3hLaDXf2QwEWUHXOGEH1VsfUBEiaDCyR69bnsPl+ckZR02rWw== root@CDN-MGM-002" >> /var/home/root/.ssh/authorized_keys
### For Production change this key
EOF
echo "Done"
done
