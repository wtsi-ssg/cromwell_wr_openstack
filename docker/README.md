 **Runtime attributes**
 
 We will mount <s3_mount_path> on host to docker container as volume with same <s3_mount_path> path. 
 (i.e. Mounting /home/ubuntu/mnt on host as volume to /home/ubuntu/mnt on docker container). 
 And we will also make docker_cwd to same path which is shared amount all the worker nodes and master node.
 
 ```
 ...
 
 runtime {
    docker:          docker
    docker_cwd:      "<s3_mount_path>/cromwell-executions"
    volume_str:      "<s3_mount_path>/:<s3_mount_path>"
    wr_cwd:          "${wr_cwd}"
    wr_cloud_os:     "${wr_cloud_os}"
    wr_cloud_flavor: "${wr_cloud_flavor}"
    wr_cloud_script: "${wr_cloud_script}"
  }
  
...

```
