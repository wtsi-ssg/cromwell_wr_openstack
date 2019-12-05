# Cromwell-WR-Openstack (GATK JointCalling)


## Setting up files

**1. Cromwell Configuration file:**

a) Without mysql:
Refer "cromwell.conf" and pass below mentioned variables from input.json :
- wr_cwd : Current working directory on wr worker nodes (Im using /home/ubuntu)
- cloud_script : cloud script location on local host where you will be triggering your cromwell wdl file. This script will have any commands which need to get executed on wr worker node as soon as it comes up and before any other wdl commands get run on it. I'm using this script to mount my s3 bucket onto the worker node at location /home/ubuntu/mnt (Please refer file named "cloud.script" from this the repo)
- wr_cloud_os : Openstack image name which has java and all other software/tools installed 
- wr_cloud_flavor: Any specific cloud vm flavor depending on the workflow (eg. m1.medium, m2.small)
- s3_mount_path: Mount path of s3 bucket which will be used as root directory of your cromwell and will be a shared location between master and all the wr worker nodes (eg. /home/ubuntu/mnt/). Please note that this variable will not get passed from the input.json file, you have be manually hard code it.

b) With mysql:
Refer "cromwell_callCaching.conf" and apart from above mentioned variables in section (a), please update below variables as well:
- hostname : hostname or url of mysql database (eg. localhost)
- database_name : database name (previously created a database eg. cromwell, as if there is no existing database, cromwell will throw error)
- username : mysql username
- password : mysql password

**2. WDL File:**

In this wdl file, we need to add few input variables to pass the wr related parameters and other s3 bucket related path:

In Workflow definition:
```
workflow JointCalling {
  
  ...
  String gatk_jar           # GATK Path
  String java_oracle        # Oracle Java
  String genomicsdb_path    # S3 mount path where genomicsdb.tar will be copied

  # WR related inputs
  String wr_cwd             # WR Working directory
  String wr_cloud_script    # WR Cloud Script to run beforehand eg. to set up mount
  String wr_cloud_os        # WR Cloud OS name
  String wr_cloud_flavor    # WR Cloud Flavor
  ...
} 
```

In each task definition configure runtime attributes:
```
 ...
 runtime {
    wr_cwd:          "${wr_cwd}"
    wr_cloud_script: "${wr_cloud_script}"
    wr_cloud_os:     "${wr_cloud_os}"
    wr_cloud_flavor: "${wr_cloud_flavor}"
  }
 ...
```

> Please refer joint_caller.wdl to understand why and where these parameters are being used.

**3. Input Json File:**

Update below mentioned parameters in Input Json file which will pass these values to WDL and cromwell configuration file:
```
 "JointCalling.gatk_jar":
    "<s3_mount_path>/gatk-4.1.1.0/gatk-package-4.1.1.0-local.jar",
  
  "JointCalling.java_oracle":
    "<s3_mount_path>/jre1.8.0_221/bin/java",

  "JointCalling.genomicsdb_path":
    "<s3_mount_path>/genomicsdb",
  
  "JointCalling.wr_cwd":
    "/home/ubuntu",

  "JointCalling.wr_cloud_script":
    "<local_path_for_cloud_script>/cloud.script",

  "JointCalling.wr_cloud_os":
    "<cloud_os_name>",

  "JointCalling.wr_cloud_flavor":
    "<flavor_name>"
```

> Please refer joint_caller_inputs.json.EXAMPLE in the repo.

 
**4. Sample Name Map File:**

Sample name file formate will be in (tab \t separated) :

```
<sample_id> <sample_s3_mounted_path>
```

Eg.
```
EGAN00001214851 /home/ubuntu/mnt/20000_samples/14820945.HXV2.paired308.f6466eef39.capmq_filtered_interval_list.interval_list.1_of_200.g.vcf.gz
EGAN00001286350 /home/ubuntu/mnt/20000_samples/14820982.HXV2.paired308.18d32776e3.capmq_filtered_interval_list.interval_list.1_of_200.g.vcf.gz
```

> Please refer sampleNameMap.txt in the repo.


**5. Interval list file :**

```
chr1:1-195878
chr1:195879-391754
chr1:391755-606302
chr1:606303-820848
chr1:820849-910849
...
```

> Please refer interval_list.intervals in the repo.


> Note: Please note that we are using oracle java to run cromwell as openjdk java core dumps quite often. We have pushed java and gatk_jar to our s3 bucket and configure same in the input.json file.


## How To Run

Once we have configured all the files with required details, we need to mount s3 bucket on our master node as well (As mentioned in section 1.a. s3_mount_path as this will be used as shared file location.
We can run same cloud.script on the master node and have /home/ubunut/mnt as s3 mount point.

Once done, its simple. Run the below command:

```
java -Dconfig.file=<cromwell_config_file> -jar <cromwell_jar_file> run <wdl_file> -i <inputs.json_file>
```

Eg.
```
java -Dconfig.file=cromwell.conf -jar cromwell-44.jar run joint_caller.wdl -i joint_caller_inputs.json
```
