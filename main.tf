provider "google" {
  project     = "gcp-lab-cloud-castles-com"
  region      = "us-east1"
}

resource "random_string" "number" {
  length  = 10
  upper   = false
  lower   = true
  number  = true
  special = false
}

resource "google_compute_network" "vpc" {
  name                    = "vpc-${random_string.number.result}"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
}

###################################################################
/*
Uncomment to solve the 403 error in the browser!!!

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.default.location
  project     = google_cloud_run_service.default.project
  service     = google_cloud_run_service.default.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
*/
##################################################################
/*
Uncomment to add a domain name to the service endpoint!!!
this scenario is if the domain is already verified in GCP
(since the domain is owned already)

resource "google_cloud_run_domain_mapping" "default" {
  location = "us-east1"
  name     = "application.gcp-lab.cloud-castles.com"
  metadata {
    namespace = "gcp-lab-cloud-castles"
  }
  spec {
    route_name = google_cloud_run_service.default.name
  }
}
*/

resource "google_cloud_run_service" "default" {
  name     = "cloudrun-app"
  location = "us-east1"
  project  = "gcp-lab-cloud-castles-com"
  depends_on = [google_sql_database_instance.instance]
  template {
    spec {
      containers {
        image = "gcr.io/gcp-lab-cloud-castles-com/graph"   
        ports {
            container_port = 4000
        }
        env {
          name = "REDIS_URL"
          value = "${google_redis_instance.cache.host}"
        } 

        env {
          name = "port"
          value = 4000
        }
        env {
          name = "NODE_ENV"
          value= "development"
        }
        resources{
          limits ={
            memory=1000
           }
        }     
    }
  }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "terraform"
        "run.googleapis.com/vpc-access-connector" = "${google_vpc_access_connector.connector.name}"
      }
    }
  }
  autogenerate_revision_name = true
}

resource "google_vpc_access_connector" "connector" {
  name          = "vpc-con-${random_string.number.result}"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.name
  region        = "us-east1" 
}

resource "google_sql_database_instance" "instance" {
  name   = "cloudrun-sql-postgres-${random_string.number.result}"
  database_version = "POSTGRES_11"
  region = "us-east1"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/gcp-lab-cloud-castles-com/global/networks/${google_compute_network.vpc.name}"
    }
    location_preference {
      zone = "us-east1-b"
    }
  }
  deletion_protection  = "false"
}

resource "google_sql_database" "database" {
  name     = "graphql-ts-server-boilerplate"
  instance = google_sql_database_instance.instance.name
  depends_on = [google_sql_database_instance.instance]
}

resource "google_sql_user" "users" {
  name     = "postgres1"
  password = "root1"
  type = "BUILT_IN"
  instance = google_sql_database_instance.instance.name
  depends_on = [google_sql_database_instance.instance]
}

resource "google_compute_global_address" "service_range" {
  name          = "address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  depends_on = [
    google_compute_network.vpc,
  ]
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_range.name]
}

resource "google_redis_instance" "cache" {
  name           = "private-cache"
  tier           = "BASIC"
  memory_size_gb = 1
  location_id    = "us-east1-b"
  region         = "us-east1"         
  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version     = "REDIS_4_0"
  display_name      = "Terraform Test Instance"
  depends_on = [google_service_networking_connection.private_service_connection]
}
