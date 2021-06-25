Terraform code for deploying cloud run app + dns + sql + redis to us-east1

To launch the app:

  terraform init
  
  
  terraform plan                   (you may need to activate the apis that will be used- terraform will output links to the gcp api pages) 
  
  
  terraform apply --auto-approve

While the infrastructure is being created- you will need to build the docker image(make sure to edit ormconfig.json with the database specs):



  sudo docker build --tag gcr.io/gcp-lab-cloud-castles-com/graph . && sudo docker push gcr.io/gcp-lab-cloud-castles-com/graph



If deletion of the resources is needed:

terraform destroy



How can we secure the system from intrusion and attack, internal and external?
We can limit internal issues with credential rotation and applying strick access policies for gcloud users.
External attacks are unlikely due to fully internalcommunication between services- only the app itself is viewable to the outside world.


How can we centrally collect all logs from all system components?
We can use the built in cloud logging system or spin up grafana and input datasources using gcloud service accounts.
Grafana is good because it is very lightweight compared to more known logging solutions like ELK and etc


How can we optimize the running costs of the system?
We can use miminal instance sizes for the databases(redis and sql),vpc connectors and cloud run app resource requirements.
From my testing the app can run from anywhere of 500mbs ram to 2gb ram. We can research the cheapest regions and move infrastructure there.
Possibly using contract plans for instances will save on computing costs.
Becoming a google partner also is a way to decrease costs.
