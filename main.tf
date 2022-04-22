
# Local Development Environment Clusters
module "cluster-single" {
  source = "./modules/cluster-single"
}

module "cluster-gitops" {
  source = "./modules/cluster-gitops"
}

module "cluster-dev" {
  source = "./modules/cluster-dev"
}

module "cluster-stage" {
  source = "./modules/cluster-stage"
}

module "cluster-prod" {
  source = "./modules/cluster-prod"
}
